# frozen_string_literal: true

require "net/http"
require "json"
require "time"
require "gtk3"
require "gst"

class EventWatcher
  API_URL = "https://api.example.com/cow_events" # Replace with the actual API URL
  VIDEO_PATH = "./videos" # Directory where video files are stored
  CHECK_INTERVAL = 10 # seconds

  def initialize(events)
    @events = parse_event_data(events)
    @last_checked = Time.now - CHECK_INTERVAL - 1
    Gst.init
    @pipeline = Gst::Pipeline.new("video_pipeline")
  end

  def parse_event_data(event_data)
    event_data.each { |event| event[:timestamp] = Time.parse(event[:timestamp]) }
      .sort_by { |event| event[:timestamp] }
  end

  def fetch_event
    @events.shift
  end

  def play_video(filename)
    filepath = File.join(VIDEO_PATH, filename)
    unless File.exist?(filepath)
      puts "Video file #{filename} not found."
      return
    end

    @pipeline.set_state(:null)
    @pipeline.children.each { |child| @pipeline.remove(child) }

    source = Gst::ElementFactory.make("filesrc", "source")
    source.location = filepath
    decode = Gst::ElementFactory.make("decodebin", "decode")
    sink = Gst::ElementFactory.make("autovideosink", "sink")

    @pipeline.add(source, decode, sink)
    source.link(decode)
    decode.signal_connect("pad-added") do |_, pad|
      pad.link(sink.get_static_pad("sink"))
    end

    @pipeline.set_state(:playing)
  end

  def handle_event_playback(current_event)
    video_filename = "#{current_event[:cow_name]}_#{current_event[:event]}.mp4"
    puts "Playing video: #{video_filename}"
    play_video(video_filename)
  end

  def start_watching
    loop do
      if Time.now - @last_checked >= CHECK_INTERVAL
        current_event = fetch_event
        @pipeline.set_state(:null)
        handle_event_playback(current_event) if current_event
        @last_checked = Time.now
      end
      sleep(CHECK_INTERVAL + 1)
    end
  end
end

# Sample Events
EVENTS = [
  {event: "milking", cow_id: 1, cow_name: "cow1", timestamp: "2024-06-08 12:22:18"},
  {event: "rumination", cow_id: 2, cow_name: "cow2", timestamp: "2024-06-08 12:22:28"},
  {event: "grazing", cow_id: 3, cow_name: "cow3", timestamp: "2024-06-08 12:22:38"},
  {event: "milking", cow_id: 2, cow_name: "cow2", timestamp: "2024-06-08 12:22:48"},
  {event: "grazing", cow_id: 1, cow_name: "cow2", timestamp: "2024-06-08 12:22:58"},
  {event: "rumination", cow_id: 3, cow_name: "cow3", timestamp: "2024-06-08 12:23:08"}
].freeze

if __FILE__ == $0
  watcher = EventWatcher.new(EVENTS)
  watcher.start_watching
end
