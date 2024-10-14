require "httparty"
require "active_support/all"

# Creates a timeline of events to be displayed. This class takes care of mixing and prioritizing
# different farm events mixed with lely apis and finally create a timeline of data as it
# happens in realtime.
#
class Timeline
  DEFAULT_EVENT_LOCATION = "inside"
  PUT_INSIDE_AFTER = 20 # minutes
  DEFAULT_EVENT_DURATION = 5 # minutes
  include HTTParty

  base_uri ENV["API_URL"] || "wfc-backend.fly.dev"

  attr_reader :rumination_events, :milking_events, :farm_schedule, :farm_overrides, :cows, :event_location, :queue

  def initialize
    @queue = []
    @base_timeline = []
    @all = []
    @event_location = DEFAULT_EVENT_LOCATION
    @event_location_set_at = Time.current

    fetch_cows
    renew
    build_base_timeline
  end

  def get_current
    if !@last_queued_at || @last_queued_at < 5.minutes.ago || @queue.empty?
      enqueue
    end

    # build base timeline if it's been some time ago
    build_base_timeline if @last_built_at <= @base_timeline_duration.minutes.ago

    # change event_location to "inside" if not already changed by the event
    set_inside if @event_location_set_at < PUT_INSIDE_AFTER.minutes.ago

    # If everything is empty then return the current event from base timeline.
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

      return current_event
    elsif (@last_popped_at || Time.parse(@queue.first[:created_at])) < event_duration.minutes.ago
      # empty the queue
      @last_popped_at = Time.current
      last = @queue.shift
      @all.push(last)
    end

    # When there is no event, then it's the setting of event_location "inside" or "outside"
    # We store them for future use.
    if @queue.first && (!@queue.first[:event] || @queue.first[:event_location])
      @event_location = @queue.first[:event_location]
      @event_location_set_at = Time.current
    end

    # make sure the method returns an event
    # note that this can possibly lead to infinite loop if there is no data for the present day
    # in that case, run the job
    @queue.first || get_current
  end

  private

  # Amount of duration a event needs to be played
  def event_duration
    # @todo add more cases for grazing, eating, scheduled event etc
    case @queue.first[:event]
    when "milking"
      @queue.first[:duration]
    else
      DEFAULT_EVENT_DURATION
    end
  end

  def enqueue
    @last_queued_at = Time.current if !@last_queued_at

    fetch_schedule
    # Look for any scheduled events at this time
    scheduled = @farm_schedule.find do |ev|
      # @todo outside_at and inside_at are not necessary here because we don't have videos for these
      # These are merely indicators for event_location. However, eats_at can be used for eating event
      # if there's a video for it
      t = ev[:outside_at] || ev[:inside_at] || ev[:eats_at]

      event_time = truncate_to_minute(Time.parse(t))
      event_time.between?(truncate_to_minute(@last_queued_at), truncate_to_minute(Time.current))
    end

    # See if there are any new overridden events
    fetch_overrides
    # get any live events added by the farmer
    overrides = @farm_overrides.select do |ev|
      event_time = truncate_to_minute(Time.parse(ev[:created_at]))
      event_time.between?(truncate_to_minute(@last_queued_at), truncate_to_minute(Time.current))
    end

    # @todo this should check for the milking duration (and play the video for that duration)
    # See if there are any new milkings
    fetch_milking
    # get milking events
    milkings = @milking_events.select do |ev|
      event_time = truncate_to_minute(Time.parse(ev[:created_at]))
      event_time.between?(truncate_to_minute(@last_queued_at), truncate_to_minute(Time.current))
    end

    unless milkings.empty?
      @queue = (@queue + milkings.reverse).uniq { |item| item[:id] }
    end

    unless overrides.empty?
      @queue = (@queue + overrides.reverse).uniq { |item| item[:id] }
    end

    @queue.push(scheduled) if scheduled

    # remove any events that have been already played
    @queue = @queue.reject do |obj1|
      @all.any? { |obj2| obj1[:id] == obj2[:id] }
    end

    @last_queued_at = Time.current
  end

  def renew
    fetch_ruminations
    fetch_schedule
    fetch_overrides
    fetch_milking
  end

  def build_base_timeline
    @last_built_at = Time.current

    @base_timeline_duration = @rumination_events.reduce(0) { |s, e| s + (e[:duration].zero? ? 40 : e[:duration]) }

    @base_timeline = @rumination_events.reduce([]) do |s, r|
      s << {
        event: "ruminations",
        duration: r[:duration].zero? ? 40 : r[:duration],
        timestamp: ((s.last && s.last[:timestamp]) || Time.current) + (s.empty? ? 0 : s.last[:duration].minutes),
        cow: r[:cow]
      }
    end
  end

  # here we get
  #   `event`: `ruminations`
  #   `cow`
  # The rumination event must be spread across 2hr timeline randomly for each cow there is.
  # And the rest must be filled with resting event.
  # We create a base timeline with resting and ruminations.
  #
  def fetch_ruminations
    @rumination_events = self.class.get("/api/cow_events?event=ruminations").slice(0, @cows.length).map(&:deep_symbolize_keys)
  end

  # here we get
  #   `event_location`
  #   `event`: `eating`
  # The base timeline can be overridden by the schedule
  #
  def fetch_schedule
    @farm_schedule = self.class.get("/api/farm_schedule")["schedule"].map(&:deep_symbolize_keys)
  end

  # here we get
  #   `event_location`,
  #   `event`: `grazing`, `ruminating`, `eating`, `resting`,
  #   `cow` or `cows`
  # The base timeline and the schedule can be overridden by the farm events
  #
  def fetch_overrides
    @farm_overrides = self.class.get("/api/farm_events").map(&:deep_symbolize_keys)
  end

  # here we get
  #   `event`: `milking`
  #   `cow`
  # This event has the highest precedence. Whenever we get this event, it must be displayed.
  #
  def fetch_milking
    @milking_events = self.class.get("/api/cow_events?event=milking").map(&:deep_symbolize_keys)
  end

  def fetch_cows
    @cows = self.class.get("/api/cows").map(&:deep_symbolize_keys)
  end

  def set_inside
    @event_location = "inside"
  end
end

def truncate_to_minute(time)
  time.change(sec: 0, usec: 0)
end
