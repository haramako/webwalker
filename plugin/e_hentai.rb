# -*- coding: utf-8 -*-

class E_Hentai < WebWalker::Plugin
  project_url %r(^http://g\.e-hentai\.org/g/(\d+)/([0-9a-f]+)/)

  class RetryAfterException < Exception; end

  class Walker < WebWalker::WalkerBase
    BASE_URL = URI('http://g.e-hentai.org/')

    walker %r(^http://g\.e-hentai\.org/g/(\d+)/([0-9a-f]+)/(\?p=\d+)?$) do |url,match|
      page = get url

      page.search('a').each do |e|
        href = e.attr('href')
        add_url href if href and href.match %r(^http://g\.e-hentai\.org/s/)
        add_url href if href and href.match %r(^http://g.e-hentai.org/g/.*/\?p=\d+$)
      end

      project_name page.search('h1#gn').text
      expire 60*60*24*365
    end

    walker %r(^http://g\.e-hentai\.org/s/([0-9a-z]+)/(\d+)-(\d+)) do |url,match|
      begin
        page = get url
        _, _, id, page_no = *match
        page_no = page_no.to_i
        page.search('div#i3 img').each do |e|
          image_url = e['src']
          raise RetryAfterException.new if image_url.match /509s\.gif/
          add_image "%04d.jpg" % page_no, get( image_url )
        end
      rescue RetryAfterException
        puts 'sleep 1 hour for 509s.gif'
        sleep 1.hour
        retry
      end
    end

  end
end



# モンキーパッチ
# ruby2.0だと問題が起こるため
require 'mechanize'
class Mechanize::HTTP::Agent
  def response_read response, request, uri
    content_length = response.content_length

    if use_tempfile? content_length then
      body_io = make_tempfile 'mechanize-raw'
    else
      body_io = StringIO.new
    end

    body_io.set_encoding Encoding::BINARY if body_io.respond_to? :set_encoding
    total = 0

    begin
      response.read_body { |part|
        total += part.length

        if StringIO === body_io and use_tempfile? total then
          new_io = make_tempfile 'mechanize-raw'

          new_io.write body_io.string

          body_io = new_io
        end

        body_io.write(part)
        log.debug("Read #{part.length} bytes (#{total} total)") if log
      }
    rescue EOFError => e
      # terminating CRLF might be missing, let the user check the document                                                                                                                                 
      raise unless response.chunked? and total.nonzero?

      body_io.rewind
      raise Mechanize::ChunkedTerminationError.new(e, response, body_io, uri,
                                                   @context)
    rescue Net::HTTP::Persistent::Error => e
      body_io.rewind
      raise Mechanize::ResponseReadError.new(e, response, body_io, uri,
                                             @context)
    end

    body_io.flush
    body_io.rewind

    raise Mechanize::ResponseCodeError.new(response, uri) if
      Net::HTTPUnknownResponse === response

    content_length = response.content_length

    unless Net::HTTP::Head === request or Net::HTTPRedirection === response then
      # begin of monkey patch
      #raise EOFError, "Content-Length (#{content_length}) does not match " \
      #                "response body length (#{body_io.length})" if
      #  content_length and content_length != body_io.length
      # end of monkey patch
    end

    body_io
  end
end
