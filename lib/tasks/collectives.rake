namespace :collectives do
  desc 'sync collectives'
  task sync: :environment do
    Collective.sync_least_recently_synced
  end

  desc 'discover collectives'
  task :discover => :environment do
    Collective.discover
  end
end