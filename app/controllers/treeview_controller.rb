class TreeviewController < IssuesController

  skip_filter :authorize, :only => [:edit, :bulk_edit, :move, :destroy]
  before_filter :treeview_authorize, :only => [:edit, :bulk_edit, :move, :destroy]

  def index
    retrieve_query
    sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
    sort_update({'id' => "#{Issue.table_name}.id"}.merge(@query.available_columns.inject({}) {|h, c| h[c.name.to_s] = c.sortable; h}))
    
    if @query.valid?
      limit = per_page_option
      respond_to do |format|
        format.html { }
        format.atom { }
        format.csv  { limit = Setting.issues_export_limit.to_i }
        format.pdf  { limit = Setting.issues_export_limit.to_i }
      end
      
      parents_only = " AND NOT EXISTS (SELECT issue_to_id FROM issue_relations where issue_relations.issue_to_id = issues.id AND issue_relations.relation_type='subtasks')"
      children_only = " AND EXISTS (SELECT issue_to_id FROM issue_relations where issue_relations.issue_to_id = issues.id AND issue_relations.relation_type='subtasks')"
      
      @issue_count = Issue.count(:include => [:status, :project, :tracker], :conditions => @query.statement + parents_only)
      @issue_pages = Paginator.new self, @issue_count, limit, params['page']
      @issues = Issue.find :all, :order => sort_clause,
                           :include => [ :assigned_to, :status, :tracker, :project, :priority, :category, :fixed_version ],
                           :conditions => @query.statement + parents_only,
                           :limit  =>  limit,
                           :offset =>  @issue_pages.current.offset

      @issues_with_parents = Issue.find(:all, :include => [:status, :project, :tracker], :conditions => @query.statement + children_only).collect {|s| s.id }
      
      respond_to do |format|
        format.html { render :template => 'treeview/index.rhtml', :layout => !request.xhr? }
        format.atom { render_feed(@issues, :title => "#{@project || Setting.app_title}: #{l(:label_issue_plural)}") }
        format.csv  { send_data(issues_to_csv(@issues, @project).read, :type => 'text/csv; header=present', :filename => 'export.csv') }
        format.pdf  { send_data(issues_to_pdf(@issues, @project), :type => 'application/pdf', :filename => 'export.pdf') }
      end
    else
      # Send html if the query is not valid
      render(:template => 'treeview/index.rhtml', :layout => !request.xhr?)
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def add_defaults(args)
    @query.add_filter 'tracker_id', '=', Tracker.find(:all, :select => :id, :conditions => "name = 'Feature' or name = 'Task'").collect {|c| c.id.to_s}
    if session[:query][:column_names]
      @query.column_names = session[:query][:column_names]
    else
      @query.column_names = [:tracker, :subject, :assigned_to, :status, :fixed_version]
      story_points = CustomField.find(:first, :select => 'id', :conditions => "name = 'Story Points'")
      @query.column_names += ["cf_#{story_points.id}".to_sym] unless story_points.nil?
    end
  end
  
  def retrieve_query
    if !params[:query_id].blank?
      cond = "project_id IS NULL"
      cond << " OR project_id = #{@project.id}" if @project
      @query = Query.find(params[:query_id], :conditions => cond)
      @query.project = @project
      session[:query] = {:id => @query.id, :project_id => @query.project_id}
      sort_clear
    else
      if params[:set_filter] || session[:query].nil? || session[:query][:project_id] != (@project ? @project.id : nil)
        # Give it a name, required to be valid
        @query = Query.new(:name => "_")
        @query.project = @project
        if params[:fields] and params[:fields].is_a? Array
          params[:fields].each do |field|
          @query.add_filter(field, params[:operators][field], params[:values][field])
          end
        else
          @query.available_filters.keys.each do |field|
            @query.add_short_filter(field, params[field]) if params[field]
          end
        end
        session[:query] = {:project_id => @query.project_id, :filters => @query.filters}
      else
        @query = Query.find_by_id(session[:query][:id]) if session[:query][:id]
        @query ||= Query.new(:name => "_", :project => @project, :filters => session[:query][:filters])
        @query.project = @project
      end
    end
    add_defaults(params)
    @query.column_names = params[:column_names] if params[:column_names]
    session[:query][:column_names] = @query.column_names
  end
  
  def bulk_edit
    if request.post?
      status = params[:status_id].blank? ? nil : IssueStatus.find_by_id(params[:status_id])
      priority = params[:priority_id].blank? ? nil : Enumeration.find_by_id(params[:priority_id])
      acctg = params[:acctg_type].blank? ? nil : Enumeration.find_by_id(params[:acctg_type])
      assigned_to = (params[:assigned_to_id].blank? || params[:assigned_to_id] == 'none') ? nil : User.find_by_id(params[:assigned_to_id])
      category = (params[:category_id].blank? || params[:category_id] == 'none') ? nil : @project.issue_categories.find_by_id(params[:category_id])
      fixed_version = (params[:fixed_version_id].blank? || params[:fixed_version_id] == 'none') ? nil : @project.versions.find_by_id(params[:fixed_version_id])
      custom_field_values = params[:custom_field_values] ? params[:custom_field_values].reject {|k,v| v.blank?} : nil
      
      unsaved_issue_ids = []
      @issues.each do |issue|
        journal = issue.init_journal(User.current, params[:notes])
        issue.priority = priority if priority
        issue.accounting = acctg if acctg
        issue.assigned_to = assigned_to if assigned_to || params[:assigned_to_id] == 'none'
        issue.category = category if category || params[:category_id] == 'none'
        issue.fixed_version = fixed_version if fixed_version || params[:fixed_version_id] == 'none'
        issue.start_date = params[:start_date] unless params[:start_date].blank?
        issue.due_date = params[:due_date] unless params[:due_date].blank?
        issue.done_ratio = params[:done_ratio] unless params[:done_ratio].blank?
        issue.custom_field_values = custom_field_values if custom_field_values && !custom_field_values.empty?
        call_hook(:controller_issues_bulk_edit_before_save, { :params => params, :issue => issue })
        # Don't save any change to the issue if the user is not authorized to apply the requested status
        unless (status.nil? || (issue.status.new_status_allowed_to?(status, current_role, issue.tracker) && issue.status = status)) && issue.save
          # Keep unsaved issue ids to display them in flash error
          unsaved_issue_ids << issue.id
        end
      end
      if unsaved_issue_ids.empty?
        flash[:notice] = l(:notice_successful_update) unless @issues.empty?
      else
        flash[:error] = l(:notice_failed_to_save_issues, :count => unsaved_issue_ids.size,
                                                         :total => @issues.size,
                                                         :ids => '#' + unsaved_issue_ids.join(', #'))
      end
      redirect_to(params[:back_to] || {:controller => 'treeview', :action => 'index', :project_id => @project})
      return
    end
    # Find potential statuses the user could be allowed to switch issues to
    @available_statuses = Workflow.find(:all, :include => :new_status,
                                              :conditions => {:role_id => current_role.id}).collect(&:new_status).compact.uniq.sort
    @custom_fields = @project.issue_custom_fields.select {|f| f.field_format == 'list'}
  end

  def move
    @allowed_projects = []
    # find projects to which the user is allowed to move the issue
    if User.current.admin?
      # admin is allowed to move issues to any active (visible) project
      @allowed_projects = Project.find(:all, :conditions => Project.visible_by(User.current))
    else
      User.current.memberships.each {|m| @allowed_projects << m.project if m.role.allowed_to?(:move_issues)}
    end
    @target_project = @allowed_projects.detect {|p| p.id.to_s == params[:new_project_id]} if params[:new_project_id]
    @target_project ||= @project
    @trackers = @target_project.trackers
    if request.post?
      new_tracker = params[:new_tracker_id].blank? ? nil : @target_project.trackers.find_by_id(params[:new_tracker_id])
      unsaved_issue_ids = []
      @issues.each do |issue|
        issue.init_journal(User.current)
        unsaved_issue_ids << issue.id unless issue.move_to(@target_project, new_tracker, params[:copy_options])
      end
      if unsaved_issue_ids.empty?
        flash[:notice] = l(:notice_successful_update) unless @issues.empty?
      else
        flash[:error] = l(:notice_failed_to_save_issues, :count => unsaved_issue_ids.size,
                                                         :total => @issues.size,
                                                         :ids => '#' + unsaved_issue_ids.join(', #'))
      end
      redirect_to(params[:back_to] || { :controller => 'treeview', :action => 'index', :project_id => @project})
      return
    end
    render :layout => false if request.xhr?
  end
    
  private
  def treeview_authorize(action = params[:action])
    allowed = User.current.allowed_to?({:controller => 'issues', :action => action}, @project)
    allowed ? true : deny_access
  end
end
