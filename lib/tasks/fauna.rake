
task :environment

namespace :fauna do
  desc "Migrate your fauna database to the latest version"
  task :migrate => :environment do
    Fauna::Client.context(Fauna.connection) do
      Fauna.migrate_schema!
    end
  end
end
