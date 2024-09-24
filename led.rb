require "rtmidi"

class LedController
  def initialize
    puts "Available MIDI output ports"
    midiout.port_names.each_with_index { |name, index| printf "%3i: %s\n", index, name }
    @midi = RtMidi::Out.new
    @midi.open_port(1)
  end

  def turn_all_off
    @midi.send_channel_message(0xb0, 30, 0)
    @midi.send_channel_message(0xb0, 50, 0)
    @midi.send_channel_message(0xb0, 10, 0)
  end

  def cow_235
    @midi.send_channel_message(0xb0, 30, 20)
    @midi.send_channel_message(0xb0, 25, 108)
    @midi.send_channel_message(0xb0, 24, 18)
  end

  def cow_468
    @midi.send_channel_message(0xb0, 50, 20)
    @midi.send_channel_message(0xb0, 45, 108)
    @midi.send_channel_message(0xb0, 44, 18)
  end

  def cow_507
    @midi.send_channel_message(0xb0, 10, 20)
    @midi.send_channel_message(0xb0, 5, 108)
    @midi.send_channel_message(0xb0, 4, 18)
  end
end
