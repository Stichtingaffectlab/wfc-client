require "net/http"
require "json"
require "time"
require "gtk3"
require "gst"

# Constants
API_URL = "https://api.example.com/cow_events"  # Replace with the actual API URL
VIDEO_PATH = "./videos"  # Directory where video files are stored
CHECK_INTERVAL = 10 # seconds

last_checked = Time.now;

EVENTS =   [
  {
    event: "milking",
    cow_id: 1,
    cow_name: "cow1",
    timestamp: "2024-06-08 12:22:18"
  },
  {
    event: "rumination",
    cow_id: 2,
    cow_name: "cow2",
    timestamp: "2024-06-08 12:22:28"
  },
  {
    event: "grazing",
    cow_id: 3,
    cow_name: "cow3",
    timestamp: "2024-06-08 12:22:38"
  },
  {
    event: "milking",
    cow_id: 2,
    cow_name: "cow2",
    timestamp: "2024-06-08 12:22:48"
  },
  {
    event: "grazing",
    cow_id: 1,
    cow_name: "cow2",
    timestamp: "2024-06-08 12:22:58"
  },
  {
    event: "rumination",
    cow_id: 3,
    cow_name: "cow3",
    timestamp: "2024-06-08 12:23:08"
  }
]

# Parse event data and sort chronologically
def parse_event_data(event_data)
  puts event_data
  events = event_data.map do |event|
    event[:timestamp] = Time.parse(event[:timestamp])
    event
  end
  events.sort_by { |event| event[:timestamp] }
end

events = parse_event_data(EVENTS)

# Fetch event data from the API
def fetch_event(events)
  # uri = URI(api_url)
  # response = Net::HTTP.get(uri)
  # JSON.parse(response)
  events.shift
end

# Play the video for the specified duration
def play_video(pipeline, filename)
  filepath = File.join(VIDEO_PATH, filename)
  if File.exist?(filepath)
    pipeline.set_state(:null)
    pipeline.children.each { |child| pipeline.remove(child) }

    source = Gst::ElementFactory.make("filesrc", "source")
    source.location = filepath
    decode = Gst::ElementFactory.make("decodebin", "decode")
    sink = Gst::ElementFactory.make("autovideosink", "sink")

    pipeline.add(source, decode, sink)
    source.link(decode)
    decode.signal_connect("pad-added") do |_, pad|
      pad.link(sink.get_static_pad("sink"))
    end

    pipeline.set_state(:playing)
  else
    puts "Video file #{filename} not found."
  end
end

# Main logic to handle event playback
def handle_event_playback(pipeline, current_event)
  video_filename = "#{current_event[:cow_name]}_#{current_event[:event]}.mp4"
  puts "Playing video: #{video_filename}"
  play_video(pipeline, video_filename)
end

def start_watching(pipeline, events, last_checked, interval)
  if (Time.now - last_checked >= interval)
    current_event = fetch_event(events)
    pipeline.set_state(:null)
    handle_event_playback(pipeline, current_event) if current_event
    last_checked = Time.now
  end
  sleep(11)
  start_watching(pipeline, events, last_checked, interval)
end

if __FILE__ == $0
  Gst.init
  pipeline = Gst::Pipeline.new("video_pipeline")
  start_watching(pipeline, events, last_checked, CHECK_INTERVAL)
end
