# frozen_string_literal: true
require 'spec_helper'

describe ChatMessage::PipelineMessage do
  subject { described_class.new(args) }

  before do
    test_commit = double("A test commit", committer: user, title: "A test commit message")
    test_project = double("A test project",
                          commit_by: test_commit, name: project[:name],
                          web_url: project[:web_url], avatar_url: project[:avatar_url])
    allow(Project).to receive(:find) { test_project }

    test_pipeline = double("A test pipeline", has_yaml_errors?: has_yaml_errors,
                          yaml_errors: "yaml error description here")
    allow(Ci::Pipeline).to receive(:find) { test_pipeline }

    allow(Gitlab::UrlBuilder).to receive(:build).with(test_commit).and_return("http://example.com/commit")
    allow(Gitlab::UrlBuilder).to receive(:build).with(user).and_return("http://example.gitlab.com/hacker")
  end

  let(:user) do
    {
      id: 345,
      name: "The Hacker",
      username: "hacker",
      email: "hacker@example.gitlab.com",
      avatar_url: "http://example.com/avatar"
    }
  end

  let(:name_of_user) { user ? "#{user[:name]} (#{user[:username]})" : "API" }

  let(:user_profile_link) { user ? "http://example.gitlab.com/hacker" : nil }

  let(:project) do
    {
      id: 234,
      name: "project_name",
      path_with_namespace: 'group/project_name',
      web_url: 'http://example.gitlab.com',
      avatar_url: 'http://example.com/project_avatar'
    }
  end

  let(:status) { "success" }

  let(:detailed_status) { nil }

  let(:has_yaml_errors) { false }

  let(:builds) { nil }

  let(:args) do
    {
      object_attributes: {
        id: 123,
        sha: '97de212e80737a608d939f648d959671fb0a0142',
        tag: false,
        ref: 'develop',
        status: status,
        detailed_status: detailed_status,
        duration: 7210,
        finished_at: "2019-05-27 11:56:36 -0300"
      },
      project: project,
      user: user,
      commit: {
        id: "abcdef"
      },
      builds: builds
    }
  end

  let(:slack_formatted_message) do
    "<http://example.gitlab.com|project_name>:" \
        " Pipeline <http://example.gitlab.com/pipelines/123|#123>" \
        " of branch <http://example.gitlab.com/commits/develop|develop>" \
        " by #{name_of_user} #{status_text} in 02:00:10"
  end

  let(:markdown_message) do
    "[project_name](http://example.gitlab.com):" \
        " Pipeline [#123](http://example.gitlab.com/pipelines/123)" \
        " of branch [develop](http://example.gitlab.com/commits/develop)" \
        " by #{name_of_user} #{status_text} in 02:00:10"
  end

  let(:activity) do
    {
      title: "Pipeline [#123](http://example.gitlab.com/pipelines/123) of branch [develop](http://example.gitlab.com/commits/develop) by #{name_of_user} #{status_text}",
      subtitle: "in [project_name](http://example.gitlab.com)",
      text: 'in 02:00:10',
      image: user ? user[:avatar_url] : ""
    }
  end

  let(:simple_attachments) do
    [{
      text: slack_formatted_message,
      color: color
    }]
  end

  let(:additional_fields) { [] }

  let(:fancy_attachments) do
    [{
      fallback: slack_formatted_message,
      color: color,
      author_name: name_of_user,
      author_icon: user ? user[:avatar_url] : nil,
      author_link: user_profile_link,
      title: "Pipeline #123 #{status_text} in 02:00:10",
      title_link: "http://example.gitlab.com/pipelines/123",
      fields: [
        {
          title: "Branch",
          value: "<http://example.gitlab.com/commits/develop|develop>",
          short: true
        },
        {
          title: "Commit",
          value: "<http://example.com/commit|A test commit message>",
          short: true
        }
      ].concat(additional_fields),
      footer: "project_name",
      footer_icon: "http://example.com/project_avatar",
      ts: 1558968996
    }]
  end

  context 'without markdown' do
    shared_examples 'a correct response' do
      context 'when the fancy_pipeline_slack_notifications feature flag is disabled' do
        let(:status_text) { status == "success" ? "passed" : status }
        let(:color) { status == "success" ? "good" : "danger" }

        it 'returns the correct pretext, fallback, and attachments' do
          stub_feature_flags(fancy_pipeline_slack_notifications: false)

          expect(subject.pretext).to be_empty
          expect(subject.fallback).to eq(slack_formatted_message)
          expect(subject.attachments).to eq(simple_attachments)
        end
      end

      context 'when the fancy_pipeline_slack_notifications feature flag is enabled' do
        let(:status_text) do
          case status
          when "success"
            detailed_status == "passed with warnings" ? "has passed with warnings" : "has passed"
          else
            "has failed"
          end
        end
        let(:color) do
          case status
          when "success"
            detailed_status == "passed with warnings" ? "warning" : "good"
          else
            "danger"
          end
        end

        it 'returns the correct pretext, fallback, and attachments' do
          stub_feature_flags(fancy_pipeline_slack_notifications: true)

          expect(subject.pretext).to be_empty
          expect(subject.fallback).to eq(slack_formatted_message)
          expect(subject.attachments).to eq(fancy_attachments)
        end
      end
    end

    context 'pipeline succeeded' do
      let(:status) { 'success' }

      it_behaves_like 'a correct response'

      context 'with warnings' do
        let(:detailed_status) { 'passed with warnings' }

        it_behaves_like 'a correct response'
      end
    end

    context 'pipeline failed' do
      let(:status) { 'failed' }

      context 'when a single job fails' do
        let(:builds) do
          [
            { id: 567, name: "rspec", status: "failed", stage: "test" },
            { id: 678, name: "karma", status: "success", stage: "test" }
          ]
        end
        let(:additional_fields) do
          [
            { title: "Failed stage", value: "<http://example.gitlab.com/pipelines/123|test>", short: true },
            { title: "Failed job", value: "<http://example.gitlab.com/-/jobs/567|rspec>", short: true }
          ]
        end

        it_behaves_like 'a correct response'
      end

      context 'when two jobs fail' do
        let(:builds) do
          [
            { id: 567, name: "rspec", status: "failed", stage: "test" },
            { id: 678, name: "eslint", status: "failed", stage: "test" },
            { id: 789, name: "karma", status: "success", stage: "test" }
          ]
        end
        let(:additional_fields) do
          [
            { title: "Failed stage", value: "<http://example.gitlab.com/pipelines/123|test>", short: true },
            { title: "Failed jobs", value: "<http://example.gitlab.com/-/jobs/678|eslint>, <http://example.gitlab.com/-/jobs/567|rspec>", short: true }
          ]
        end

        it_behaves_like 'a correct response'
      end

      context 'when 12 jobs fail' do
        let(:builds) do
          (1..ChatMessage::PipelineMessage::MAX_VISIBLE_JOBS).map do |i|
            { id: i, name: "failed-job-#{i}", status: "failed", stage: "test" }
          end
        end
        let(:additional_fields) do
          failed_jobs_text_array = builds.reverse.map { |b| "<http://example.gitlab.com/-/jobs/#{b[:id]}|#{b[:name]}>" }

          [
            { title: "Failed stage", value: "<http://example.gitlab.com/pipelines/123|test>", short: true },
            { title: "Failed jobs", value: failed_jobs_text_array.join(', '), short: true }
          ]
        end

        it_behaves_like 'a correct response'
      end

      context 'when 13 jobs fail' do
        let(:builds) do
          (1..ChatMessage::PipelineMessage::MAX_VISIBLE_JOBS + 1).map do |i|
            { id: i, name: "failed-job-#{i}", status: "failed", stage: "test" }
          end
        end
        let(:additional_fields) do
          failed_jobs_text_array = builds.reverse.first(ChatMessage::PipelineMessage::MAX_VISIBLE_JOBS - 1).map { |b| "<http://example.gitlab.com/-/jobs/#{b[:id]}|#{b[:name]}>" }
          failed_jobs_text_array.push("and <http://example.gitlab.com/pipelines/123/builds|2 more>")

          [
            { title: "Failed stage", value: "<http://example.gitlab.com/pipelines/123|test>", short: true },
            { title: "Failed jobs", value: failed_jobs_text_array.join(', '), short: true }
          ]
        end

        it_behaves_like 'a correct response'
      end

      context 'when jobs fail in multiple stages' do
        let(:builds) do
          [
            { id: 567, name: "rspec", status: "failed", stage: "test" },
            { id: 678, name: "karma", status: "success", stage: "test" },
            { id: 789, name: "review", status: "failed", stage: "review" }
          ]
        end
        let(:additional_fields) do
          [
            { title: "Failed stages", value: "<http://example.gitlab.com/pipelines/123|review>, <http://example.gitlab.com/pipelines/123|test>", short: true },
            { title: "Failed jobs", value: "<http://example.gitlab.com/-/jobs/789|review>, <http://example.gitlab.com/-/jobs/567|rspec>", short: true }
          ]
        end

        it_behaves_like 'a correct response'
      end

      context 'when the yaml file is invalid' do
        let(:has_yaml_errors) { true }
        let(:additional_fields) do
          [{ title: "Invalid CI config YAML file", value: "yaml error description here", short: false }]
        end

        it_behaves_like 'a correct response'
      end

      context 'when triggered by API therefore lacking user' do
        let(:user) { nil }

        it_behaves_like 'a correct response'
      end
    end
  end

  context 'with markdown' do
    before do
      args[:markdown] = true
    end

    shared_examples 'a correct response' do
      context 'when the fancy_pipeline_slack_notifications feature flag is disabled' do
        let(:status_text) { status == "success" ? "passed" : status }
        let(:color) { status == "success" ? "good" : "danger" }

        it 'returns the correct pretext, attachments, and activity' do
          stub_feature_flags(fancy_pipeline_slack_notifications: false)

          expect(subject.pretext).to be_empty
          expect(subject.attachments).to eq(markdown_message)
          expect(subject.activity).to eq(activity)
        end
      end

      context 'when the fancy_pipeline_slack_notifications feature flag is enabled' do
        let(:status_text) do
          case status
          when "success"
            detailed_status == "passed with warnings" ? "has passed with warnings" : "has passed"
          else
            "has failed"
          end
        end
        let(:color) do
          case status
          when "success"
            detailed_status == "passed with warnings" ? "warning" : "good"
          else
            "danger"
          end
        end

        it 'returns the correct pretext, attachments, and activity' do
          stub_feature_flags(fancy_pipeline_slack_notifications: true)

          expect(subject.pretext).to be_empty
          expect(subject.attachments).to eq(markdown_message)
          expect(subject.activity).to eq(activity)
        end
      end
    end

    context 'pipeline succeeded' do
      let(:status) { 'success' }

      it_behaves_like 'a correct response'
    end

    context 'pipeline failed' do
      let(:status) { 'failed' }

      it_behaves_like 'a correct response'

      context 'when triggered by API therefore lacking user' do
        let(:user) { nil }

        it_behaves_like 'a correct response'
      end
    end
  end
end
