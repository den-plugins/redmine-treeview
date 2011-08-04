require 'redmine'

Redmine::Plugin.register :redmine_treeview do
  name 'Redmine Treeview plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  
  project_module :issue_tracking do
    permission :issue_tracking, {:treeview => :index}
  end
  
  menu :project_menu, :treeview, {:controller => 'treeview', :action => 'index'}, :caption => 'User Stories', :param => :project_id
end
