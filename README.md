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

