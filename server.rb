require 'sinatra'
require 'fileutils'
require 'mapnik'
require 'rest-client'
require 'open-uri'
require 'childprocess'
require 'cgi'

require_relative 'map_process.rb'

configure do
  set :map_processes, {}
end

helpers do
  def make_map(file)
    `ruby map_maker.rb #{file}`
  end

  def restart_ogc(room)
    ChildProcess.posix_spawn = true
    puts "restarting ogc for room #{room}"
    process = settings.map_processes[room] ||= MapProcess.new(room, next_port)
    process.restart()
    puts "process on #{process.port}"
  end

  def next_port
    # return next open port
    8000 + settings.map_processes.size
  end

  def room_port(room)
    pro = settings.map_processes[room]
    if pro
      puts "#{room} at port #{pro.port}"
      pro.port
    else
      raise "no map process for room #{room}"
    end
  end
end


get '/show/:room' do
  restart_ogc(params[:room]) unless settings.map_processes[params[:room]]
  send_file 'views/geo-ext.html'
end

get '/map/:room' do
  # @@ogc_pid ||= nil
  restart_ogc(params[:room]) unless settings.map_processes[params[:room]]
  newp = '?' + request.env['rack.request.query_hash'].map{|k,v| "#{k}=#{v}"}.join("&")
  port = room_port(params[:room])
  # puts "localhost:#{port}/#{newp}"
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

