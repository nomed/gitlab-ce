# frozen_string_literal: true

class AwardEmojisFinder
  attr_reader :user, :params

  delegate :awardable, :name, to: :params

  def initialize(user, params = {})
    @user = user
    @params = OpenStruct.new(params)
  end

  def execute
    awards = user.award_emoji
    awards = by_name(awards)
    awards = by_awardable(awards)
    awards
  end

  private

  def by_name(awards)
    return awards unless name

    awards.where(name: name) # rubocop: disable CodeReuse/ActiveRecord
  end

  def by_awardable(awards)
    return awards unless awardable

    awards.where(awardable_type: awardable.class.base_class.name, awardable_id: awardable.id) # rubocop: disable CodeReuse/ActiveRecord
  end
end
