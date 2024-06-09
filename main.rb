require "net/http"
require "json"
require "time"

# Constants
API_URL = "https://api.example.com/cow_events"  # Replace with the actual API URL
VIDEO_PATH = "./videos"  # Directory where video files are stored

# Fetch event data from the API
def fetch_event_data(api_url)
  # uri = URI(api_url)
  # response = Net::HTTP.get(uri)
  # JSON.parse(response)

  [
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
end

# Parse event data and sort chronologically
def parse_event_data(event_data)
  puts event_data
  events = event_data.map do |event|
    event[:timestamp] = Time.parse(event[:timestamp])
    event
  end
  events.sort_by { |event| event[:timestamp] }
end

# Play the video for the specified duration
def play_video(filename, duration)
  filepath = File.join(VIDEO_PATH, filename)
  if File.exist?(filepath)
    system("ffplay", "-t", duration.to_s, "-autoexit", "-nodisp", filepath)
  else
    puts "Video file #{filename} not found."
  end
end

# Main logic to handle event playback
def handle_event_playback(events)
  events.each_with_index do |current_event, i|
    if i < events.size - 1
      next_event = events[i + 1]
      duration = next_event[:timestamp] - current_event[:timestamp]
    else
      duration = 10  # Default duration for the last event
    end

    video_filename = "#{current_event[:cow_name]}_#{current_event[:event]}.mp4"
    puts "Playing video: #{video_filename} for #{duration} seconds."
    play_video(video_filename, duration)
  end
end

if __FILE__ == $0
  # Fetch and process the event data
  event_data = fetch_event_data(API_URL)
  events = parse_event_data(event_data)

  # Handle the playback of events
  handle_event_playback(events)
end
