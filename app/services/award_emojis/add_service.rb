# frozen_string_literal: true

module AwardEmojis
  class AddService < AwardEmojis::BaseService
    include Gitlab::Utils::StrongMemoize

    def execute
      return error('User cannot award emoji to awardable', :forbidden) unless awardable.user_can_award?(current_user)
      return error('Awardable cannot be awarded emoji', :unprocessable_entity) unless awardable.emoji_awardable?

      award = awardable.award_emoji.create(name: name, user: current_user)

      if award.persisted?
        TodoService.new.new_award_emoji(todoable, current_user) if todoable
        success(award: award)
      else
        error(award.errors.full_messages.to_sentence)
      end
    end

    private

    def todoable
      strong_memoize(:todoable) do
        case awardable
        when Note
          # We don't create todos for personal snippet comments for now
          awardable.for_personal_snippet? ? nil : awardable.noteable
        when MergeRequest, Issue
          awardable
        when Snippet
          nil
        end
      end
    end
  end
end
