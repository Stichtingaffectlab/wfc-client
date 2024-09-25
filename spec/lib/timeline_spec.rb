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
    context "by default" do
      it "returns the last rumination event" do
        expect(subject.get_current).to have_key(:event)
        expect(subject.get_current).to have_key(:duration)
        expect(subject.get_current[:event]).to eq("ruminations")
      end
    end

    describe "queue" do
      let(:t) { Time.local(2024, 9, 24, 7, 48, 10) }

      before(:all) do
        # travel to the moment where we can test
        Timecop.travel(Time.local(2024, 9, 24, 7, 48, 10))
        @tl = described_class.new
      end

      after(:all) do
        Timecop.return
      end

      it "retrieves events in an order" do
        # Initially we should receive the rumination event
        # from base timeline
        expect(@tl.get_current).to have_key(:event)
        expect(@tl.get_current[:event]).to eq("ruminations")
      end

      # travel to the minute milking starts
      # It should be milking now as we truncate to the minute
      it "retrieves mulking event" do
        Timecop.travel(t + 2.minutes) # go 2 minutes ahead
        expect(@tl.get_current[:event]).to eq("milking")
      end

      # the milking duration is for 6 minutes, so check if it is still milking
      # after 5 minutes
      it "handles the milking and scheduled event transition" do
        Timecop.travel(t + 5.minutes) # go 5 minutes ahead
        last_event = @tl.get_current
        expect(@tl.get_current[:event]).to eq("milking")
        expect(@tl.event_location).to eq("inside")

        # go past 6 minutes, now the milking event
        # should be over and we should start the scheduled event

        Timecop.travel(t + (last_event[:duration] + 2).minutes) # go 8 minutes ahead
        expect(@tl.get_current[:event]).to be_nil
        expect(@tl.event_location).to eq("outside")
      end

      # after 5 minutes, the scheduled event will be over so ruminations
      # start from the base timeline
      it "starts rumination after queue is empty" do
        Timecop.travel(t + 14.minutes)
        expect(@tl.get_current[:event]).to eq("ruminations")
        # note that the event_location is still outside
        expect(@tl.event_location).to eq("outside")
      end

      # after 20 minutes, the event_location should change to inside
      # after 8 minutes (when it is scheduled) + 20 (default duration to put inside)
      it "ensures location is reset after a set duration" do
        Timecop.travel(t + (Timeline::PUT_INSIDE_AFTER + 9).minutes)
        @tl.get_current
        expect(@tl.event_location).to eq("inside")
      end

      # Now we are going to travel further to see if we still
      # receive rumination events
      it "continues with enqueuing unplayed events when skipped" do
        Timecop.travel(t + 3.hours) # 10:48
        # we have a scheduled event at 9 when the cows eat outside
        # so this is first played and then the ruminations
        expect(@tl.get_current[:event]).to eq("eating")
      end

      # The scheduled event must be played for 5 minutes (default setting)
      it "plays scheduled event for #{Timeline::DEFAULT_EVENT_DURATION} minutes" do
        Timecop.travel(t + 3.hours + (Timeline::DEFAULT_EVENT_DURATION + 1).minutes) # 10:54
        expect(@tl.get_current[:event]).to eq("ruminations")
      end

      # Now go to the time of milking event at 12:00
      it "continues enqueuing events as they happen" do
        # Randomly go a bit further
        Timecop.travel(t + 4.hours)
        @tl.get_current
        Timecop.travel(t + 4.hours + 2.minutes)
        @tl.get_current
        # sleep(1)
        @tl.get_current

        Timecop.travel(Time.local(2024, 9, 24, 12, 0, 10))
        expect(@tl.get_current[:event]).to eq("milking")
        expect(@tl.event_location).to eq("inside")
      end
    end
  end
end
