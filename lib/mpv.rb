require "socket"
require_relative "colored_logger"

class MPV
  MPV_SOCKET = "/tmp/mpvsocket"
  VIDEO_PATH = "./videos" # Directory where video files are stored

  def initialize
    @socket = UNIXSocket.new(MPV_SOCKET) # Store the socket connection
    @logger = ColoredLogger.new($stdout)
    @logger.level = Logger::DEBUG
  end

  # play video file of the current event
  def play_video(filename)
    file = filepath(filename)
    # cow_id = filename.split("_").first

    unless File.exist?(file)
      puts "Video file #{filename} not found."
      return
    end

    @logger.info "Playing video: #{filename}"

    # @todo wip
    # separate logic for milking videos
    if file.include? "milking"
      send_command(["set_property", "loop", "no"])
      send_command(["set_property", "loop-playlist", "inf"])
      # return handle_milking_playback(cow_id)
    else
      send_command(["set_property", "loop", "yes"])
    end

    send_command(["loadfile", file])
  end

  # close mpv socket
  def close_socket
    @socket&.close
  end

  private

  def handle_milking_playback(cow_id)
    send_command(["set_property", "loop", "no"])
    enqueue(["#{cow_id}_milking_intro.mp4", "#{cow_id}_milking.mp4"])

    # Listen for end of file events
    listen_for_events do |ev|
      if ev["event"] == "end-file"
        @logger.info ev

        send_command(["playlist-next"])

        # Wait for a short duration to ensure the file has started
        sleep(0.5)

        # @todo get the duration of the next file
        # seek based on amount of time the milking event needs to be played considering event_duration
        # send_command(["seek", 2 * 60, "absolute"])

        enqueue(["#{cow_id}_milking_outro.mp4"])

        # Exit the loop after handling the seek
        break
      end
    end

    # send_command(["loadfile", "#{cow}_milking_outro.mp4"])
    # send_command(["set_property", "loop", "yes"])
  end

  def enqueue(files)
    files.each do |file|
      send_command(["loadfile", filepath(file), "append"])
    end
  end

  def listen_for_events
    send_command(["observe_property", 1, "playlist-count"])

    while (response = @socket.gets)
      event = JSON.parse(response)
      yield(event) if block_given?
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
