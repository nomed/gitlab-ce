# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # changes access level for pages sites to public and updates config
    class MakeAllPagesSitesPublic
      include Gitlab::Database::MigrationHelpers

      MIGRATION = 'MakePagesSitesPublic'
      BATCH_SIZE = 20000
      BATCH_TIME = 2.minutes

      # ProjectFeature
      class ProjectFeature < ApplicationRecord
        include ::EachBatch

        self.table_name = 'project_features'

        PUBLIC   = 30
      end

      def perform
        features = ProjectFeature.arel_table
        features_to_update = ProjectFeature.where(features[:pages_access_level].lt(ProjectFeature::PUBLIC))

        queue_background_migration_jobs_by_range_at_intervals(
          features_to_update,
          MIGRATION,
          BATCH_TIME,
          batch_size: BATCH_SIZE)
      end
    end
  end
end
