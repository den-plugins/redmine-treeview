module CarryOverHelper
  
  def self.carry_over(params)
    original = Issue.find params[:id]
    carry_over = params[:carry_over_to]
    carries = carry_over[:issues]
    issue = original.custom_clone
    issue.attributes = self.create_attributes(carry_over, issue)
    if issue.save and carries and carries!=""
      carries = carries.split(",").map{|x| Issue.find(x.to_i)}
      arr = original.children
      ref = {}
      flag = arr.empty?
      while !flag
        puts arr.map(&:id)
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
      #original.status = IssueStatus.find_by_name("Carried Over")
      #original.save
    end
  end

  def self.create_issue(issue, parent, hash, create_parent)
    begin
      new = issue.custom_clone
      new.subject.gsub!(/(\[CO\])+/, "[CO]")
      new.attributes = {"custom_field_values" => self.create_custom_fields(issue.custom_values)}
      if new.save
        #issue.status = IssueStatus.find_by_name("Carried Over")
        #issue.save
      end
      exist = Issue.find(:all, :conditions=>{:subject=>parent.subject, 
                                             :description=>parent.description,
                                             :tracker_id=>parent.tracker_id,
                                             :priority_id=>parent.priority_id}).sort_by(&:created_on).last
      if exist.id == parent.id and create_parent
        np = parent.custom_clone
        np.attributes = {"custom_field_values" => self.create_custom_fields(parent.custom_values)}
        np.save
        #parent.status = IssueStatus.find_by_name("Carried Over")
        #parent.save
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
    #rescue
      #hash
    end
  end
  
  def self.create_attributes(carry_over, issue)
    hash = {"subject" => "#{carry_over[:subject]}[CO]",
            "priority_id" => carry_over[:priority_id],
            "description" => carry_over[:description],
            "fixed_version_id" => carry_over[:fixed_version_id]}
    hash["custom_field_values"] = self.create_custom_fields(issue.custom_values) if !issue.custom_values.empty?
    hash
  end

  def self.create_custom_fields(custom_values)
    hash = {}
    custom_values.each do |c|
      hash["#{c.custom_field_id}"] = c.value
    end
    hash
  end
end
