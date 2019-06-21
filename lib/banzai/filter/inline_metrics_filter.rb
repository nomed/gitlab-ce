# frozen_string_literal: true

module Banzai
  module Filter
    # HTML filter that inserts a placeholder element for each
    # reference to a metrics dashboard.
    class InlineMetricsFilter < Banzai::Filter::InlineEmbedsFilter
      # Placeholder element for the frontend to use as an
      # injection point for charts.
      def element_to_embed(doc, params)
        doc.document.create_element(
          'div',
          class: 'js-render-metrics',
          'data-dashboard-url': embedded_metrics_url(params),
          'data-namespace': params['namespace'],
          'data-project': params['project']
        )
      end

      # Endpoint FE should hit to collect the appropriate
      # chart information
      def embedded_metrics_url(params)
        Gitlab::Routing.url_helpers.metrics_dashboard_namespace_project_environment_url(
          params['namespace'],
          params['project'],
          params['environment'],
          embedded: true
        )
      end

      # Identifies the url for the metrics dashboard.
      # https://<host>/<namespace>/<project>/environments/<env_id>/metrics
      def url_regex
        %r{
          (?<url>
            #{Regexp.escape(Gitlab.config.gitlab.url)}
            \/#{Project.reference_pattern}
            (?:\/\-)?
            \/environments
            \/(?<environment>\d+)
            \/metrics
            (?<path>
              (\/[a-z0-9_=-]+)*
            )?
            (?<query>
              \?[a-z0-9_=-]+
              (&[a-z0-9_=-]+)*
            )?
            (?<anchor>\#[a-z0-9_-]+)?
          )
        }x
      end
    end
  end
end
