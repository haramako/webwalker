# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

set :output, "/var/walker/cron.log"

every 1.minutes do
  command "cd #{path} && bundle exec ruby walk cron"
end
