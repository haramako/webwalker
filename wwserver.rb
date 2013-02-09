#!/usr/bin/env ruby
# -*- coding:utf-8 -*-

Encoding.default_external = 'UTF-8'
Encoding.default_internal = 'UTF-8'


require 'pathname'
$LOAD_PATH << File.dirname(__FILE__)+ '/lib'

require 'sinatra'
require 'webwalker'
# require 'rack/csrf' TODO: CSRF対策をいれること

class MyApp < Sinatra::Base

  # Basic認証
  use Rack::Auth::Basic, 'Baisc Auth' do |user,pass|
    user == 'makoto' and pass == 'mako0522'
  end

  before do 
    content_type 'text/html', 'charset' => 'utf-8'
  end

  get '/' do
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
    project = WebWalker::Project.new( url: url, name: url)
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
    f = open(zip,'rb')
    f
    # redirect '/project'
  end

  get '/url' do
    @urls = WebWalker::Url.where( status: '' ).limit(100).find(:all)
    erb :url_list
  end

  get '/url/delete/:id' do
    WebWalker::Url.find(params[:id].to_i).destroy
    erb :url_list
  end

end
