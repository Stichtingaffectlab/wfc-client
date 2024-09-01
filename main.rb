# frozen_string_literal: true

require "net/http"
require "json"
require "time"
require "gtk3"
require "gst"
require "./timeline"

#
# @todos
# - play video according to event
#   - if no new event, keep playing the same video
# - x include scheduled event in the queue
#   - keep a default for the amount of time scheduled event plays
#   - if no scheduled event for the day, use last one
# - add few more presets for distributing the timeline between two hours
#

class EventWatcher
  VIDEO_PATH = "./videos" # Directory where video files are stored
  CHECK_INTERVAL = 4 # seconds

  def initialize(events)
    @tl = Timeline.new
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
    puts @tl.get_current
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
    video_filename = "#{current_event[:cow]}_#{current_event[:event]}.mp4"
    puts "Playing video: #{video_filename}"
    play_video(video_filename)
  end

  def start_watching
    loop do
      if Time.now - @last_checked >= CHECK_INTERVAL
        ev = fetch_event
        if @current_event != ev
          @current_event = ev
          if @current_event
            @pipeline.set_state(:null)
            handle_event_playback(@current_event)
          end
        end
        @last_checked = Time.now
      end
      sleep(CHECK_INTERVAL + 1)
    end
  end
end

# Sample Events
EVENTS = [
  {event: "milking", cow_id: 1, cow: "cow1", event_location: "inside", timestamp: "2024-06-08 12:22:18"},
  {event: "milking", cow_id: 1, cow: "cow1", event_location: "inside", timestamp: "2024-06-08 12:22:18"},
  {event: "rumination", cow_id: 2, cow: "cow2", event_location: "inside", timestamp: "2024-06-08 12:22:28"},
  {event: "grazing", cow_id: 3, cow: "cow3", event_location: "outside", timestamp: "2024-06-08 12:22:38"},
  {event: "milking", cow_id: 2, cow: "cow2", event_location: "inside", timestamp: "2024-06-08 12:22:48"},
  {event: "grazing", cow_id: 1, cow: "cow2", event_location: "outside", timestamp: "2024-06-08 12:22:58"},
  {event: "rumination", cow_id: 3, cow: "cow3", event_location: "outside", timestamp: "2024-06-08 12:23:08"}
].freeze

if __FILE__ == $0
  watcher = EventWatcher.new(EVENTS)
  watcher.start_watching
end
