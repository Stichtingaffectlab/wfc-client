require_relative "lib/event_watcher"

$stdout.sync = true

if __FILE__ == $0
  watcher = EventWatcher.new
  watcher.start
end
