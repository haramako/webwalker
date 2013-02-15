require 'bundler/capistrano'
require 'whenever/capistrano'

role :app, "dorubako.ddo.jp"                          # This may be the same as your `Web` server


set :application, "webwalker"
set :repository,  "git@github.com:haramako/webwalker.git"

set :use_sudo, false

set :deploy_to, "/home/harada/webwalker"
set :shared_children, %w( tmp log tmp/pids )
set :public_children, []

set :whenever_roles, [ :app ]
set :whenever_command, 'bundle exec whenever'


namespace :deploy do

  task :restart, role: :app do
    run "cd #{deploy_to}/current && bundle exec thin -d restart"
    run "cd #{deploy_to}/current && bundle exec ./walk daemon restart"
  end

  task :start, role: :app  do
    run "cd #{deploy_to}/current && bundle exec thin -d start"
    run "cd #{deploy_to}/current && bundle exec ./walk daemon start"
  end

  task :stop, role: :app do
    run "cd #{deploy_to}/current && bundle exec thin -d stop"
    run "cd #{deploy_to}/current && bundle exec ./walk daemon stop"
  end

end

