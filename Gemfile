# frozen_string_literal: true

source "https://rubygems.org"

# to make api calls
gem "httparty", "~> 0.22.0"

# for some date sugar
gem "activesupport", "~> 7.1"

# to control led strips
gem "rtmidi", "~> 0.3", require: false

# for playing video
gem "mpv", "~> 3.0"

group :development do
  gem "guard"
  gem "guard-rspec", "~> 4.7"

  # to lint and format code
  gem "standard", "~> 1.39"
end

group :test do
  # testing framework
  gem "rspec", "~> 3.13"

  # for time travelling and testing the timeline
  gem "timecop", "~> 0.9.10"
end

gem "colorize", "~> 1.1"
