require 'spec_helper'

describe 'Discussion Comments Commit', :js do
  include RepoHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let!(:commit_discussion_note) { create(:discussion_note_on_commit, project: project) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_commit_path(project, sample_commit.id)
  end

  it_behaves_like 'discussion comments', 'commit'

  it 'has class .js-note-emoji' do
    expect(page).to have_css('.js-note-emoji')
  end
end
