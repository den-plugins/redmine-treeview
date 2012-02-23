class TreeviewController < IssuesController
  include FaceboxRender
  
  before_filter :find_issue, :only => [:show, :edit, :reply, :split]
  before_filter :find_issues, :only => [:show, :bulk_edit, :move, :destroy]
  before_filter :find_project, :only => [:new, :update_form, :preview]
  skip_filter :authorize, :only => [:show, :edit, :bulk_edit, :move, :destroy, :new]
  before_filter :treeview_authorize, :only => [:show, :edit, :bulk_edit, :move, :destroy, :new]
  before_filter :authorize, :except => [:index, :changes, :gantt, :calendar, :preview, :update_form, :context_menu, :new_remote, :edit_remote, :update_status_remote,
                                        :rollback_credit]

  def index
    retrieve_query
    sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
    sort_update({'id' => "#{Issue.table_name}.id"}.merge(@query.available_columns.inject({}) {|h, c| h[c.name.to_s] = c.sortable; h}))
    @back = url_for(:controller => 'treeview', :action => 'index')
    
    if @query.valid?
      limit = per_page_option
      respond_to do |format|
        format.html { }
        format.atom { }
        format.csv  { limit = Setting.issues_export_limit.to_i }
        format.pdf  { limit = Setting.issues_export_limit.to_i }
      end
      
      @tmp_issues = Issue.find :all, :order => sort_clause,
                                     :include => [:assigned_to, :status, :tracker, :project, :priority, :category, :fixed_version],
                                     :conditions => @query.statement
      
      @issues, @child_issues = [], []
      @filtered_issues = @tmp_issues.reject do |issue|
        @child_issues << issue if issue.has_parent?
        issue if (issue.has_parent? and @tmp_issues.include?(issue.parent_issue))
      end
      @child_issues.delete_if {|c| @filtered_issues.include? c}
      @child_issues_clone = @child_issues
      
      @issue_count = @filtered_issues.count
      @issue_pages = Paginator.new self, @issue_count, limit, params['page']
      offset = @issue_pages.current.offset
      (offset ... (offset + limit)).each do |i|
       break if @filtered_issues[i].nil?
	   	if params[:set_filter] || session[:not_first_load]
      	 	@issues << @filtered_issues[i]
			session[:not_first_load] = "yes"
		end
      end

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
  
  def show
    @journals = @issue.journals.find(:all, :include => [:user, :details], :order => "#{Journal.table_name}.created_on ASC")
    @journals.each_with_index {|j,i| j.indice = i+1}
    @journals.reverse! if User.current.wants_comments_in_reverse_order?
    @changesets = @issue.changesets
    @changesets.reverse! if User.current.wants_comments_in_reverse_order?
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    @edit_allowed = User.current.allowed_to?(:edit_issues, @project)
    @logtime_allowed = TimeEntry.logtime_allowed?(User.current, @project)
    @priorities = Enumeration.priorities
    @accounting = Enumeration.accounting_types
    @default = @issue.accounting.id
    @time_entry = TimeEntry.new
    @update_options = {'Internal (DEN only)' => 1, 'Include Mystic' => 2}
    @treeview_index = "#{root_url}stories/#{@project.identifier}"

		# for feature #8364
		issues = @project.issues.collect {|pi| pi.id}.sort
		index = issues.index(@issue.id)
		if !index.nil?
			prv_issue = (index-1 >= 0) ? issues[index-1] : 0
			nxt_issue = (index+1 < issues.size) ? issues[index+1] : 0
		end
		#
    respond_to do |format|
      format.html { render :template => 'treeview/show.rhtml', :locals => {:prv => prv_issue, :nxt => nxt_issue} } # for feature #8364 - added locals
      format.atom { render :action => 'changes', :layout => false, :content_type => 'application/atom+xml' }
      format.pdf  { send_data(issue_to_pdf(@issue), :type => 'application/pdf', :filename => "#{@project.identifier}-#{@issue.id}.pdf") }
    end
  end
  
  def new
    @issue = Issue.new
    @issue.copy_from(params[:copy_from]) if params[:copy_from]
    @issue.project = @project
    @mode = 'main'
    # Tracker must be set before custom field values
    @issue.tracker ||= @project.trackers.find((params[:issue] && params[:issue][:tracker_id]) || params[:tracker_id] || :first)
    if @issue.tracker.nil?
      render_error 'No tracker is associated to this project. Please check the Project settings.'
      return
    end
    if params[:issue].is_a?(Hash)
      @issue.attributes = params[:issue]
      @issue.watcher_user_ids = params[:issue]['watcher_user_ids'] if User.current.allowed_to?(:add_issue_watchers, @project)
    end
    @issue.author = User.current
    
    default_status = IssueStatus.default
    unless default_status
      render_error 'No default issue status is defined. Please check your configuration (Go to "Administration -> Issue statuses").'
      return
    end
    @issue.status = default_status
    @allowed_statuses = ([default_status] + default_status.find_new_statuses_allowed_to(User.current.role_for_project(@project), @issue.tracker)).uniq
    
    if params[:issue_from_id]
      @mode = "subtask"
      @relation = IssueRelation.new()
      @relation.issue_from = Issue.find(params[:issue_from_id])
      @relation.relation_type = params[:relation_type]
    end

    if request.get? || request.xhr?
      @issue.start_date ||= Date.today
    else
      requested_status = IssueStatus.find_by_id(params[:issue][:status_id])
      # Check that the user is allowed to apply the requested status
      @issue.status = (@allowed_statuses.include? requested_status) ? requested_status : default_status

      if @issue.save
        if params[:relation]
          @relation = IssueRelation.new(params[:relation])
          if !params[:relation][:issue_from_id].blank?
            @relation.issue_from = Issue.find(params[:relation][:issue_from_id])
            @relation.issue_to = @issue
          else
            if !params[:relation][:issue_to_id].blank?
              @relation.issue_to = Issue.find(params[:relation][:issue_to_id])
              @relation.issue_from = @issue
            end
          end
          @relation.save
        end
        attach_files(@issue, params[:attachments])
        flash[:notice] = l(:notice_successful_create)
        call_hook(:controller_issues_new_after_save, { :params => params, :issue => @issue})
        redirect_to(params[:continue] ? { :controller => 'treeview', :action => 'new', :tracker_id => @issue.tracker, :project_id => @project.id } :
                                        { :controller => 'treeview', :action => 'show', :id => @issue, :project_id => @project.id })
        return
      end
    end
    @priorities = Enumeration.priorities
    @accounting = Enumeration.accounting_types
    @default = !@project.accounting.nil? ? @project.accounting.id : Enumeration.accounting_types.default.id if Enumeration.accounting_types
    render :layout => !request.xhr?
  end
  
  def context_menu
    @issues = Issue.find_all_by_id(params[:ids], :include => :project)
    if (@issues.size == 1)
      @issue = @issues.first
      @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
      @assignables = @issue.assignable_users
      @assignables << @issue.assigned_to if @issue.assigned_to && !@assignables.include?(@issue.assigned_to)
    end
    projects = @issues.collect(&:project).compact.uniq
    @project = projects.first if projects.size == 1

    @can = {:edit => (@project && User.current.allowed_to?(:edit_issues, @project)),
            :log_time => (@project && User.current.allowed_to?(:log_time, @project)),
            :update => (@issue && (User.current.allowed_to?(:edit_issues, @project) || (User.current.allowed_to?(:change_status, @project) && !@allowed_statuses.empty?))),
            :move => (@project && User.current.allowed_to?(:move_issues, @project)),
            :copy => (@issue && @project.trackers.include?(@issue.tracker) && User.current.allowed_to?(:add_issues, @project)),
            :delete => (@project && User.current.allowed_to?(:delete_issues, @project)),
            :split => (@project && User.current.allowed_to?(:split_issues, @project))
            }

     if @project
      @assignables = @project.assignable_users
      @assignables << @issue.assigned_to if @issue && @issue.assigned_to && !@assignables.include?(@issue.assigned_to)
    end
    
    @priorities = Enumeration.priorities.reverse
    @acctg_types = Enumeration.accounting_types.reverse
    @statuses = IssueStatus.find(:all, :order => 'position')
    @back = request.env['HTTP_REFERER']
    @sorting_options = {'Priority'=> {:sort_key => 'enumerations.position'},
                        'Category'=> {:sort_key => 'issues.category_id'},
                        'Due Date'=> {:sort_key => 'issues.due_date'},
                        'Date Created'=> {:sort_key => 'issues.created_on'}}

    render :layout => false
  end
  
  def edit
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    @priorities = Enumeration.priorities
    @accounting = Enumeration.accounting_types
    @default = @issue.accounting.id
    @edit_allowed = User.current.allowed_to?(:edit_issues, @project)
    @time_entry = TimeEntry.new

    @notes = params[:notes]
    journal = @issue.init_journal(User.current, @notes)
    # User can change issue attributes only if he has :edit permission or if a workflow transition is allowed
    if (@edit_allowed || !@allowed_statuses.empty?) && params[:issue]
      attrs = params[:issue].dup
      attrs.delete_if {|k,v| !UPDATABLE_ATTRS_ON_TRANSITION.include?(k) } unless @edit_allowed
      attrs.delete(:status_id) unless @allowed_statuses.detect {|s| s.id.to_s == attrs[:status_id].to_s}
      issue_clone = @issue.clone
      @issue.attributes = attrs
    end

    if request.post?
      Issue.transaction do
        @time_entry = TimeEntry.new(:project => @project, :issue => @issue, :user => User.current, :spent_on => Date.today)
        @time_entry.attributes = params[:time_entry]
        attachments = attach_files(@issue, params[:attachments])
        attachments.each {|a| journal.details << JournalDetail.new(:property => 'attachment', :prop_key => a.id, :value => a.filename)}
      
        call_hook(:controller_issues_edit_before_save, { :params => params, :issue => @issue, :time_entry => @time_entry, :journal => journal})

        if (@time_entry.hours.nil? || @time_entry.valid?) && @issue.save
          # Log spend time
          if User.current.allowed_to?(:log_time, @project)
            @time_entry.save
            if !@time_entry.hours.nil?
              journal.details << JournalDetail.new(:property => 'timelog', :prop_key => 'hours', :value => @time_entry.hours)
              journal.details << JournalDetail.new(:property => 'timelog', :prop_key => 'activity_id', :value => @time_entry.activity_id)
              journal.details << JournalDetail.new(:property => 'timelog', :prop_key => 'spent_on', :value => @time_entry.spent_on)
              if !@issue.estimated_hours.nil?
                total_time_entry = TimeEntry.sum(:hours, :conditions => "issue_id = #{@issue.id}")
                remaining_estimate = @issue.estimated_hours - total_time_entry
                journal.details << JournalDetail.new(:property => 'timelog', :prop_key => 'remaining_estimate',
                                                     :value => remaining_estimate >= 0 ? remaining_estimate : 0)
              end
              #journal.save
            end
            if !@time_entry.hours.nil? || !journal.notes.blank?
              journal.save
            end
          end
          if !journal.new_record?
            # Only send notification if something was actually changed
            flash[:notice] = l(:notice_successful_update)
          end
          call_hook(:controller_issues_edit_after_save, { :params => params, :issue => @issue, :time_entry => @time_entry, :journal => journal})
          if update_ticket_at_mystic?
            return(update_mystic_ticket(@issue, @notes))
          else
            redirect_to(params[:back_to] || {:controller => 'treeview', :action => 'show', :id => @issue})
          end
        end
      end # transaction end
    end
  rescue ActiveRecord::StaleObjectError
    # Optimistic locking exception
    flash.now[:error] = l(:notice_locking_conflict)
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
  
  def split
    respond_to do |format|
      format.html
      format.js { render_to_facebox :template => "treeview/split" }
    end
  end
  
  def destroy
    @hours = TimeEntry.sum(:hours, :conditions => ['issue_id IN (?)', @issues]).to_f
    if @hours > 0
      case params[:todo]
      when 'destroy'
        # nothing to do
      when 'nullify'
        TimeEntry.update_all('issue_id = NULL', ['issue_id IN (?)', @issues])
      when 'reassign'
        reassign_to = @project.issues.find_by_id(params[:reassign_to_id])
        if reassign_to.nil?
          flash.now[:error] = l(:error_issue_not_found_in_project)
          return
        else
          TimeEntry.update_all("issue_id = #{reassign_to.id}", ['issue_id IN (?)', @issues])
        end
      else
        # display the destroy form
        return
      end
    end
    @issues.each(&:destroy)
    redirect_to :controller => 'treeview', :action => 'index', :project_id => @project
  end
    
  private
  def treeview_authorize(action = params[:action])
    puts action
    puts @project
    allowed = User.current.allowed_to?({:controller => 'issues', :action => action}, @project)
    allowed ? true : deny_access
  end
  
  def add_defaults
    tracker_condition    = "name='Feature' or name='Task'"
    tracker_condition += " or name='Bug'" if params[:include_bugs] || session[:us_query][:include_bugs]
    @query.add_filter 'tracker_id', '=', Tracker.find(:all, :select => :id, :conditions => tracker_condition).collect {|c| c.id.to_s}
    if session[:us_query][:column_names]
      @query.column_names = session[:us_query][:column_names]
    else
      @query.column_names = [:tracker, :subject, :assigned_to, :status]
      story_points = CustomField.find(:first, :select => 'id', :conditions => "name = 'Story Points'")
      @query.column_names += ["cf_#{story_points.id}".to_sym] unless story_points.nil?
    end
    # always show  subject column
    @query.column_names += [:subject] unless @query.column_names.include?(:subject)
  end
  
  def retrieve_query
    if params[:set_filter] || session[:us_query].nil? || session[:us_query][:project_id] != (@project ? @project.id : nil)
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
        @query.add_filter('fixed_version_id', '=', [''])
        @query.add_filter('status_id', '*', [''])
      end
      session[:us_query] = {:project_id => @query.project_id, :filters => @query.filters, :include_bugs => params[:include_bugs]}
    else
      @query = Query.find_by_id(session[:us_query][:id]) if session[:us_query][:id]
      @query ||= Query.new(:name => "_", :project => @project, :filters => session[:us_query][:filters])
      @query.add_filter('fixed_version_id', '=', ['']) unless session[:us_query][:filters] && session[:us_query][:filters]["fixed_version_id"]
      @query.add_filter('status_id', '*', ['']) unless session[:us_query][:filters] && session[:us_query][:filters]["status_id"]
      @query.project = @project
    end
    add_defaults
    @query.column_names = params[:column_names] if params[:column_names]
    session[:us_query][:column_names] = @query.column_names
  end
end
