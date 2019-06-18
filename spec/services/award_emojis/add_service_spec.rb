# frozen_string_literal: true

require 'spec_helper'

describe AwardEmojis::AddService do
  using RSpec::Parameterized::TableSyntax

  let(:user) { create(:user) }
  let(:project) { awardable.project }
  let(:awardable) { create(:note) }
  let(:name) { 'thumbsup' }
  subject(:service) { described_class.new(awardable, name, user) }

  describe '#execute' do
    context 'when user is not authorized' do
      it 'does not add an emoji' do
        expect { service.execute }.not_to change { AwardEmoji.count }
      end

      it 'returns an error status' do
        result = service.execute

        expect(result[:status]).to eq(:error)
        expect(result[:http_status]).to eq(:forbidden)
      end
    end

    context 'when user is authorized' do
      before do
        project.add_developer(user)
      end

      it 'creates an award emoji' do
        expect { service.execute }.to change { AwardEmoji.count }.by(1)
      end

      it 'returns the award emoji' do
        result = service.execute

        expect(result[:award]).to be_kind_of(AwardEmoji)
      end

      it 'return a success status' do
        result = service.execute

        expect(result[:status]).to eq(:success)
      end

      it 'sets the correct properties on the award emoji' do
        award = service.execute[:award]

        expect(award.name).to eq(name)
        expect(award.user).to eq(user)
      end

      describe 'marking todos as done' do
        where(:type, :expectation) do
          :issue           | true
          :merge_request   | true
          :project_snippet | false
        end

        with_them do
          let(:awardable) { create(type) }
          let!(:todo) { create(:todo, target: awardable, project: project, user: user) }

          it do
            service.execute

            expect(todo.reload.done?).to eq(expectation)
          end
        end

        # Notes have more complicated rules than other todoables
        describe 'for notes' do
          let(:awardable) { create(:note) }
          let!(:todo) { create(:todo, target: awardable.noteable, project: project, user: user) }

          it 'marks the todo as done' do
            service.execute

            expect(todo.reload.done?).to eq(true)
          end

          it 'does not mark the todo as done when note is for personal snippet' do
            expect(awardable).to receive(:for_personal_snippet?).and_return(true)

            service.execute

            expect(todo.reload.done?).to eq(false)
          end
        end
      end

      context 'when the awardable cannot have emoji awarded to it' do
        before do
          expect(awardable).to receive(:emoji_awardable?).and_return(false)
        end

        it 'does not add an emoji' do
          expect { service.execute }.not_to change { AwardEmoji.count }
        end

        it 'returns an error status' do
          result = service.execute

          expect(result[:status]).to eq(:error)
          expect(result[:http_status]).to eq(:unprocessable_entity)
        end
      end

      context 'when the awardable is invalid' do
        before do
          expect_next_instance_of(AwardEmoji) do |award|
            expect(award).to receive(:valid?).and_return(false)
            expect(award).to receive_message_chain(:errors, :full_messages).and_return(['Error 1', 'Error 2'])
          end
        end

        it 'does not add an emoji' do
          expect { service.execute }.not_to change { AwardEmoji.count }
        end

        it 'returns an error status' do
          result = service.execute

          expect(result[:status]).to eq(:error)
        end

        it 'returns an error message' do
          result = service.execute

          expect(result[:message]).to eq('Error 1 and Error 2')
        end
      end
    end
  end
end
