map.with_options :controller => 'treeview' do |group_routes|
  group_routes.with_options :conditions => {:method => :get} do |group_views|
    group_views.connect 'stories/:project_id', :action => 'index'
    group_views.connect 'treeview/:action', :action => 'context_menu'
  end
  group_routes.with_options :conditions => {:method => :post} do |group_actions|
    group_actions.connect 'stories/:project_id', :action => 'index'
    group_actions.connect 'treeview/:action', :action => 'context_menu'
  end
end
