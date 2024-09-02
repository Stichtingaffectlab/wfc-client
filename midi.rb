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

# first led strip
midiout.send_channel_message(0xb0, 10, 20)
midiout.send_channel_message(0xb0, 1, 1)
midiout.send_channel_message(0xb0, 5, 127)
midiout.send_channel_message(0xb0, 4, 107)

# second led strip
midiout.send_channel_message(0xb0, 30, 60)

# for pitch in [60, 62, 64, 65, 67]
#   midiout.send_channel_message(0x90, pitch, 127)
#   sleep 0.5
#   midiout.send_channel_message(0x90, pitch, 0) # note off
# end

sleep 0.5 # give the final note off time to release
