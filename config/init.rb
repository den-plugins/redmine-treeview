require 'redmine'
require 'remaining_effort_entry'
require 'custom_issue_patch'

init_dir = File.dirname(__FILE__)
require init_dir + '/install_assets'
Dir[init_dir + '/../app/helpers/*.rb'].each {|file| require file }
Dir[init_dir + '/../app/controllers/*.rb'].each {|file| require file }
I18n.load_path += ["#{init_dir}/locales/en.yml", "#{init_dir}/../lang/en.yml"]

ActionController::Base.prepend_view_path init_dir + "/../app/views"
ActionView::Base.send(:include,TreeviewHelper)

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
