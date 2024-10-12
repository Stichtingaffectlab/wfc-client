require "socket"
require "json"
require "./lib/colored_logger"
require "./lib/timeline"

# An event watcher class to "Wait for the cows"
#
class EventWatcher
  VIDEO_PATH = "./videos" # Directory where video files are stored
  CHECK_INTERVAL = 4 # seconds
  MPV_SOCKET = "/tmp/mpvsocket"

  def initialize
    @tl = Timeline.new
    @last_checked = Time.now - CHECK_INTERVAL - 1
    @mpv_socket = UNIXSocket.new(MPV_SOCKET) # Store the socket connection

    @logger = ColoredLogger.new($stdout)
    @logger.level = Logger::DEBUG

    # @led = LedController.new
  end

  # handle polling and watching for events (main logic)
  def start_watching
    loop do
      if Time.now - @last_checked >= CHECK_INTERVAL
        ev = fetch_event
        log ev if @current_event != ev
        if @current_event != ev && ev
          @current_event = ev
          if @current_event && (@current_event[:event])
            handle_event_playback(@current_event)
          elsif !(@current_event[:event]) # to cater for change in event location
            handle_event_playback(@previous_event)
          end
        end
        @last_checked = Time.now if ev
      end
      sleep(CHECK_INTERVAL + 1)
    end
  ensure
    close_socket
  end

  private

  # play video file of the current event
  def play_video(filename)
    filepath = File.join(VIDEO_PATH, filename)
    unless File.exist?(filepath)
      puts "Video file #{filename} not found."
      return
    end

    log "Playing video: #{filename}"

    # loop playlist for milking videos
    if filepath.include? "milking"
      send_command({"command" => ["set_property", "loop", "no"]})
      send_command({"command" => ["set_property", "loop-playlist", "inf"]})
    else
      send_command({"command" => ["set_property", "loop", "yes"]})
    end

    # Send command to play video
    send_command({"command" => ["loadfile", filepath]})
  end

  # handle video playback before video is played
  def handle_event_playback(ev)
    cow = cow_id(ev)
    event = event_name(ev)

    filename = if event == "milking"
      "#{cow}_milking.m3u" # for milking event we use a playlist to include intro and outro
    else
      "#{cow}_#{event}_#{@tl.event_location}.mp4"
    end
    @previous_event = ev

    play_video(filename)

    # control led strips
    # first turn all of and then turn on one for the current cow
    # @led.turn_all_off
    # @led.send(:"cow_#{cow}")
    # Thread.new do
    #   sleep 60 * 3 # wait for 3 minutes and turn off the led strips
    #   @led.turn_all_off
    # end
  end

  # get id of the cow
  def cow_id(ev)
    cow = ev[:cow]
    cow = @previous_event[:cow] if !cow

    # cow[:name] is usually in this format "435 Robina", starting with the cow id
    cow[:name].split(" ").first
  end

  # get current event name
  # we don't have videos for resting and grazing, instead for these we simply show alternatives
  def event_name(ev)
    case ev[:event]
    when "grazing"
      "eating"
    when "resting"
      "ruminations"
    else
      ev[:event]
    end
  end

  # fetch current event from the timeline
  def fetch_event
    @tl.get_current
  end

  # send command to mpv player
  def send_command(command)
    @mpv_socket.write(command.to_json + "\n")
  rescue Errno::EPIPE # Handle broken pipe error
    # Reconnect the socket if the connection is closed
    @mpv_socket = UNIXSocket.new(MPV_SOCKET)
    retry
  end

  # close mpv socket
  def close_socket
    @mpv_socket&.close
  end

  # log to console
  def log(*args)
    @logger.info args.join(", ")
  end
end

if __FILE__ == $0
  watcher = EventWatcher.new
  watcher.start_watching
end
