# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # changes access level for pages sites to public and updates config
    class MakePagesSitesPublic
      def perform(start_id, stop_id)
        ProjectFeature.where(id: start_id..stop_id).includes(:project).find_each do |project_feature|
          project = project_feature.project
          next unless project.pages_deployed?

          project_feature.update!(pages_access_level: ProjectFeature::PUBLIC)
          ::Projects::UpdatePagesConfigurationService.new(project).execute
        rescue => e
          Rails.logger.error "Failed to make pages site public. project_feature_id: #{project_feature.id}, message: #{e.message}"
        end
      end
    end
  end
end
