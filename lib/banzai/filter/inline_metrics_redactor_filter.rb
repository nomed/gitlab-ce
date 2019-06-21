# frozen_string_literal: true

module Banzai
  module Filter
    # HTML filter that removes embeded elements that the current user does
    # not have permission to view.
    #
    # Currently includes only embedded metrics, but should
    # be refactored to include future inline embeds.
    class InlineMetricsRedactorFilter < HTML::Pipeline::Filter
      CSS_SIGNAL = '.js-render-metrics'

      # Finds all embeds based on the css class the FE
      # uses to identify the embedded content, removing
      # only necessary nodes.
      def call
        doc.css(CSS_SIGNAL).each do |node|
          project = project_for_node(node)
          user = context[:current_user]

          node.remove if should_remove_node?(user, project)
        end

        doc
      end

      private

      def project_for_node(node)
        namespace = node.attribute('data-namespace').to_s
        project = node.attribute('data-project').to_s

        Project.find_by_full_path("#{namespace}/#{project}")
      end

      def should_remove_node?(user, project)
        !Ability.allowed?(user, :read_environment, project)
      end
    end
  end
end
