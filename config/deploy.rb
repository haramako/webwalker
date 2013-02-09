set :application, "webwalker"
set :repository,  "git@github.com:haramako/webwalker.git"

require 'bundler/capistrano'

# role :web, "localhost"                          # Your HTTP server, Apache/etc
role :app, "dorubako.ddo.jp"                          # This may be the same as your `Web` server
set :use_sudo, false

# role :db,  "your primary db-server here", :primary => true # This is where Rails migrations will run
# role :db,  "your slave db-server here"

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

set :deploy_to, "/home/harada/webwalker"

default_environment['PATH'] = '/var/lib/gems/1.9.1/bin:${PATH}'

namespace :deploy do
  task :restart do
    run "cd #{deploy_to}/current && bundle exec thin -d restart"
    run "cd #{deploy_to}/current && bundle exec ruby1.9.1 walk daemon restart"
  end
  task :start do
    run "cd #{deploy_to}/current && bundle exec thin -d start"
    run "cd #{deploy_to}/current && bundle exec ruby1.9.1 walk daemon start"
  end
  task :stop do
    run "cd #{deploy_to}/current && bundle exec thin -d stop"
  end
end
