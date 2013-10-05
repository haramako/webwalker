# -*- coding: utf-8 -*-

class Taikai < WebWalker::Plugin
  project_url %r(^http://www\.taikaisyu\.com/)

  class Walker < WebWalker::WalkerBase

    TAIKAI_URL = 'http://www.taikaisyu.com/'

    # 画像
    walker %r(^http://www\.taikaisyu\.com/.*\.jpg) do |url,match|
      path = url.gsub( /^http:\/\/www\.taikaisyu\.com\//, '' ).gsub(/\//){'_'}
      add_image path, get( url )
      { expire: 60*60*24*365 }
    end

    # インデックス
    walker %r(^http://www\.taikaisyu\.com/) do |url,match|
      page = get url

      page.search('a').each do |e|
        href = URI.join( url, e.attr('href') ).to_s
        next unless href.start_with?( TAIKAI_URL )
        add_url href
        # puts href
      end

      begin
        page.search('img').each do |e|
          src = URI.join( url, e.attr('src') ).to_s
          next unless /\/\d+\.jpg$/ === src 
          add_url src
        end
      rescue URI::InvalidURIError
        raise WebWalker::CannotWalk.new( "invalid uri in #{url}" )
      end

      { expire: 60*60*24*365 }
    end

  end

end
