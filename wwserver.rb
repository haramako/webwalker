#!/usr/bin/env ruby
# -*- coding:utf-8 -*-

$LOAD_PATH << File.dirname(__FILE__) + '/lib'

require 'sinatra/base'
require 'webwalker'
require 'rack/flash'
require 'fluent-logger'

# require 'rack/csrf' TODO: CSRF対策をいれること


class MyApp < Sinatra::Base

  configure do
    # WebWalker.logger = Fluent::Logger::FluentLogger.open(nil, host:'localhost' )
    @@logger = WebWalker.logger = Fluent::Logger::ConsoleLogger.new(STDERR)
  end

  # 開発時は、リローダを使う
  configure :development do
    require 'sinatra/reloader'
    register Sinatra::Reloader

    # connection pool があふれる問題の対策
    # See: http://stackoverflow.com/questions/13675879/activerecordconnectiontimeouterror
    # See: http://stackoverflow.com/questions/10191531/activerecord-connection-warning-database-connections-will-not-be-closed-automa
    use ActiveRecord::ConnectionAdapters::ConnectionManagement
    after do
      ActiveRecord::Base.connection.close
    end

  end

  # セッションとフラッシュの設定
  use Rack::Session::Cookie, :secret => '0b3b395b8706d7585ac8dd92cd44cd71'
  use Rack::Flash, :accessorize => [:info, :error, :success], :sweep => true
  def flash
    env['x-rack.flash']
  end

  # Basic認証
  use Rack::Auth::Basic, 'Baisc Auth' do |user,pass|
    user == 'makoto' and pass == 'mako0522'
  end

  def logger
    @@logger
  end

  before do 
    # content_type 'text/html', 'charset' => 'utf-8'
  end

  #=============== ルーティング ================

  get '/' do
    @title = 'トップ'
    erb :index
  end

  get '/project' do
    @projects = WebWalker::Project.order( 'id desc' ).find(:all)
    @title = 'プロジェクト一覧'
    erb :project_list
  end

  get '/project/:id' do
    @proj = WebWalker::Project.find( params[:id].to_i )
    @title = @proj.name
    erb :project_view
  end

  post '/project/create' do
    url = params[:url]
    halt if url == ''
    plugins = WebWalker::Plugin.match_project( url )
    raise "no match found" if plugins.size <= 0
    raise "need match to *just* one" if plugins.size > 1
    project = WebWalker::Project.new( :url => url, :plugin => plugins[0].to_s )
    project.save!
    url = WebWalker::Url.new( :url =>url, :project_id => project.id, :expire_at => Time.now )
    url.save!
    flash.success = "'#{project.display_name}'を作成しました"
    redirect '/project'
  end

  get '/project/delete/:id' do
    id = params[:id].to_i
    project = WebWalker::Project.find(id)
    project.destroy
    flash.success = "'#{project.display_name}'を削除しました"
    redirect '/project'
  end

  get '/project/zip/:id' do
    id = params[:id].to_i
    @proj = WebWalker::Project.find(id)
    zip = @proj.zip
    content_type 'application/zip'
    # UTF-8でダウンロードするファイル名を指定している 
    # See: http://stackoverflow.com/questions/1361604/how-to-encode-utf8-filename-for-http-headers-python-django
    headers 'Content-Disposition' => "attachment; filename=\"#{@proj.id}.zip\"; filename*=UTF-8''#{URI.encode(@proj.name,/[^#{URI::PATTERN::ALNUM}]/)}.zip"
    f = open(zip,'rb')
    f
  end

  get '/url' do
    @urls = WebWalker::Url.where( :status => '' ).order(:expire_at).limit(100).find(:all)
    @title = 'URL一覧'
    erb :url_list
  end

  get '/url/delete/:id' do
    url = WebWalker::Url.find(params[:id].to_i)
    url.destroy
    flash.success = "#{url.url}を削除しました"
    redirect '/url'
  end

end
