module CarryOverHelper
  
  def self.carry_over(params)
    original = Issue.find params[:id]
    carry_over = params[:carry_over_to]
    carries = carry_over[:issues]
    issue = original.custom_clone
    issue.attributes = self.create_attributes(carry_over, issue)
    if carries and carries!=""
      begin
        issue.save!
      rescue ActiveRecord::RecordInvalid
        return false
      else
        tree_list = [issue]
        carries = carries.split(",").map{|x| Issue.find(x.to_i)}
        arr = self.get_issues_to_be_carried(original.children, carries)
        flag = arr.empty?
        while !flag
          arr.each do |c|
            if c.parent.issue_from_id != original.id
              arr << c.parent.issue_from
              tree_list = self.create_issue(c, c.parent.issue_from, true, issue.fixed_version, tree_list)
            else
              tree_list = self.create_issue(c, issue, false, issue.fixed_version, tree_list)
            end
            arr.delete c
          end
          flag = arr.empty?
        end
      return true
      end
    end
  end

  def self.get_issues_to_be_carried(arr, carries)
    ret = []
    flag = arr.empty?
    while !flag
      arr.each do |x|
        arr.delete x
        arr += x.children
        ret << x if carries.include?(x)
      end
      flag = arr.empty?
    end
    ret
  end
  
  def self.create_issue(issue, parent, create_parent, version, tree_list)
    exist_issue = (Issue.find(:all, :conditions=>{:subject=>"#{issue.subject.gsub(/(\[CO\])+/, "")}[CO]", 
                                                 :fixed_version_id=>version.id}) & tree_list).last
    exist_parent = (Issue.find(:all, :conditions=>{:subject=>"#{parent.subject.gsub(/(\[CO\])+/, "")}[CO]", 
                                                  :fixed_version_id=>version.id}) & tree_list).last
    if exist_issue.nil?
      new = issue.custom_clone
      new.subject = new.subject.gsub(/(\[CO\])+/, "") + "[CO]"
      new.attributes = {"fixed_version_id" => version.id,
                        "custom_field_values" => self.create_custom_fields(issue.custom_values)}
      if new.save
        tree_list << new
        issue = Issue.find(issue.id)
        issue.status = IssueStatus.find_by_name("Carried Over")
        puts "issue #{issue.save}"
      end
    else
      new = exist_issue
    end
    
    if exist_parent.nil? and create_parent
      np = parent.custom_clone
      np.subject = np.subject.gsub(/(\[CO\])+/, "") + "[CO]"
      np.attributes = {"fixed_version_id" => version.id,
                       "custom_field_values" => self.create_custom_fields(parent.custom_values)}
      if np.save
        tree_list << np
        parent = Issue.find(parent.id)
        unless parent.children.map{|x| x.status.is_closed}.include? false
          parent.status = IssueStatus.find_by_name("Carried Over") 
          puts "parent #{parent.save}"
        end
      end
    elsif exist_parent and create_parent
      np = exist_parent
    else
      np = parent
    end
    
    if new and np
      rel = IssueRelation.new
      rel.issue_from = np
      rel.issue_to = new
      rel.relation_type = issue.parent.relation_type
      puts rel.inspect
      puts "relationship #{rel.save}"
    end
    tree_list
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

  def self.get_children(parent)
    flag = false
    arr = parent.children
    children = []
    while !flag
      arr.each do |x|
        arr.delete x
        x.children.empty? ? children << x : arr += x.children
      end
      flag = arr.empty?
    end
    children
  end
end
