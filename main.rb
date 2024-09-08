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
# - x for milking event, play the video for that duration
# - x include scheduled event in the queue
#   - x keep a default for the amount of time scheduled event plays
#   - if no scheduled event for the day, use last one
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
    @tl.get_current
  end

  def play_video(filename)
    filepath = File.join(VIDEO_PATH, filename)
    unless File.exist?(filepath)
      puts "Video file #{filename} not found."
      return
    end

    # Stop any currently playing video
    @pipeline.set_state(:null)
    @pipeline.children.each { |child| @pipeline.remove(child) }

    # Create GStreamer elements for video playback
    source = Gst::ElementFactory.make("filesrc", "source")
    source.location = filepath
    decode = Gst::ElementFactory.make("decodebin", "decode")
    sink = Gst::ElementFactory.make("autovideosink", "sink")

    @pipeline.add(source, decode, sink)
    source.link(decode)

    decode.signal_connect("pad-added") do |_, pad|
      pad.link(sink.get_static_pad("sink"))
    end

    # @todo play the video in loop

    @pipeline.set_state(:playing)
  end

  def handle_event_playback(ev)
    video_filename = "#{get_cow(ev)}_#{ev[:event]}_#{@tl.event_location}.mp4"
    puts "Playing video: #{video_filename}"
    play_video(video_filename)
  end

  def get_cow(ev)
    (ev[:cow] && (ev[:cow][:name] || ev[:cow]["name"])).split(" ").first
  end

  def start_watching
    loop do
      if Time.now - @last_checked >= CHECK_INTERVAL
        ev = fetch_event
        puts ev
        if @current_event != ev
          @current_event = ev
          if @current_event && @current_event[:event]
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

if __FILE__ == $0
  watcher = EventWatcher.new(EVENTS)
  watcher.start_watching
end
