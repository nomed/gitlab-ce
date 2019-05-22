# frozen_string_literal: true

danger.import_plugin('danger/plugins/helper.rb')

LOCAL_DANGER_FILES = %w{
  danger/changes_size
  danger/gemfile
  danger/documentation
  danger/frozen_string
  danger/duplicate_yarn_dependencies
  danger/prettier
  danger/eslint
}.freeze

REMOTE_DANGER_FILES = %w{
  danger/metadata
  danger/changelog
  danger/specs
  danger/database
  danger/commit_messages
  danger/single_codebase
  danger/gitlab_ui_wg
  danger/ce_ee_vue_templates
}.freeze

CI_ONLY_DANGER_FILES = %w{
  danger/roulette
}.freeze

all_danger_files = LOCAL_DANGER_FILES
all_danger_files += REMOTE_DANGER_FILES

if ENV['GITLAB_CI'] && !helper.release_automation?
  # all_danger_files += REMOTE_DANGER_FILES
  # all_danger_files += CI_ONLY_DANGER_FILES
end

all_danger_files.each { |file| danger.import_dangerfile(path: file) }
