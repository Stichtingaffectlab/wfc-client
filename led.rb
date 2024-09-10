require "rtmidi"

midiout = RtMidi::Out.new

##############################################################################
# Boilerplate code for selecting a MIDI port

puts "Available MIDI output ports"
midiout.port_names.each_with_index { |name, index| printf "%3i: %s\n", index, name }

##############################################################################
# Use this approach when you only need to send channel message like:
# MIDI notes, modulation/CC, pitch bend, aftertouch

midiout.open_port(1)

# second
midiout.send_channel_message(0xb0, 30, 20)
midiout.send_channel_message(0xb0, 25, 108)
midiout.send_channel_message(0xb0, 24, 18)

# third
midiout.send_channel_message(0xb0, 50, 20)
midiout.send_channel_message(0xb0, 50, 20)
midiout.send_channel_message(0xb0, 45, 108)
midiout.send_channel_message(0xb0, 44, 18)

# first
midiout.send_channel_message(0xb0, 10, 20)
midiout.send_channel_message(0xb0, 5, 108)
midiout.send_channel_message(0xb0, 4, 18)
