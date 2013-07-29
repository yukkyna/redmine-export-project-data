# The MIT License (MIT)
#
# Copyright (c) 2012 yukkyna
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

desc 'Export project data.'

namespace :project_data do

	class OpenIdAuthenticationAssociation < ActiveRecord::Base; end

	class OpenIdAuthenticationNonce       < ActiveRecord::Base; end

	class SchemaMigration                 < ActiveRecord::Base
		self.primary_key = :version
	end

	class CustomFieldsProject             < ActiveRecord::Base
		self.primary_key = :custom_field_id
	end

	class GroupsUser                      < ActiveRecord::Base
		self.primary_key = :group_id
	end

	class ProjectsTracker                 < ActiveRecord::Base
		self.primary_key = :project_id
	end

	class CustomFieldsTracker             < ActiveRecord::Base
		self.primary_key = :custom_field_id
	end

	class ChangesetParent                 < ActiveRecord::Base
		self.primary_key = :changeset_id
	end

	class ChangesetsIssue                 < ActiveRecord::Base
		self.primary_key = :changeset_id
	end

	class WikiContentVersion              < ActiveRecord::Base; end

	class ProjectData
		
		attr_accessor :ident, :dir, :file, :att_dir, :project

		def ProjectData.callback(file)
			proc {
				file.close if file && !file.closed?
				p 'finish'
			}
		end
		
		def initialize(args)
			abort 'Identifier is required.' unless args[:id]
			abort 'Destdir is required.' unless args[:dir]
			p 'export project data'
			@ident = args[:id]
			@dir = args[:dir]
			@file = File.open(@dir + @ident + '.sql', "w")
			@att_dir = @dir + 'files' + File::SEPARATOR
			Dir::mkdir @att_dir
			ObjectSpace.define_finalizer(self, ProjectData.callback(@file))
		end

		def export_row(model)
			values = []
			model.class.column_names.each {|column_name| values << model.class.connection.quote(model.attributes[column_name])}
			@file.puts 'INSERT IGNORE INTO `%s` (`%s`) VALUES (%s);' % [
				model.class.table_name.force_encoding('UTF-8'), 
				model.class.column_names.join('`, `').force_encoding('UTF-8'), 
				values.join(', ').force_encoding('UTF-8'),
			]
		end

		def export_rows(model_class, condition={})
			model_class.where(condition).find_each do |model|
				export_row model
				yield model
			end
		end

		def export_polymorphics(polymorphic, model_class, prefix, suffix=:type)
			condition = {
				('%s_id' % [prefix]).to_sym         => polymorphic.id, 
				('%s_%s' % [prefix, suffix]).to_sym => polymorphic.class.name,
			}
			export_rows model_class, condition do |polymorphic_relation|
				yield polymorphic_relation
			end
		end

		def export_attachments(polymorphic)
			export_polymorphics polymorphic, Attachment, :container do |attachment|
				src = Attachment.storage_path + File::SEPARATOR + attachment.disk_filename
				dest = @att_dir + attachment.disk_filename
				FileUtils.copy(src, dest) if File.exists?(src)
			end
		end

		def export_comments(polymorphic)
			export_polymorphics(polymorphic, Comment, :commented){|comment|}
		end
		
		def export_custom_values(polymorphic)
			export_polymorphics(polymorphic, CustomValue, :customized){|custom_value|}
		end

		def export_journal_details(journal)
			export_rows(JournalDetail, {:journal_id => journal.id}){|journal_detail|}
		end

		def export_journals(polymorphic)
			export_polymorphics polymorphic, Journal, :journalized do |journal|
				export_journal_details journal
			end
		end
		
		def export_watchers(polymorphic)
			export_polymorphics(polymorphic, Watcher, :watchable){|watcher|}
		end

		def export_wiki_extensions_votes(polymorphic)
			export_polymorphics(polymorphic, WikiExtensionsVote, :target, :class_name){|wiki_extensions_votes|}
		end

		def export_polymorphic_rerations(model)
			export_attachments           model
			export_comments              model
			export_custom_values         model
			export_journals              model
			export_watchers              model
			export_wiki_extensions_votes model
		end

		def export_default_tables
			default_tables = [
				AuthSource,
				IssueStatus,
				OpenIdAuthenticationAssociation,
				OpenIdAuthenticationNonce,
				Role,
				SchemaMigration,
				Setting,
			]
			default_tables.each do |model_class|
				export_rows(model_class){|model|}
			end
		end

		def export_project
			@project = Project.find :first, :conditions => ["identifier = ?", @ident]
			abort 'Could not find project %s!' % [@ident] if @project.nil?
			export_row @project
			export_polymorphic_rerations @project
		end

		def export(model_class, condition={})
			export_rows model_class, condition do |model|
				export_polymorphic_rerations model
				yield model
			end
		end

		def export_by_project_id(model_class)
			export model_class, ["project_id = ? OR project_id IS NULL", @project.id] do |model|
				yield model
			end
		end

		def export_messages(board)
			export(Message, {:board_id => board.id}){|message|}
		end
		
		def export_boards
			export_by_project_id Board do |board|
				export_messages board
			end
		end

		def export_code_review_project_settings
			export_by_project_id(CodeReviewProjectSetting){|code_review_project_setting|}
		end

		def export_code_reviews
			export_by_project_id(CodeReview){|code_review|}
			export_code_review_project_settings
		end

		def export_custom_fields_projects
			export_by_project_id CustomFieldsProject do |custom_fields_project|
				yield custom_fields_project
			end
		end

		def export_custom_fields
			export_custom_fields_projects do |custom_fields_project|
				export(CustomField, {:id => custom_fields_project.custom_field_id}){|custom_field|}
			end
		end

		def export_documents
			export_by_project_id(Document){|document|}
		end

		def export_enabled_modules
			export_by_project_id(EnabledModule){|enabled_module|}
		end

		def export_enumerations
			export_by_project_id(Enumeration){|enumeration|}
		end

		def export_issue_categories
			export_by_project_id(IssueCategory){|issue_category|}
		end

		def export_issue_relations(issue)
			export(IssueRelation, {:issue_from_id => issue.id}){|issue_relation|}
		end

		def export_code_review_assignments(issue)
			export(CodeReviewAssignment, ["issue_id = ? OR issue_id IS NULL", issue.id]){|code_review_assignment|}
		end

		def export_issues
			export_issue_categories
			export_by_project_id Issue do |issue|
				export_issue_relations         issue
				export_code_review_assignments issue
			end
		end

		def export_member_roles(member)
			export(MemberRole, {:member_id => member.id}){|member_role|}
		end

		def export_code_review_user_settings(user)
			export(CodeReviewUserSetting, {:user_id => user.id}){|code_review_user_setting|}
		end

		def export_groups_users(user)
			export(GroupsUser, {:user_id => user.id}){|groups_user|}
		end

		def export_tokens(user)
			export(Token, {:user_id => user.id}){|token|}
		end

		def export_user_preferences(user)
			export(UserPreference, {:user_id => user.id}){|user_preference|}
		end

		def export_users(member)
			export User, {:id => member.user_id} do |user|
				export_code_review_user_settings user
				export_groups_users              user
				export_tokens                    user
				export_user_preferences          user
			end
		end

		def export_members
			export_by_project_id Member do |member|
				export_member_roles member
				export_users member
			end
		end

		def export_news
			export_by_project_id(News){|news|}
		end

		def export_projects_trackers
			export_by_project_id ProjectsTracker do |projects_tracker|
				yield projects_tracker
			end
		end

		def export_custom_fields_trackers(tracker)
			export(CustomFieldsTracker, {:tracker_id => tracker.id}){|custom_fields_tracker|}
		end

		def export_workflows(tracker)
			export(Workflow, {:tracker_id => tracker.id}){|workflow|}
		end

		def export_trackers
			export_projects_trackers do |projects_tracker|
				export Tracker, {:id => projects_tracker.tracker_id} do |tracker|
					export_custom_fields_trackers tracker
					export_workflows              tracker
				end
			end
		end

		def export_queries
			export_by_project_id(Query){|query|}
		end

		def export_changes(changeset)
			export(Change, {:changeset_id => changeset.id}){|change|}
		end

		def export_changeset_parents(changeset)
			export(ChangesetParent, {:changeset_id => changeset.id}){|changeset_parent|}
		end

		def export_changesets_issues(changeset)
			export(ChangesetsIssue, {:changeset_id => changeset.id}){|changesets_issue|}
		end

		def export_changesets(repository)
			export Changeset, {:repository_id => repository.id} do |changeset|
				export_changes           changeset
				export_changeset_parents changeset
				export_changesets_issues changeset
			end
		end

		def export_repositories
			export_by_project_id Repository do |repository|
				export_changesets repository
			end
		end

		def export_time_entries
			export_by_project_id(TimeEntry){|time_entry|}
		end

		def export_versions
			export_by_project_id(Version){|version|}
		end

		def export_wiki_content_versions(wiki_content)
			export(WikiContentVersion, {:wiki_content_id => wiki_content.id}){|wiki_content_version|}
		end

		def export_wiki_contents(wiki_page)
			export WikiContent, {:page_id => wiki_page.id} do |wiki_content|
				export_wiki_content_versions wiki_content
			end
		end

		def export_wiki_extensions_comments(wiki_page)
			export(WikiExtensionsComment, {:wiki_page_id => wiki_page.id}){|wiki_extensions_comment|}
		end

		def export_wiki_pages(wiki)
			export WikiPage, {:wiki_id => wiki.id} do |wiki_page|
				export_wiki_contents            wiki_page
				export_wiki_extensions_comments wiki_page
			end
		end

		def export_wiki_redirects(wiki)
			export(WikiRedirect, {:wiki_id => wiki.id}){|wiki_redirect|}
		end

		def export_wiki_extensions_counts
			export_by_project_id(WikiExtensionsCount){|wiki_extensions_count|}
		end

		def export_wiki_extensions_menus
			export_by_project_id(WikiExtensionsMenu){|wiki_extensions_menu|}
		end

		def export_wiki_extensions_settings
			export_by_project_id(WikiExtensionsSetting){|wiki_extensions_setting|}
		end

		def export_wiki_extensions_tag_relations(wiki_extensions_tag)
			export(WikiExtensionsTagRelation, {:tag_id => wiki_extensions_tag.id}){|wiki_extensions_tag_relation|}
		end

		def export_wiki_extensions_tags
			export_by_project_id WikiExtensionsTag do |wiki_extensions_tag|
				export_wiki_extensions_tag_relations wiki_extensions_tag
			end
		end

		def export_wiki_extensions
			export_wiki_extensions_counts
			export_wiki_extensions_menus
			export_wiki_extensions_settings
			export_wiki_extensions_tags
		end

		def export_wikis
			export_by_project_id Wiki do |wiki|
				export_wiki_pages     wiki
				export_wiki_redirects wiki
			end
			export_wiki_extensions
		end

		def export_related_tables
			export_boards
			export_code_reviews
			export_custom_fields
			export_documents
			export_enabled_modules
			export_enumerations
			export_issues
			export_members
			export_news
			export_trackers
			export_queries
			export_repositories
			export_time_entries
			export_versions
			export_wikis
		end

		def main
			export_default_tables
			export_project
			export_related_tables
		end

	end

	task :export, [:id, :dir] => :environment do |task, args|
		project_data = ProjectData.new args
		project_data.main
	end

end
