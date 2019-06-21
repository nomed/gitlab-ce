# frozen_string_literal: true

class Projects::MergeRequests::WidgetController < Projects::MergeRequests::ApplicationController
  around_action :allow_gitaly_ref_name_caching

  def show
    respond_to do |format|
      format.json do
        Gitlab::PollingInterval.set_header(response, interval: 10_000)

        serializer = MergeRequestSerializer.new(current_user: current_user, project: merge_request.project)
        render json: serializer.represent(merge_request, serializer: 'widget')
      end
    end
  end
end
