require 'bundler/capistrano'
require 'whenever/capistrano'

set :application, "webwalker"
set :repository,  "git@github.com:haramako/webwalker.git"

# role :web, "localhost"                          # Your HTTP server, Apache/etc
role :app, "dorubako.ddo.jp"                          # This may be the same as your `Web` server
set :use_sudo, false

set :deploy_to, "/home/harada/webwalker"

set :whenever_roles, [ :app ]

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
    run "cd #{deploy_to}/current && bundle exec ruby1.9.1 walk daemon stop"
  end

end

