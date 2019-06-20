require 'rake_helper'

describe 'rake gitlab:pages:make_all_public' do
  let!(:public_pages_project) { create(:project, :pages_public) }
  let!(:project_for_update) { create(:project, :pages_enabled) }
  let!(:project_without_deployed_pages) { create(:project, :pages_enabled)}

  let(:migration_name) { 'MakePagesSitesPublic' }

  before do
    Rake.application.rake_require 'tasks/gitlab/pages'

    allow_any_instance_of(Project).to receive(:pages_deployed?) do |project|
      project.id != project_without_deployed_pages.id
    end
  end

  subject do
    run_rake_task('gitlab:pages:make_all_public')
  end

  it 'schedules background migrations' do
    Sidekiq::Testing.fake! do
      Timecop.freeze do
        subject

        first_id = project_for_update.id
        last_id = project_without_deployed_pages.id

        expect(migration_name).to be_scheduled_delayed_migration(2.minutes, first_id, last_id)
      end
    end
  end

  it 'updates settings' do
    perform_enqueued_jobs do
      expect do
        subject
      end.to change { project_for_update.reload.project_feature.pages_access_level }.from(ProjectFeature::ENABLED).to(ProjectFeature::PUBLIC)
    end
  end

  it 'updates pages config' do
    perform_enqueued_jobs do
      service = instance_double('::Projects::UpdatePagesConfigurationService')
      expect(::Projects::UpdatePagesConfigurationService).to receive(:new).with(project_for_update).and_return(service)
      expect(service).to receive(:execute)

      subject
    end
  end

  it 'skips projects without deployed pages' do
    perform_enqueued_jobs do
      expect(::Projects::UpdatePagesConfigurationService).not_to receive(:new).with(project_without_deployed_pages)

      expect do
        subject
      end.not_to change { project_without_deployed_pages.reload.project_feature.pages_access_level }.from(ProjectFeature::ENABLED)
    end
  end
end
