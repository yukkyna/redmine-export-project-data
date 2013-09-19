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
  task :export, [:id, :dir] => :environment do |task, args|

    p 'export project data'

    if !args[:id]
      p 'error id '
      exit 1
    end
    ident = args[:id]

    if !args[:dir]
      p 'error dir '
      exit 1
    end
    dir = args[:dir]
    file = File.open(File.join(dir, ident + '.sql'), "w")
    attDir = File.join(dir, 'files')
    Dir::mkdir(attDir)

    # export project
    project = Project.find(:first, :conditions => ["identifier = ?", ident])
    if project == nil then
      p 'Could not find project ' + ident
      exit 1
    end
    export(file, project)

    # export project attachments
    Attachment.where(:container_id => project.id, :container_type => 'Project').find_each do |o|
      export(file, o)
    end

    # export issues
    Issue.where(:project_id => project.id).find_each do |issue|
      export(file, issue)

      # export issue journals
      Journal.where(:journalized_type => 'Issue', :journalized_id => issue.id).find_each do |j|
        export(file, j)
        # export issue journal details
        JournalDetail.where(:journal_id => j.id).find_each do |d|
          export(file, d)
        end
      end

      # export issue attachments
      Attachment.where(:container_id => issue.id, :container_type => 'Issue').find_each do |o|
        export(file, o)

        export_file(o, attDir)
      end

      # export issue relations
      IssueRelation.where(:issue_from_id => issue.id).find_each do |o|
        export(file, o)
      end

      # export issue watchers
      Watcher.where(:watchable_id => issue.id, :watchable_type => 'Issue').find_each do |o|
        export(file, o)
      end
    end

    # export documents
    Document.where(:project_id => project.id).find_each do |document|
      export(file, document)

      # export document attachments
      Attachment.where(:container_id => document.id, :container_type => 'Document').find_each do |o|
        export(file, o)

        export_file(o, attDir)
      end
    end

    # export enabled_modules
    EnabledModule.where(:project_id => project.id).find_each do |o|
      export(file, o)
    end

    # export issue_categories
    IssueCategory.where(:project_id => project.id).find_each do |o|
      export(file, o)
    end

    # export members
    Member.where(:project_id => project.id).find_each do |o|
      export(file, o)
    end

    # export project_trackers
    Member.where(:project_id => project.id).find_each do |o|
      export(file, o)
    end

    # export queries
    Query.where(:project_id => project.id).find_each do |o|
      export(file, o)
    end

    # export versions
    Version.where(:project_id => project.id).find_each do |version|
      export(file, version)

      # export version attachments
      Attachment.where(:container_id => version.id, :container_type => 'Version').find_each do |o|
        export(file, o)

        export_file(o, attDir)
      end
    end

    # export wikis
    Wiki.where(:project_id => project.id).find_each do |wiki|
      export(file, wiki)

      # export wiki redirects
      WikiRedirect.where(:wiki_id => wiki.id).find_each do |r|
        export(file, r)
      end

      # export wiki pages
      WikiPage.where(:wiki_id => wiki.id).find_each do |page|
        export(file, page)

        # export wiki page contents
        WikiContent.where(:page_id => page.id).find_each do |content|
          export(file, content)
        end

        # export wiki page attachments
        Attachment.where(:container_id => page.id, :container_type => 'WikiPage').find_each do |o|
          export(file, o)
          
          export_file(o, attDir)
        end

        # export wiki page watchers
        Watcher.where(:watchable_id => page.id, :watchable_type => 'WikiPage').find_each do |o|
          export(file, o)
        end
      end
    end

    file.close

    p 'finish'
  end

  def export(file, data)
    c = data.class
    file.print("INSERT INTO " + c.table_name + "(" + c.column_names.join(',') + ") VALUES(")

    c.column_names.each_with_index {|key, i|
      file.print(c.connection.quote(data.attributes[key]))
      if i != c.columns.size - 1
        file.print(',')
      end
    }
    file.puts(');')
  end


  def export_file(attach, attDir)
    src = attach.diskfile
    if attach.attribute_present?('disk_directory')
      FileUtils.mkdir_p(File.join(attDir, attach.disk_directory))
      dest = File.join(attDir, attach.disk_directory, attach.disk_filename)
    else
      dest = File.join(attDir, attach.disk_filename)
    end
    FileUtils.copy(src, dest) if File.exists?(src)
  end

end
