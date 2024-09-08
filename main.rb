require "socket"
require "json"
require "./timeline"

class EventWatcher
  VIDEO_PATH = "./videos" # Directory where video files are stored
  CHECK_INTERVAL = 4 # seconds
  MPV_SOCKET = "/tmp/mpvsocket"

  def initialize
    @tl = Timeline.new
    @last_checked = Time.now - CHECK_INTERVAL - 1
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

    # Send command to play video
    send_command({"command" => ["loadfile", filepath]})
  end

  def handle_event_playback(ev)
    @previous_event = ev
    video_filename = "#{get_cow(ev)}_#{ev[:event] || ev["event"]}_#{@tl.event_location}.mp4"
    play_video(video_filename)
  end

  def get_cow(ev)
    cow = ev[:cow] || ev["cow"]
    (cow && (cow[:name] || cow["name"])).split(" ").first
  end

  def start_watching
    loop do
      if Time.now - @last_checked >= CHECK_INTERVAL
        ev = fetch_event
        puts ev
        if @current_event != ev
          @current_event = ev
          if @current_event && (@current_event[:event] || @current_event["event"])
            handle_event_playback(@current_event)
          elsif !(@current_event[:event] || @current_event["event"]) # to cater for change in event location
            handle_event_playback(@previous_event)
          end
        end
        @last_checked = Time.now
      end
      sleep(CHECK_INTERVAL + 1)
    end
  end
end

if __FILE__ == $0
  watcher = EventWatcher.new
  watcher.start_watching
end
