set :application, "webwalker"
set :repository,  "git@github.com:haramako/webwalker.git"

require 'bundler/capistrano'

role :web, "localhost"                          # Your HTTP server, Apache/etc
role :app, "localhost"                          # This may be the same as your `Web` server
set :use_sudo, false

# role :db,  "your primary db-server here", :primary => true # This is where Rails migrations will run
# role :db,  "your slave db-server here"

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

set :deploy_to, "/tmp/hoge"

namespace :deploy do
  task :restart do
  end
  task :start do
  end
  task :stop do
  end
end
