module ApplicationHelper
  def condition_badge_class(condition)
    case condition.to_s.downcase
    when /new|全新/
      "badge-success"
    when /like new|9成新|90%/
      "badge-warning"
    when /good|used|8成新|二手/
      "badge-info"
    else
      "badge-neutral"
    end
  end
end
