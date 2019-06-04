# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module TestHelper
      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      def stage_query(project_ids)
        if @options[:branch]
          super(project_ids).where(build_table[:ref].eq(@options[:branch]))
        else
          super(project_ids)
        end
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables
    end
  end
end
