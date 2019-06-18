# frozen_string_literal: true

module AwardEmojis
  class DestroyService < AwardEmojis::BaseService
    def execute
      unless awardable.awarded_emoji?(name, current_user)
        return error("User cannot destroy emoji of type #{name} on the awardable", :forbidden)
      end

      awards = AwardEmojisFinder.new( # rubocop: disable DestroyAll
        current_user,
        name: name,
        awardable: awardable
      ).execute.destroy_all

      errors = collect_errors(awards)

      return error(errors) if errors

      success
    end

    private

    def collect_errors(awards)
      awards.map { |a| a.errors.full_messages }.flatten.to_sentence.presence
    end
  end
end
