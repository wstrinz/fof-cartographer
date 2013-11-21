require 'fileutils'
require 'rest-client'
require 'childprocess'


class MapProcess
  attr :room
  attr :port

  def initialize(room, port=8000)
    @port = port
    @room = room
    @process = ChildProcess.build("./bin/ogcserver-local.py", "../rooms/#{room}/#{room}.xml", port.to_s)
    @process.cwd = "OGCServer"
  end

  def start
    puts "starting map process for #{@room} on port #{@port}"
    @process.start
  end

  def stop
    puts "stopping"
    @process.stop
  end

  def restart
    if @process.alive?
      stop()
    end

    start()
  end
end