namespace :collectives do
  desc 'sync collectives'
  task sync: :environment do
    Collective.sync_least_recently_synced
  end

  desc 'sync osc collectives'
  task sync_osc: :environment do
    Collective.sync_least_recently_synced_osc
  end

  desc 'discover collectives'
  task :discover => :environment do
    Collective.discover
  end

  desc 'sync funders'
  task sync_funders: :environment do
    Collective.sync_funders
  end

  desc 'fetch commit stats for user-owner collectives'
  task fetch_user_owner_commit_stats: :environment do
    scope = Project.where(collective_id: Collective.opensource.with_user_owner.select(:id))
                   .source
                   .where(commit_stats: nil)
    total = scope.count
    puts "Fetching commit stats for #{total} projects"
    scope.find_each.with_index do |project, i|
      project.fetch_commit_stats
      puts "#{i + 1}/#{total}" if (i + 1) % 100 == 0
    end
  end
end