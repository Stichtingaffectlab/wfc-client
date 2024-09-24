require_relative "../../lib/timeline"
require_relative "../spec_helper"
require "yaml"
require "timecop"

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
    after do
      Timecop.return
    end

    context "by default" do
      it "returns the last rumination event" do
        expect(subject.get_current).to have_key(:event)
        expect(subject.get_current).to have_key(:duration)
        expect(subject.get_current[:event]).to eq(:ruminations)
      end
    end

    context "when multiple events happen at the same time, they are put in queue" do
      it "fetches rumination event" do
        # travel to the moment where we can test
        t = Time.local(2024, 9, 24, 7, 48, 10)
        Timecop.travel(t)

        # Initially we should receive the rumination event
        # from base timeline
        #
        expect(subject.get_current).to have_key(:event)
        expect(subject.get_current[:event]).to eq(:ruminations)

        # travel to the minute milking starts
        # It should be milking now as we truncate to the minute
        #
        Timecop.travel(t + 2.minutes) # go 2 minutes ahead
        puts subject.get_current
        expect(subject.get_current["event"]).to eq("milking")

        # the milking duration is for 6 minutes, so check if it is still milking
        # after 5 minutes
        #
        Timecop.travel(t + 5.minutes) # go 5 minutes ahead
        expect(subject.get_current["event"]).to eq("milking")

        # go past 6 minutes, now the milking event
        # should be over and we should start the scheduled event
        #
        Timecop.travel(t + 8.minutes) # go 8 minutes ahead
        expect(subject.get_current["event"]).to be_nil
        expect(subject.event_location).to eq("outside")

        # after 5 minutes, the event_location should change to inside
        Timecop.travel(t + 14.minutes)
        expect(subject.get_current[:event]).to eq(:ruminations)
        expect(subject.event_location).to eq("inside")
      end
    end

    context "when base timeline is over, a new one is built" do
      it "still continues to return events as they happen" do
      end
    end
  end
end
