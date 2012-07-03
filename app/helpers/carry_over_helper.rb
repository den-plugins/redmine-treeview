module CarryOverHelper
  
  def self.create_carried_issue(params)
    original = Issue.find params[:id]
    carry_over = params[:carry_over_to]
    carries = carry_over[:issues]
    issue = original.clone
    issue.subject = carry_over[:subject]
    issue.priority_id = carry_over[:priority_id]
    issue.description = carry_over[:description]
    issue.fixed_version_id = carry_over[:fixed_version_id]
    issue.custom_values = original.custom_values
    if issue.save and carries and carries!=""
      carries = carries.split(",").map{|x| Issue.find(x.to_i)}
      arr = original.children
      ref = {}
      flag = arr.empty?
      while !flag
        arr.each do |c|
          if c.parent.issue_from == original and (!c.children.empty? or carries.include?(c)) 
            ref = self.create_issue(c, issue, ref, false)
          elsif !c.children.empty? or carries.include? c
            ref = self.create_issue(c, ref[:"#{c.parent.issue_from.id}"], ref, true) 
          end
          arr += c.children
          arr.delete c
        end
        flag = arr.empty?
      end
    end
  end

  def self.create_issue(issue, parent, hash, create_parent)
    begin
      new = issue.clone
      begin
        new.custom_values = issue.custom_values
        new.status_id = issue.status_id
      end while !new.save
      exist = Issue.find(:all, :conditions=>{:subject=>parent.subject, 
                                             :description=>parent.description,
                                             :tracker_id=>parent.tracker_id,
                                             :priority_id=>parent.priority_id}).sort_by(&:created_on).last
      if exist.id == parent.id and create_parent
        np = parent.clone
        np.custom_values = parent.custom_values
      else
        np = exist
      end
      new_parent = np
      
      rel = IssueRelation.new
      rel.issue_from = new_parent
      rel.issue_to = new
      rel.relation_type = issue.parent.relation_type
      rel.save
      hash[:"#{parent.id}"] = parent
      hash[:"#{issue.id}"] = issue
      hash
    rescue
      hash
    end
  end
end
