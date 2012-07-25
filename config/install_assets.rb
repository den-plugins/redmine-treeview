root     = RAILS_ROOT
curr_dir = File.dirname(__FILE__)

js_dest    = %Q{#{root}/public/javascripts/redmine_treeview}
js_orig    = %Q{#{curr_dir}/../assets/javascripts/}
style_dest = %Q{#{root}/public/stylesheets/redmine_treeview}
style_orig = %Q{#{curr_dir}/../assets/stylesheets/}

#clean all installed assets
FileUtils.rm_r js_dest, :force => true
FileUtils.rm_r style_dest, :force => true

#copy all js assets to <app>/public/javascripts/redmine_treeview
FileUtils.cp_r js_orig, js_dest

#copy all stylesheet assets to <app>/public/stylesheets/redmine_treeview
FileUtils.cp_r style_orig, style_dest
