shared_examples 'data fields handling' do
  context 'reading data' do
    it 'reads data correctly' do
      expect(service.project_url).to eq(project_url)
      expect(service.issues_url).to eq(issues_url)
      expect(service.new_issue_url).to eq(new_issue_url)
    end
  end

  context '#create' do
    subject { described_class.create(params) }

    it 'does not store data into properties' do
      expect(subject.properties).to be_empty
    end

    it 'sets data correctly' do
      service = subject

      expect(service.project_url).to eq(project_url)
      expect(service.issues_url).to eq(issues_url)
      expect(service.new_issue_url).to eq(new_issue_url)
    end
  end

  context '#update' do
    before do
      service.update(new_issue_url: 'http://new-issue.tracker.com')
    end

    it 'leaves properties field emtpy' do
      expect(service.reload.properties).to be_empty
    end

    it 'stores updated data in jira_tracker_data table' do
      data = service.issue_tracker_data.reload

      expect(data.project_url).to eq(project_url)
      expect(data.issues_url).to eq(issues_url)
      expect(data.new_issue_url).to eq('http://new-issue.tracker.com')
    end
  end
end
