# frozen_string_literal: true

require 'spec_helper'

describe Projects::DivergingCountsController do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:user) { create(:user) }

  before do
    project.add_developer(user)
    controller.instance_variable_set(:@project, project)

    sign_in(user)
  end

  describe '#index' do
    before do
      get :index,
          format: :json,
          params: {
            namespace_id: project.namespace,
            project_id: project,
            names: ['fix', 'add-pdf-file', 'branch-merged']
          }
    end

    it 'returns the commit counts behind and ahead of default branch' do
      parsed_response = JSON.parse(response.body)
      expect(parsed_response).to eq(
        "fix" => { "behind" => 29, "ahead" => 2 },
        "branch-merged" => { "behind" => 1, "ahead" => 0 },
        "add-pdf-file" => { "behind" => 0, "ahead" => 3 }
      )
    end
  end
end
