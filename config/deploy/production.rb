role :app, "webwalker"

set :scm, :none
set :repository,  "."
set :deploy_via, :copy

set :rails_env, 'production'
