require 'spec_helper'

describe 'Toggling an AwardEmoji' do
  include GraphqlHelpers

  let(:current_user) { create(:user) }
  let(:project) { awardable.project }
  let(:emoji_name) { 'thumbsup' }
  let(:mutation) do
    variables = {
      awardable_id: GitlabSchema.id_from_object(awardable).to_s,
      name: emoji_name
    }

    graphql_mutation(:toggle_award_emoji, variables)
  end

  def mutation_response
    graphql_mutation_response(:toggle_award_emoji)
  end

  shared_examples 'a mutation that does not create or destroy an AwardEmoji' do
    it do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.not_to change { AwardEmoji.count }
    end
  end

  context 'when the given awardable is not an Awardable' do
    let(:awardable) { create(:event) }

    it_behaves_like 'a mutation that does not create or destroy an AwardEmoji'

    it_behaves_like 'a mutation that returns the error',
                    error: 'The resource of awardable_id can not be awarded emojis'
  end

  context 'when the given awardable is an Awardable but still cannot be awarded an emoji' do
    let(:awardable) { create(:system_note) }

    it_behaves_like 'a mutation that does not create or destroy an AwardEmoji'

    it_behaves_like 'a mutation that returns the error', error: 'The resource is not emoji awardable'
  end

  context 'when the given awardable is an Awardable' do
    let(:awardable) { create(:note) }

    context 'when the user has permission' do
      before do
        project.add_developer(current_user)
      end

      def create_award_emoji(user)
        create(:award_emoji, name: emoji_name, awardable: awardable, user: user )
      end

      context 'when no emoji has been awarded by the current_user yet' do
        # Create an award emoji for another user. This therefore tests that
        # toggling is correctly scoped to the user's emoji only.
        let!(:award_emoji) { create_award_emoji(create(:user)) }

        it 'creates an emoji' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
          end.to change { AwardEmoji.count }.by(1)
        end

        it 'returns the emoji' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(mutation_response['awardEmoji']['name']).to eq(emoji_name)
        end

        it 'returns toggledOn as true' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(mutation_response['toggledOn']).to eq(true)
        end

        context 'when there were active record validation errors' do
          before do
            expect_next_instance_of(AwardEmoji) do |award|
              expect(award).to receive(:valid?).at_least(:once).and_return(false)
              expect(award).to receive_message_chain(:errors, :full_messages).and_return(['Error 1', 'Error 2'])
            end
          end

          it_behaves_like 'a mutation that does not create or destroy an AwardEmoji'

          it_behaves_like 'a mutation that returns the error', error: 'Error 1 and Error 2'
        end
      end

      context 'when an emoji has been awarded by the current_user' do
        let!(:award_emoji) { create_award_emoji(current_user) }

        it 'removes the emoji' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
          end.to change { AwardEmoji.count }.by(-1)
        end

        it 'returns no errors' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(graphql_errors).to be_nil
        end

        it 'returns an empty awardEmoji' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(mutation_response).to have_key('awardEmoji')
          expect(mutation_response['awardEmoji']).to be_nil
        end

        it 'returns toggledOn as false' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(mutation_response['toggledOn']).to eq(false)
        end
      end
    end

    context 'when the user does not have permission' do
      it_behaves_like 'a mutation that does not create or destroy an AwardEmoji'

      it_behaves_like 'a mutation that returns the error',
                      error: 'The resource that you are attempting to access does not exist or you don\'t have permission to perform this action'
    end
  end
end
