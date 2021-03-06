redmine-export-project-data
===========================

Exports all the data from a Redmine project.

Backed up data
------------------------

This script exports the data from the following tables as SQL INSERT commands:
* projects
* attachments
* issues
* journals
* journal_details
* issue_relations
* watchers
* documents
* enabled_modules
* issue_categories
* members
* queries
* versions
* wikis
* wiki_redirects
* wiki_pages
* wiki_contents

It also copies the attachments inside the `files` directory to a subdirectory inside the specified directory.

Installation
------------

Place the `export_project_data.rake` file inside the `/path/to/redmine/lib/tasks` folder.

Usage
------------

Run the following command from your Redmine root directory:

`rake 'project_data:export[identifier,destdir]'`

"identifier" should be replaced with the unique ID of your project. You can find it out from your project URL. If your project URL is "https://domain/projects/myproject", the identifier would be "myproject".

Likewise, "destdir" should be the destination path for your backups. The destination path should point to an existing directory and end with a trailing slash.

License
----------
The MIT License (MIT)

Copyright (c) 2012-2013 yukkyna, bluezio

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
