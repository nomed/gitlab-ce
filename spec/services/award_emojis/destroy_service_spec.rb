# frozen_string_literal: true

require 'spec_helper'

describe AwardEmojis::DestroyService do
  let(:user) { create(:user) }
  let(:project) { awardable.project }
  let(:awardable) { create(:note) }
  let(:name) { 'thumbsup' }
  subject(:service) { described_class.new(awardable, name, user) }

  describe '#execute' do
    context 'when user has not awarded an emoji to the awardable' do
      let!(:award) { create(:award_emoji, name: name, awardable: awardable) }

      it 'does not remove the emoji' do
        expect { service.execute }.not_to change { AwardEmoji.count }
      end

      it 'returns an error status' do
        result = service.execute

        expect(result[:status]).to eq(:error)
        expect(result[:http_status]).to eq(:forbidden)
      end
    end

    context 'when user has awarded an emoji to the awardable' do
      let!(:award) { create(:award_emoji, name: name, awardable: awardable, user: user) }

      it 'removes the emoji' do
        expect { service.execute }.to change { AwardEmoji.count }.by(-1)
      end

      it 'returns a success status' do
        result = service.execute

        expect(result[:status]).to eq(:success)
      end
    end
  end
end
