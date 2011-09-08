module TreeviewHelper
  
  def node_level(issue)
    l = 0
    until issue.parent.nil?
      l += 1
      issue = issue.parent.other_issue(issue)
    end
    l
  end
end
