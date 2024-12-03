require "socket"
require_relative "colored_logger"

class Player
  MPV_SOCKET = "/tmp/mpvsocket"
  VIDEO_PATH = "./videos" # Directory where video files are stored

  def initialize
    @socket = UNIXSocket.new(MPV_SOCKET) # Store the socket connection
    @logger = ColoredLogger.new($stdout)
    @logger.level = Logger::DEBUG
  end

  # play video file of the current event
  def play_video(filename)
    @previous = @current if @current  # store previously playing video
    @current = filename

    file = filepath(filename)

    unless File.exist?(file)
      puts "Video file #{filename} not found."
      return
    end

    @logger.info "Playing video: #{filename}"

    # separate logic for milking videos
    if file.include? "milking"
      cow_id = filename.split("_").first
      loop_video("no")
      # enqueue milking files and then in the end enqueue the file which was playing before milking
      # so that the playlist doesn't stop playing
      enqueue([
        "#{cow_id}_milking_main.mp4",
        @previous || "#{cow_id}_ruminations_inside.mp4" # if in case milking is the only event, we enqueue this to prevent video from stop playing
      ])
      send_command(["playlist-next"])
      # send_command(["set_property", "loop", "yes"])
    else
      loop_video("yes")
      send_command(["loadfile", file])
    end
  end

  def append(files)
    @logger.info "Playing video: #{files.join(", ")}"
    @previous = files.last
    loop_video("no")
    enqueue(files)
    send_command(["playlist-next"])
  end

  def loop_video(value = "yes")
    send_command(["set_property", "loop", value])
  end

  # close mpv socket
  def close
    @socket&.close
  end

  private

  def enqueue(files)
    files.select { |x| x }.each do |file|
      send_command(["loadfile", filepath(file), "append"])
    end
  end

  # send command to mpv player
  def send_command(command)
    @socket.write({command:}.to_json + "\n")
  rescue Errno::EPIPE # Handle broken pipe error
    # Reconnect the socket if the connection is closed
    @socket = UNIXSocket.new(MPV_SOCKET)
    retry
  end

  def filepath(filename)
    File.join(VIDEO_PATH, filename)
  end
end
