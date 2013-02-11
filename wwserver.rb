#!/usr/bin/env ruby
# -*- coding:utf-8 -*-

$LOAD_PATH << File.dirname(__FILE__) + '/lib'

require 'sinatra/base'
require 'webwalker'
# require 'rack/csrf' TODO: CSRF対策をいれること

class MyApp < Sinatra::Base

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

  # Basic認証
  use Rack::Auth::Basic, 'Baisc Auth' do |user,pass|
    user == 'makoto' and pass == 'mako0522'
  end

  before do 
    # content_type 'text/html', 'charset' => 'utf-8'
  end

  get '/' do
    @title = 'トップ'
    erb :index
  end

  get '/project' do
    @projects = WebWalker::Project.find(:all)
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
    project = WebWalker::Project.new( url: url, plugin: plugins[0].to_s )
    project.save!
    WebWalker::Handler.add_url project, url
    redirect '/project'
  end

  get '/project/delete/:id' do
    id = params[:id].to_i
    @proj = WebWalker::Project.find(id)
    @proj.destroy
    redirect '/project'
  end

  get '/project/zip/:id' do
    id = params[:id].to_i
    @proj = WebWalker::Project.find(id)
    zip = @proj.zip
    content_type 'application/zip'
    # UTF-8でファイル名を指定している See: http://stackoverflow.com/questions/1361604/how-to-encode-utf8-filename-for-http-headers-python-django
    headers 'Content-Disposition' => "attachment; filename=\"#{@proj.id}.zip\"; filename*=UTF-8''#{URI.encode(@proj.name)}.zip"
    f = open(zip,'rb')
    f
    # redirect '/project'
  end

  get '/url' do
    @urls = WebWalker::Url.where( status: '' ).limit(100).find(:all)
    @title = 'URL一覧'
    erb :url_list
  end

  get '/url/delete/:id' do
    WebWalker::Url.find(params[:id].to_i).destroy
    erb :url_list
  end

end
