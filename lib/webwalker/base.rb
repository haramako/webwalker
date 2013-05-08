# -*- coding: utf-8 -*-

require 'active_record'
require 'mechanize'
require 'fileutils'
require 'uri'
require 'pathname'
require 'pp'
require 'pluginfactory'

ActiveRecord::Base.establish_connection( :adapter => 'mysql2',
                                         :database => 'walker',
                                         :charset => 'utf8',
                                         :encoding => 'utf8' )
# ActiveRecord::Base.logger = Logger.new( STDOUT )

IMG_DIR = Pathname('/var/walker/img/')
ZIP_DIR = Pathname('/var/walker/zip/')

module WebWalker
  
  def self.logger
    unless defined? @@logger
      @@logger = Logger.new(File::NULL)
      @@logger.level = Logger::DEBUG
    end
    @@logger
  end

  def self.logger=(val)
    @@logger = val
  end

  #################################################
  # プラグイン
  #################################################
  class Plugin
    include PluginFactory

    def self.plugin_list
      unless defined?(@@plugin_list)
        @@plugin_list = {}
        derivative_dirs.each do |dir|
          Dir.glob( dir+'/*.rb' ) do |rbfile|
            module_name = File.basename( rbfile )[0..-4]
            @@plugin_list[module_name.to_sym] = get_subclass( module_name )
          end
        end
      end
      @@plugin_list
    end

    def self.match_project( url )
      r = []
      pp [1,plugin_list]
      plugin_list.each do |name,plugin|
        pp plugin.get_project_url
        if plugin.get_project_url.match(url)
          r << name
        end
      end
      r
    end

    def self.derivative_dirs
      ['./plugin']
    end

    def self.project_url( regexp )
      class_variable_set :@@project_url, regexp
    end

    def self.get_project_url
      self.class_variable_get :@@project_url
    end
  end

  #################################################
  # プロジェクトモデル
  #################################################
  class Project < ActiveRecord::Base
    has_many :children, :class_name => :Url, :dependent => :destroy

    after_initialize do
      if new_record?
        self.name ||= ''
      end
    end

    before_destroy do
      FileUtils.rm_rf path
      FileUtils.rm_f zippath
    end

    def display_name
      if name == '' then '(未設定)' else name end
    end
    
    def path
      r = IMG_DIR + "%06d"%[id]
      FileUtils.mkdir_p r
      r
    end

    def zip
      unless zipped?
        FileUtils.mkdir_p ZIP_DIR
        imgpath = path
        system "cd #{imgpath}; zip -r #{zippath} *"
        self.zipped_at = Time.now
        save!
      end
      zippath
    end

    def zippath
      ZIP_DIR + "%06d.zip"%[id]
    end

    def zipped?
      zipped_at and zipped_at >= updated_at
    end

  end

  #################################################
  # URLモデル
  #################################################
  class Url < ActiveRecord::Base
    belongs_to :project
  end


  #################################################
  # 
  #################################################
  module Handler
    module_function

    def self.walk( plugin_name, url )
      WebWalker.logger.post 'walk', :url => url
      plugin = Plugin.get_subclass( plugin_name )
      w = plugin::Walker.new( url )
      w.walk url
      w
    end

    def self.walk_around
      while true
        url = Url.limit(1).find( :all, :conditions => { :status => ''}, :order => :expire_at )
        break if url.size <= 0
        walk_one url[0]
      end
    end

    def self.walk_one( url )
      url = WebWalker::Url.find(url) unless url.is_a?(Url)
      project = url.project

      x = walk project.plugin, url.url

      # 帰ってきた値に応じて動作する
      x.result[:url].each do |new_url|
        next if Url.find( :all, :conditions => { :project_id => project.id, :url => new_url } ).size > 0
        Url.new( :project => project, :url => new_url, :created_at => Time.now, :expire_at => Time.now ).save!
      end
      x.result[:image].each do |path,img|
        File.open( project.path + path, 'wb' ){|f| f.write img.body }
      end

      if x.result[:project_name] and project.name == ''
        project.name = x.result[:project_name]
      end
      project.updated_at = Time.now
      project.save!

      url.status = 'P'
      url.save!
    rescue Mechanize::ResponseCodeError, Errno::ETIMEDOUT, Timeout::Error, Errno::ECONNRESET, Net::HTTP::Persistent::Error, Errno::EHOSTUNREACH
      url.status = 'F'
      url.save!
      pp $!
    rescue
      raise
    end

    # 定期処理
    def self.cron
      sql = <<EOT
UPDATE projects AS p
JOIN (
  SELECT project_id,
    COUNT(*) AS url_all,
    SUM( CASE WHEN status='P' THEN 1 ELSE 0 END) AS url_finished,
    SUM( CASE WHEN status='F' THEN 1 ELSE 0 END) AS url_failed
  FROM urls GROUP BY project_id
) AS c ON p.id = c.project_id
SET p.url_all = c.url_all,
  p.url_finished = c.url_finished,
  p.url_failed = p.url_failed
EOT
      Project.connection.execute sql
    end

  end

  #################################################
  # 
  #################################################
  class WalkerBase

    attr_reader :url, :result

    def initialize( url )
      @cur_url = url
      @agent = Mechanize.new
      @agent.request_headers['Accept-Language'] = 'ja,en-US'
      @result = { :url => [], :image => {} }
    end

    def log( tag, data )
      WebWalker.logger.post 'ww.'+tag, data
    end

    def walk( url )
      self.class.class_variable_get( :@@walkers ).each do |w|
        if match = w[:regexp].match( url )
          instance_exec( url, match,  &w[:block] )
          return
        end
      end
      raise "not match to #{url}"
    end

    def get( url )
      if @cur_url.to_s.match %r(^http://g\.e-hentai\.org/)
        sleep 1
      end

      log 'debug', :url => url
      page = @agent.get url, [], 'http://www.pixiv.net/'

      case page
      when Mechanize::Image
        page
      else
        html = page.root.to_s
        if html.match(/The ban expires/) # Banが終わるまで待つ
          log 'info.wait', :url => url, :msg =>'wait for e-hentai ban, 1 hour'
          sleep 60*60
          get( url )
        end

        page.root
      end
    end

    def add_url( url )
      @result[:url] << url.to_s
    end

    def expire(val)
      @result[:expire] = val
    end

    def project_name(val)
      @result[:project_name] = val
    end

    def add_image(path,val)
      @result[:image][path] = val
    end

    def self.walker( regexp, &block )
      class_variable_set( :@@walkers, [] ) unless class_variable_defined? :@@walkers
      walkers = class_variable_get :@@walkers
      walkers << { :regexp => regexp, :block => block }
    end

  end

end

# ppなどしたときに、大きくなり過ぎないようにモンキーパッチを当てる
class Mechanize::Image
  def to_s
    filename
  end
end
