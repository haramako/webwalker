require 'bundler/capistrano'
require 'whenever/capistrano'
require 'capistrano/ext/multistage'
require 'capistrano-rbenv'
set :rbenv_ruby_version, '1.9.3-p448'

set :application, "webwalker"

set :deploy_to, "/opt/webwalker"
set :shared_children, %w( tmp log tmp/pids )
set :public_children, []

set :use_sudo, false

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

  task :migrate, role: :app do
    run "cd #{deploy_to}/current && bundle exec rake db:migrate"
  end

end
