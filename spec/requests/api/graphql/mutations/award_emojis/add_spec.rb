require 'spec_helper'

describe 'Adding an AwardEmoji' do
  include GraphqlHelpers

  let(:current_user) { create(:user) }
  let(:project) { awardable.project }
  let(:emoji_name) { 'thumbsup' }
  let(:mutation) do
    variables = {
      awardable_id: GitlabSchema.id_from_object(awardable).to_s,
      name: emoji_name
    }

    graphql_mutation(:add_award_emoji, variables)
  end

  def mutation_response
    graphql_mutation_response(:add_award_emoji)
  end

  shared_examples 'a mutation that does not create an AwardEmoji' do
    it do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.not_to change { AwardEmoji.count }
    end
  end

  context 'when the given awardable is not an Awardable' do
    let(:awardable) { create(:event) }

    it_behaves_like 'a mutation that does not create an AwardEmoji'

    it_behaves_like 'a mutation that returns the error',
                    error: 'The resource of awardable_id can not be awarded emojis'
  end

  context 'when the given awardable is an Awardable but still cannot be awarded an emoji' do
    let(:awardable) { create(:system_note) }

    it_behaves_like 'a mutation that does not create an AwardEmoji'

    it_behaves_like 'a mutation that returns the error', error: 'The resource is not emoji awardable'
  end

  context 'when the given awardable is an Awardable' do
    let(:awardable) { create(:note) }

    context 'when the user has permission' do
      before do
        project.add_developer(current_user)
      end

      it 'creates an emoji' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change { AwardEmoji.count }.by(1)
      end

      it 'returns the emoji' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['awardEmoji']['name']).to eq(emoji_name)
      end

      context 'when there were active record validation errors' do
        before do
          expect_next_instance_of(AwardEmoji) do |award|
            expect(award).to receive(:valid?).at_least(:once).and_return(false)
            expect(award).to receive_message_chain(:errors, :full_messages).and_return(['Error 1', 'Error 2'])
          end
        end

        it_behaves_like 'a mutation that does not create an AwardEmoji'

        it_behaves_like 'a mutation that returns the error', error: 'Error 1 and Error 2'
      end
    end

    context 'when the user does not have permission' do
      it_behaves_like 'a mutation that does not create an AwardEmoji'

      it_behaves_like 'a mutation that returns the error',
                      error: 'The resource that you are attempting to access does not exist or you don\'t have permission to perform this action'
    end
  end
end
