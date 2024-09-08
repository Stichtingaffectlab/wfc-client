## Waiting for cows

Waiting for Cows is an interactive storytelling project that explores the complex relationship between humans, animals and technology. Set on a Friesian farm, the main protagonists are Dutch dairy cows monitored by wearables, conditioned by algorithms and quantified in data.


## Set up

**Requirements**: A linux machine with mpv installed

```sh
sudo apt install mpv # for debian based distros
sudo dnf install mpv # for red had based
```.

And then

```sh
bundle install
mkdir videos
# copy videos of the cows in this directory
# make sure the videos are named like this:
#
#   235_grazing_inside.mp4
#   235_grazing_outside.mp4
#   235_milking_inside.mp4
#   235_milking_outside.mp4
#   235_ruminations_inside.mp4
#   235_ruminations_outside.mp4
#
# same for the other cows
#

# run the mpv player in background
mpv --input-ipc-server=/tmp/mpvsocket --loop=inf --fullscreen videos/235_ruminations_inside.mp4 &
ruby main.rb
```

The correct name of the events in the filename must be

- ruminations
- milking
- eating
- grazing
- resting

## Development

We use [standardrb](https://github.com/standardrb/standard) for code formatting and linting.
