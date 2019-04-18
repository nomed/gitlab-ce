# frozen_string_literal: true

namespace :jira_connect do
  # This is so we can have a named route helper for the base URL
  root to: proc { [404, {}, ['']] }, as: 'base'

  get 'app_descriptor' => 'app_descriptor#show'

  namespace :events do
    post 'installed'
    post 'uninstalled'
  end

  get 'configuration' => 'configuration#show'
end