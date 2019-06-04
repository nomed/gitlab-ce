module Gitlab
  module CycleAnalytics
    module TestHelper
      def stage_query(project_ids)
        if @options[:branch]
          super(project_ids).where(build_table[:ref].eq(@options[:branch]))
        else
          super(project_ids)
        end
      end
    end
  end
end
