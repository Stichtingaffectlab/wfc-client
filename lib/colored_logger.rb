require "logger"
require "colorize"

# Use a coloured logger to print logs
#
class ColoredLogger < Logger
  def format_message(severity, timestamp, progname, msg)
    # Grey colour for timestamp, reset colour for log message
    "#{timestamp.strftime("%Y-%m-%d %H:%M:%S").light_black} - #{msg}\n"
  end
end
