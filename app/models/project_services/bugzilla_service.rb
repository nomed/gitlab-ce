# frozen_string_literal: true

class BugzillaService < IssueTrackerService
  def title
    if self.properties && self.properties['title'].present?
      self.properties['title']
    else
      'Bugzilla'
    end
  end

  def description
    if self.properties && self.properties['description'].present?
      self.properties['description']
    else
      'Bugzilla issue tracker'
    end
  end

  def self.to_param
    'bugzilla'
  end
end
