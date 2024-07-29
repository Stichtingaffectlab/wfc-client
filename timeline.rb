require "net/http"
require "httparty"
require "active_support/all"

PRE_SELECTED = [
  [[0, :resting, 1], [18, :ruminations, 2], [39, :ruminations, 1], [62, :resting, 3], [85, :ruminations, 3], [103, :resting, 2]]
]

DEFAULT_EVENT_LOCATION = "inside"

# Creates a timeline of events to be displayed. This class takes care of mixing and prioritizing
# different farm events mixed with lely apis and finally create a timeline of data as it happens in
# realtime.
#
class Timeline
  include HTTParty

  # base_uri "wfc-backend.fly.dev" # for production
  base_uri "localhost:3000"

  attr_reader :rumination_events, :milking_events, :farm_schedule, :farm_overrides, :cows

  def initialize
    @queue = []
    @base_timeline = []

    fetch_cows
    renew
    build_base_timeline
  end

  def renew
    fetch_ruminations
    fetch_schedule
    fetch_overrides
    fetch_milking
  end

  def build_base_timeline
    @last_built_at = Time.current
    @base_timeline = PRE_SELECTED[0].map do |s|
      {event: s[1], timestamp: Time.current + s[0].minutes, cow: "cow" + s[2].to_s}
    end
  end

  def get_current
    enqueue

    # if everything is empty then return the current event from base timeline
    if @queue.empty?
      current_time = truncate_to_minute(Time.current)
      current_event = @base_timeline.select do |event|
        event_time = truncate_to_minute(event[:timestamp])
        event_time <= current_time
      end.max_by do |event|
        event[:timestamp]
      end

      # if no current_event was found then build the timeline
      build_base_timeline unless current_event

      current_event
    elsif !@last_queued_at || @last_queued_at < 5.minutes.ago
      # return the last queued element
      @last_queued_event = @queue.shift # check for time when it was last shifted and play it until a certain time
      @last_queued_at = Time.current
      @last_queued_event
    else
      @last_queued_event
    end
  end

  private

  def enqueue
    # it's been 2h sicne we last built the timeline, so build it
    build_base_timeline if @last_built_at < 2.hours.ago

    # Look for any scheduled events at this time
    scheduled = @farm_schedule.find do |ev|
      t = ev["outside_at"] || ev["inside_at"] || ev["eats_at"]
      truncate_to_minute(Time.parse(t)) == truncate_to_minute(Time.current)
    end

    # See if there are any new overridden events
    fetch_overrides # if @last_overrides_check < 5.minutes.ago
    # get any live events added by the farmer
    overrides = @farm_overrides.select do |ev|
      five_min_ago = truncate_to_minute(Time.current - 5.minutes)
      event_time = truncate_to_minute(Time.parse(ev["created_at"]))
      # Here we only try to get events that were found 5 minutes ago, not older than that
      event_time >= five_min_ago && event_time <= Time.current
    end

    # See if there are any new milkings
    fetch_milking # if @last_milk_check < 5.minutes.ago
    # get milking events
    milkings = @milking_events.select do |ev|
      five_min_ago = truncate_to_minute(Time.current - 5.minutes)
      event_time = truncate_to_minute(Time.parse(ev["created_at"]))
      event_time >= five_min_ago && event_time <= Time.current
    end

    unless milkings.empty?
      @queue += milkings
    end

    unless overrides.empty?
      @queue += overrides
    end

    @queue.push(scheduled) if scheduled
  end

  # here we get
  #   `event`: `ruminations`
  #   `cow`
  # The rumination event must be spread across 2hr timeline randomly for each cow there is.
  # And the rest must be filled with resting event.
  # We create a base timeline with resting and ruminations.
  #
  def fetch_ruminations
    @rumination_events = self.class.get("/api/cow_events?event=ruminations").slice(0, @cows.length)
  end

  # here we get
  #   `event_location`
  #   `event`: `eating`
  # The base timeline can be overridden by the schedule
  #
  def fetch_schedule
    @farm_schedule = self.class.get("/api/farm_schedule")["schedule"]
  end

  # here we get
  #   `event_location`,
  #   `event`: `grazing`, `ruminating`, `eating`, `resting`,
  #   `cow` or `cows`
  # The base timeline and the schedule can be overridden by the farm events
  #
  def fetch_overrides
    @farm_overrides = self.class.get("/api/farm_events")
    @last_overrides_check = Time.current
  end

  # here we get
  #   `event`: `milking`
  #   `cow`
  # This event has the highest precedence. Whenever we get this event, it must be displayed.
  #
  def fetch_milking
    @milking_events = self.class.get("/api/cow_events?event=milking")
    @last_milk_check = Time.current
  end

  def fetch_cows
    @cows = self.class.get("/api/cows")
  end
end

def truncate_to_minute(time)
  time.change(sec: 0, usec: 0)
end

# t = Timeline.new
# puts t.rumination_events
# puts "-----"
# puts "-----"
# puts t.milking_events
# puts "-----"
# puts "-----"
# puts t.farm_schedule
# puts "-----"
# puts "-----"
# puts t.farm_overrides
# puts "-----"
# puts "-----"
# puts t.build
# puts "-----"
# puts "-----"
# puts t.get_current
