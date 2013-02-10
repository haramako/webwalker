$LOAD_PATH << File.dirname(__FILE__) + '/lib'

require 'rake'

namespace :db do
  "Migrate database."

  task :init do
  end

  task :migrate do
    # See: http://subtech.g.hatena.ne.jp/cho45/20080204/1202051972
    require 'webwalker'
    ActiveRecord::Migrator.migrate 'db/migrate/', ENV['VERSION'] ? ENV['VERSION'].to_i : nil
  end

end

