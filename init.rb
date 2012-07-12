require 'redmine'
require 'remaining_effort_entry'
require 'custom_issue_patch'

Redmine::Plugin.register :redmine_treeview do
  name 'Redmine Treeview plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  
  project_module :issue_tracking do
    permission :issue_tracking, {:treeview => [:index]}, :public => true
    permission :split_issues, {:treeview => [:split]}
    permission :carry_over_issues, {:treeview => [:carry_over]}
    permission :carry_over_operation, {:treeview => [:carry_over_operation]}
    permission :create_new_iteration, {:treeview => [:create_iteration]}
  end
  
  menu :project_menu, :treeview, {:controller => 'treeview', :action => 'index'}, :after => :backlogs, :caption => 'User Stories', :param => :project_id
end
