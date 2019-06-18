require './spec/support/sidekiq'

Gitlab::Seeder.quiet do
  emoji = Gitlab::Emoji.emojis.keys

  Issue.order(Gitlab::Database.random).limit(Issue.count / 2).each do |issue|
    project = issue.project

    project.team.users.sample(2).each do |user|
      AwardEmojis::AddService.new(issue, emoji.sample, user).execute

      issue.notes.sample(2).each do |note|
        next if note.system?
        AwardEmojis::AddService.new(note, emoji.sample, user).execute
      end

      print '.'
    end
  end

  MergeRequest.order(Gitlab::Database.random).limit(MergeRequest.count / 2).each do |mr|
    project = mr.project

    project.team.users.sample(2).each do |user|
      AwardEmojis::AddService.new(mr, emoji.sample, user).execute

      mr.notes.sample(2).each do |note|
        next if note.system?
        AwardEmojis::AddService.new(note, emoji.sample, user).execute
      end

      print '.'
    end
  end
end
