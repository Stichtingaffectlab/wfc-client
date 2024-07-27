require "net/http"
require "httparty"

DEFAULT_EVENT_LOCATION = "inside"

class Timeline
  include HTTParty

  # base_uri "wfc-backend.fly.dev"
  base_uri "localhost:3000"

  attr_reader :rumination_events, :milking_events, :farm_schedule, :farm_overrides

  def initialize
    fetch_ruminations
    fetch_schedule
    fetch_overrides
    fetch_milking
  end

  private

  def fetch_ruminations
    # here we get
    #   `event`: `ruminations`
    #   `cow`
    @rumination_events = self.class.get("/api/cow_events?event=ruminations")
  end

  def fetch_milking
    # here we get
    #   `event`: `milking`
    #   `cow`
    @milking_events = self.class.get("/api/cow_events?event=milking")
  end

  def fetch_schedule
    # here we get
    #   `event_location`
    #   `event`: `eating`
    @farm_schedule = self.class.get("/api/farm_schedule")
  end

  def fetch_overrides
    # here we get
    #   `event_location`,
    #   `event`: `grazing`, `ruminating`, `eating`, `resting`,
    #   `cow` or `cows`
    @farm_overrides = self.class.get("/api/farm_events")
  end
end

t = Timeline.new
puts t.rumination_events
puts "-----"
puts "-----"
puts t.milking_events
puts "-----"
puts "-----"
puts t.farm_schedule
puts "-----"
puts "-----"
puts t.farm_overrides
