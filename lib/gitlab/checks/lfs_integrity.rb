# frozen_string_literal: true

module Gitlab
  module Checks
    class LfsIntegrity
      def initialize(project, newrev, time_left)
        @project = project
        @newrev = newrev
        @time_left = time_left
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def objects_missing?
        return false unless @newrev && @project.lfs_enabled?

        new_lfs_pointers = Gitlab::Git::LfsChanges.new(@project.repository, @newrev)
                                                  .new_pointers(object_limit: ::Gitlab::Git::Repository::REV_LIST_COMMIT_LIMIT, dynamic_timeout: @time_left)

        return false unless new_lfs_pointers.present?

        existing_count = @project.all_lfs_objects
                                 .where(oid: new_lfs_pointers.map(&:lfs_oid))
                                 .size

        existing_count != new_lfs_pointers.size
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
