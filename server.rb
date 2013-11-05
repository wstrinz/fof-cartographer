require 'sinatra'
require 'fileutils'
require 'mapnik'
require 'rest-client'
require 'open-uri'
require 'childprocess'
require 'cgi'

helpers do
  def make_map(file)
    `ruby map_maker.rb #{file}`
  end

  def restart_ogc(room)
    ChildProcess.posix_spawn = true
    puts "restarting ogc for room #{room}"

    @@ogc_pid ||= nil

    if @@ogc_pid
      @@ogc_pid.stop
      puts "done"
    end
    @@ogc_pid = ChildProcess.build("./bin/ogcserver-local.py", "../rooms/#{room}/#{room}.xml")
    @@ogc_pid.cwd = "OGCServer"
    @@ogc_pid.start
  end

  def room_port(room)
    8000
  end
end


get '/show/:room' do
  send_file 'views/geo-ext.html'
end

get '/map/:room' do
  @@ogc_pid ||= nil
  restart_ogc(params[:room]) unless @@ogc_pid
  newp = '?' + request.env['rack.request.query_hash'].map{|k,v| "#{k}=#{v}"}.join("&")
  port = room_port(params[:room])
  puts "localhost:8000/#{newp}"
  content_type "image/png"
  open("http://localhost:#{port}/#{newp}").read
end

post '/map/:room' do
  data = params[:data]

  unless data
    raise "Nothing sent"
  else
    roomDir = File.dirname(__FILE__) + '/rooms/' + params[:room]

    unless File.exist?(roomDir)
      FileUtils.mkdir roomDir
    end

    open("#{roomDir}/#{params[:room]}_json.json",'w'){|f| f.write data }
    make_map("#{roomDir}/#{params[:room]}_json.json")
    restart_ogc("#{params[:room]}")
    "good"
  end
end

