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

		def export(model)
			values = []
			model.class.column_names.each {|column_name| values << model.class.connection.quote(model.attributes[column_name])}
			@file.puts 'INSERT INTO %s (%s) VALUES (%s);' % [model.class.table_name, model.class.column_names.join(', '), values.join(', ')]
		end

		def export_habtm(first_object, second_object)
			habtm_table = '%s_%s' % [
				first_object.class.name.downcase.pluralize,
				second_object.class.name.downcase.pluralize,
			]
			first_id  = '%s_id' % [first_object.class.name.downcase]
			second_id = '%s_id' % [second_object.class.name.downcase]
			@file.puts 'INSERT INTO %s (%s, %s) VALUES (%d, %d);' % [habtm_table, first_id, second_id, first_object.id, second_object.id]
		end		
		
		def export_attachments(container)
			Attachment.where(:container_id => container.id, :container_type => container.class.name).find_each do |attachment|
				export attachment
				src = Attachment.storage_path + File::SEPARATOR + attachment.disk_filename
				dest = @att_dir + attachment.disk_filename
				FileUtils.copy(src, dest) if File.exists?(src)
			end
		end

		def export_journal_details(journal)
			JournalDetail.where(:journal_id => journal.id).find_each do |journal_detail|
				export(journal_detail)
			end
		end

		def export_journals(journalized)
			Journal.where(:journalized_id => journalized.id, :journalized_type => journalized.class.name).find_each do |journal|
				export journal
				export journal_details journal
			end
		end
		
		def export_project
			@project = Project.find :first, :conditions => ["identifier = ?", @ident]
			abort 'Could not find project %s!' % [@ident] if @project.nil?
			export @project
			export_attachments @project
		end

		def export_watchers(watchable)
			Watcher.where(:watchable_id => watchable.id, :watchable_type => watchable.class.name).find_each do |watcher|
				export watcher
			end
		end

		def export_issue_relations(issue)
			IssueRelation.where(:issue_from_id => issue.id).find_each do |issue_reration|
				export issue_reration
			end
		end
		
		def export_issues
			Issue.where(:project_id => @project.id).find_each do |issue|
				export issue
				export_journals issue
				export_attachments issue
				export_issue_relations issue
				export_watchers issue
			end
		end

		def export_documents
			Document.where(:project_id => @project.id).find_each do |document|
				export document
				export_attachments document
			end
		end

		def export_enabled_modules
			EnabledModule.where(:project_id => @project.id).find_each do |enabled_module|
				export enabled_module
			end
		end

		def export_issue_categories
			IssueCategory.where(:project_id => @project.id).find_each do |issue_category|
				export issue_category
			end
		end

		def export_users(member)
			User.where(:id => member.user_id).find_each do |user|
				export user
			end
		end

		def export_members
			Member.where(:project_id => @project.id).find_each do |member|
				export member
				export_users member
			end
		end

		def export_project_trackers
			@project.trackers do |tracker|
				export tracker
				export_habtm @project, tracker
			end
		end

		def export_queries
			Query.where(:project_id => @project.id).find_each do |query|
				export query
			end
		end

		def export_versions
			Version.where(:project_id => @project.id).find_each do |version|
				export version
				export_attachments version
			end
		end

		def export_wiki_redirects(wiki)
			WikiRedirect.where(:wiki_id => wiki.id).find_each do |wiki_redirect|
				export wiki_redirect
			end
		end
		
		def export_wiki_contents
			WikiContent.where(:page_id => wiki_page.id).find_each do |wiki_content|
				export wiki_content
			end
		end

		def export_wiki_pages
			WikiPage.where(:wiki_id => wiki.id).find_each do |wiki_page|
				export wiki_page
				export_wiki_contents wiki_page
				export_attachments wiki_page
				export_watchers
			end
		end

		def export_wikis
			Wiki.where(:project_id => @project.id).find_each do |wiki|
				export wiki
				export_wiki_redirects wiki
				export_wiki_pages wiki
			end
		end

		def main
			export_project
			export_issues
			export_documents
			export_enabled_modules
			export_issue_categories
			export_members
			export_project_trackers
			export_queries
			export_versions
			export_wikis
		end

	end

	task :export, [:id, :dir] => :environment do |task, args|
		project_data = ProjectData.new args
		project_data.main
	end

end

