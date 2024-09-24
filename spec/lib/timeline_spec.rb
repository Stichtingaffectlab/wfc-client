require_relative "../../lib/timeline"
require_relative "../spec_helper"
require "yaml"

describe Timeline do
  let(:cows) { load_fixture("cows.yml") }
  let(:schedule) { load_fixture("schedule.yml") }
  let(:overrides) { load_fixture("overrides.yml") }
  let(:milking) { load_fixture("milking.yml") }
  let(:ruminations) { load_fixture("ruminations.yml") }

  # Mock the API calls
  before do
    allow(Timeline).to receive(:get)
      .with("/api/cows")
      .and_return(cows)

    # Mock the farm schedule API call
    allow(Timeline).to receive(:get)
      .with("/api/farm_schedule")
      .and_return(schedule)

    # Mock the farm events API call
    allow(Timeline).to receive(:get)
      .with("/api/farm_events")
      .and_return(overrides)

    # Mock the cow events API call for ruminations
    allow(Timeline).to receive(:get)
      .with("/api/cow_events?event=ruminations")
      .and_return(ruminations)

    # Mock the cow events API call for milking
    allow(Timeline).to receive(:get)
      .with("/api/cow_events?event=milking")
      .and_return(milking)
  end

  it { is_expected.to be_an_instance_of(Timeline) }
  it { is_expected.to respond_to(:get_current, :queue, :event_location) }

  it "follows three cows" do
    expect(cows.length).to be 3
  end

  describe "event_location" do
    it "has event_location set to inside" do
      expect(subject.event_location).to eq("inside")
    end
  end

  describe "queue" do
    it "has a list of items in the queue" do
      expect(subject.queue).to match_array([])
    end
  end

  describe "#get_current" do
    it "returns the last rumination event" do
      expect(subject.get_current).to have_key(:event)
      expect(subject.get_current).to have_key(:duration)
    end
  end
end
