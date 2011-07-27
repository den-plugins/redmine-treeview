class TreeviewController < IssuesController

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
      @issue_count = Issue.count(:include => [:status, :project], :conditions => @query.statement)
      @issue_pages = Paginator.new self, @issue_count, limit, params['page']
      @issues = Issue.find :all, :order => sort_clause,
                           :include => [ :assigned_to, :status, :tracker, :project, :priority, :category, :fixed_version ],
                           :conditions => @query.statement,
                           :limit  =>  limit,
                           :offset =>  @issue_pages.current.offset
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
end
