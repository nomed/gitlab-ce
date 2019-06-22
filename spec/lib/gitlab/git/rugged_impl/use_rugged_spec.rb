# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'tempfile'

describe Gitlab::Git::RuggedImpl::UseRugged, :seed_helper do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:feature_flag) { 'feature-flag-name' }
  let(:temp_gitaly_metadata_file) { create_temporary_gitaly_metadata_file }

  before(:all) do
    create_gitaly_metadata_file
  end

  subject(:wrapper) do
    klazz = Class.new { include Gitlab::Git::RuggedImpl::UseRugged }
    klazz.new
  end

  before do
#    allow(Gitlab::Git::RuggedImpl::UseRugged).to receive(:use_rugged?).and_call_original
    allow(Feature).to receive(:enabled?).with(feature_flag).and_return(true)
  end

  it 'returns true when gitaly matches disk' do
    expect(subject.use_rugged?(repository, feature_flag)).to be true
  end

  it 'returns false when disk access fails' do
    allow(repository).to receive(:path_to_gitaly_metadata_file).and_return("/fake/path/doesnt/exist")

    expect(subject.use_rugged?(repository, feature_flag)).to be false
  end

  it 'returns false when the feature flag is off' do
    allow(Feature).to receive(:enabled?).with(feature_flag).and_return(false)

    expect(subject.use_rugged?(repository, feature_flag)).to be_falsey
  end

  it "returns false when gitaly doesn't match disk" do
    allow(repository).to receive(:path_to_gitaly_metadata_file).and_return(temp_gitaly_metadata_file)

    expect(subject.use_rugged?(repository, feature_flag)).to be_falsey

    File.delete(temp_gitaly_metadata_file)
  end

  def create_temporary_gitaly_metadata_file
    tmp = Tempfile.new('.gitaly-metadata')
    gitaly_metadata = {
      "gitaly_filesystem_id" => "some-value"
    }
    tmp.write(gitaly_metadata.to_json)
    tmp.flush
    tmp.close
    tmp.path
  end

  def create_gitaly_metadata_file
    File.open(File.join(SEED_STORAGE_PATH, '.gitaly-metadata'), 'w+') do |f|
      gitaly_metadata = {
        "gitaly_filesystem_id" => SecureRandom.uuid
      }
      f.write(gitaly_metadata.to_json)
    end
  end
end
