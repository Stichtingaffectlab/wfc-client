require "socket"
require "json"
require "./lib/timeline"

class EventWatcher
  VIDEO_PATH = "./videos" # Directory where video files are stored
  CHECK_INTERVAL = 4 # seconds
  MPV_SOCKET = "/tmp/mpvsocket"

  def initialize
    @tl = Timeline.new
    @last_checked = Time.now - CHECK_INTERVAL - 1
    # @led = LedController.new
  end

  def fetch_event
    @tl.get_current
  end

  def send_command(command)
    socket = UNIXSocket.new(MPV_SOCKET)
    socket.write(command.to_json + "\n")
    socket.close
  end

  def play_video(filename)
    filepath = File.join(VIDEO_PATH, filename)
    unless File.exist?(filepath)
      puts "Video file #{filename} not found."
      return
    end

    puts "Playing video: #{filename}"

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

  def handle_event_playback(ev)
    video_filename = if get_event(ev) == "milking"
      "#{get_cow(ev)}_milking.m3u" # for milking event we use a playlist to include intro and outro
    else
      "#{get_cow(ev)}_#{get_event(ev)}_#{@tl.event_location}.mp4"
    end
    @previous_event = ev
    play_video(video_filename)

    # control led strips
    # first turn all of and then turn on one for the current cow
    # @led.turn_all_off
    # @led.send(:"cow_#{get_cow(ev)}")
    # Thread.new do
    #   sleep 60 * 3 # wait for 3 minutes and turn off the led strips
    #   @led.turn_all_off
    # end
  end

  def get_cow(ev)
    cow = ev[:cow]
    cow = @previous_event[:cow] if !cow
    cow[:name].split(" ").first
  end

  # we don't have videos for resting and grazing, instead for these we simply show alternatives
  def get_event(ev)
    case ev[:event]
    when "grazing"
      "eating"
    when "resting"
      "ruminations"
    else
      ev[:event]
    end
  end

  def start_watching
    loop do
      if Time.now - @last_checked >= CHECK_INTERVAL
        ev = fetch_event
        puts ev
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
  end
end

if __FILE__ == $0
  watcher = EventWatcher.new
  watcher.start_watching
end
