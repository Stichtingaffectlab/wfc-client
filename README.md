## Waiting for cows

Waiting for Cows is an interactive storytelling project that explores the complex relationship between humans, animals and technology. Set on a Friesian farm, the main protagonists are Dutch dairy cows monitored by wearables, conditioned by algorithms and quantified in data.


## Set up

**Requirements**: A linux machine running gnome and gtk with gstreamer installed.

```sh
bundle install
mkdir videos
# copy videos of the cows in this directory
# make sure the videos are named like this:
#
#   cow1_grazing.mp4
#   cow1_milking.mp4
#   cow1_rumination.mp4
#
# same for the other cows
#
ruby main.rb
```
