require 'sinatra'
require 'fileutils'
require 'mapnik'
require 'rest-client'
require 'open-uri'
require 'cgi'

helpers do
  def make_map(file)
    # open(Rails.root.to_s + "/public/map/#{json["clientID"]}_json.json",'w'){|f| f.write json.to_json}
    # maker = MapMaker.new

    `ruby map_maker.rb #{file}`
  end

  def restart_ogc(room)
    puts "restarting ogc for room #{room}"

    # spawn do
    @@ogc_pid ||= nil

    if @@ogc_pid
      # puts "killing #{@@ogc_pid}"
      # `kill -9 #{@@ogc_pid}`
      Process.kill 2, @@ogc_pid + 1
      Process.kill 2, @@ogc_pid
      # Process.wait @@ogc_pid + 1
      puts "done"
      # Thread.new do
      # sleep(2)

      # @@ogc_pid = fork { exec "cd OGCServer && ./bin/ogcserver-local.py ../rooms/#{room}/#{room}.xml" ; Signal.trap("INT") { puts "stop" } }
    # else
    end
    @@ogc_pid = spawn "cd OGCServer && ./bin/ogcserver-local.py ../rooms/#{room}/#{room}.xml"

    # Process.detach(@@ogc_pid)
    puts @@ogc_pid

    # end
  end

  def room_port(room)
    8000
  end
end


get '/' do
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

