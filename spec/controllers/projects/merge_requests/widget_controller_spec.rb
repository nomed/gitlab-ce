# frozen_string_literal: true

require 'spec_helper'

describe Projects::MergeRequests::WidgetController do
  let(:project) { create(:project, :repository) }
  let(:user) { project.owner }
  let(:merge_request) { create(:merge_request, target_project: project, source_project: project) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET show' do
    before do
      expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original
    end

    it 'renders widget MR entity as json' do
      get :show, params: {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid,
        format: :json
      }

      expect(response).to match_response_schema('entities/merge_request_widget')
    end
  end
end
