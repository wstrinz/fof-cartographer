require 'sinatra'
require 'fileutils'
require 'mapnik'
require 'rest-client'

helpers do
  def make_map(file)
    # open(Rails.root.to_s + "/public/map/#{json["clientID"]}_json.json",'w'){|f| f.write json.to_json}
    # maker = MapMaker.new

    `ruby map_maker.rb #{file}`
  end

  def restart_ogc(room)
    puts "restarting ogc for room #{room}"
  end
end

get '/map/:room' do
  data = <<-EOF
{
  "event": "fieldDump",
  "clientID": "a",
  "fields": [{
    "farm": "a",
    "pesticide": false,
    "SOM": 101.5501495391146,
    "yield": 9.977123534579679,
    "GBI": 0.9972951823405465,
    "year": 6,
    "fertilizer": false,
    "till": false,
    "crop": "GRASS",
    "y": 1,
    "x": 1
  }, {
    "farm": "a",
    "pesticide": false,
    "SOM": 52.62828919547201,
    "yield": 0.0,
    "GBI": 0.9972951823405465,
    "year": 6,
    "fertilizer": false,
    "till": false,
    "crop": "GRASS",
    "y": 1,
    "x": 2
  }]
}
  EOF
  # puts request.host_with_port
  puts "http://#{request.host_with_port}/map/#{params[:room]}"
  # RestClient.post("http://#{request.host_with_port}/map/#{params[:room]}", data: data )
  RestClient.post("http://localhost:4567/map/a", data: data )
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

