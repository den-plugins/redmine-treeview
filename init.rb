require 'redmine'

Redmine::Plugin.register :redmine_treeview do
  name 'Redmine Treeview plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  
  permission :treeview, {:treeview => :index}, :public => true
  menu :project_menu, :treeview, {:controller => 'treeview', :action => 'index'}, :caption => 'Treeview', :param => :project_id
end
