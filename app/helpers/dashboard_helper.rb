# frozen_string_literal: true

module DashboardHelper
  include IconsHelper

  def assigned_issues_dashboard_path
    issues_dashboard_path(assignee_username: current_user.username)
  end

  def assigned_mrs_dashboard_path
    merge_requests_dashboard_path(assignee_username: current_user.username)
  end

  def dashboard_nav_links
    @dashboard_nav_links ||= get_dashboard_nav_links
  end

  def dashboard_nav_link?(link)
    dashboard_nav_links.include?(link)
  end

  def any_dashboard_nav_link?(links)
    links.any? { |link| dashboard_nav_link?(link) }
  end

  def has_start_trial?
    false
  end

  def feature_entry(title, href, enabled = true)
    output = content_tag(:p, 'aria-label' => "#{title}: status " + (enabled ? 'on' : 'off')) do
      concat(enabled && href ? content_tag(:a, title, href: href) : title)
      concat(content_tag(:span, '', class: ['light', 'float-right']) do
        concat(boolean_to_icon enabled)
      end)
    end
    output.html_safe
  end

  private

  def get_dashboard_nav_links
    links = [:projects, :groups, :snippets]

    if can?(current_user, :read_cross_project)
      links += [:activity, :milestones]
    end

    links
  end
end
