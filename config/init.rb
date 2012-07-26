require 'redmine'
require 'remaining_effort_entry'
require 'custom_issue_patch'

this_file = File.dirname(__FILE__)
require this_file + '/install_assets'
Dir[this_file + '/../app/helpers/*.rb'].each {|file| require file }
Dir[this_file + '/../app/controllers/*.rb'].each {|file| require file }
I18n.load_path += ["#{this_file}/locales/en.yml", "#{this_file}/../lang/en.yml"]

ActionController::Base.prepend_view_path this_file + "/../app/views"
ActionView::Base.send(:include,TreeviewHelper)

Redmine::Plugin.register :redmine_treeview do
  name 'Redmine Treeview plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '1.0.0'
  
  project_module :issue_tracking do
    permission :issue_tracking, {:treeview => [:index]}, :public => true
    permission :split_issues, {:treeview => [:split]}
    permission :carry_over_issues, {:treeview => [:carry_over]}
    permission :carry_over_operation, {:treeview => [:carry_over_operation]}
    permission :create_new_iteration, {:treeview => [:create_iteration]}
  end
  
  menu :project_menu, :treeview, {:controller => 'treeview', :action => 'index'}, :after => :backlogs, :caption => 'User Stories', :param => :project_id
end
