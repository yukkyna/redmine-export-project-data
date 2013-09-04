redmine-export-project-data
===========================
Redmineの任意のプロジェクトデータをバックアップします。

バックアップされるデータ
------------------------
指定されたプロジェクトのデータを、以下のテーブルを対象にSQLのINSERT文としてファイルに出力します。
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

また、files内にある添付ファイルも指定したディレクトリにコピーします。

インストール
------------
/path/to/redmine/lib/tasks にexport_project_data.rakeを設置します。

使用方法
--------
Redmineのルートディレクトリから以下のコマンドを実行します。

`rake 'project_data:export[identifier,destdir]'`

identifierにはプロジェクト識別子を指定します。

プロジェクトのURLがhttps://domain/projects/myprojectの場合、myprojectがプロジェクト識別子になります。

destdirにはバックアップの出力先ディレクトリを指定します。

ディレクトリは既に存在している必要があります。また、/tmp/export/のように、絶対パスで最後にセパレータを指定する必要があります。

ライセンス
----------
The MIT License (MIT)

Copyright (c) 2012 yukkyna

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
