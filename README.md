[![Tests](https://github.com/Stichtingaffectlab/wfc-client/actions/workflows/test.yml/badge.svg)](https://github.com/Stichtingaffectlab/wfc-client/actions/workflows/test.yml)

## Waiting for cows

Waiting for Cows is an interactive storytelling project that explores the complex relationship between humans, animals and technology. Set on a Friesian farm, the main protagonists are Dutch dairy cows monitored by wearables, conditioned by algorithms and quantified in data.

## Development

**Requirements**: A linux machine with [mpv](https://mpv.io) installed

```sh
sudo apt install mpv # for debian based distros
sudo dnf install mpv # for red had based
```

or if you are using a mac

```
brew install mpv
```

Set up [rbenv](https://github.com/rbenv/rbenv), which should install the right ruby and bundler versions.

And then

```sh
bundle install
```

Copy videos of the cows in `videos` directory. And make sure they are named in the following way

```
235_eating_inside.mp4
235_eating_outside.mp4
235_milking_main.mp4
235_ruminations_inside.mp4
235_ruminations_outside.mp4
cows_go_inside.mp4
cows_go_outside.mp4
```

Do the same for the other cows.

Run the mpv player in background (ntice the `&` at the end)

```sh
mpv --input-ipc-server=/tmp/mpvsocket --loop=inf --fullscreen videos/235_ruminations_inside.mp4 &
```

Start the script

```sh
ruby main.rb
```

You may set the environment `API_URL=localhost:3000` if you are running our [backend](https://github.com/Stichtingaffectlab/wfc-backend) locally.

The correct name of the events in the filename must be `ruminations`, `milking`, `eating`, `grazing`, `resting`.

OR you can simply run the bash script which runs both the above commands. In the museum installation, this might be the easier approach

```sh
chmod +x ./run-wfc.sh
./run-wfc.sh
```

Then you can check for logs in `tmp/` folder and `tail` it.

If you simply want to end all the processes, you can run

```sh
chmod +x ./end-wfc.sh
./end-wfc.sh
```

## Code style

We use [standardrb](https://github.com/standardrb/standard) for code formatting and linting. Make sure to install the [standard ruby vscode extension](https://marketplace.visualstudio.com/items?itemName=testdouble.vscode-standard-ruby) if you are using vscode/vscodium. They support various editors, do check out their [repository](https://github.com/standardrb/standard?tab=readme-ov-file#editor-support).

## Testing

We have rspec tests that uses timecop gem to check for the queuing of events and how the timeline is built. To run the tests

```sh
rspec .
```

or you can run the below to watch changes as you develop

```sh
bundle exec guard
```

## Production

### Restarts

Set up crontab to perform some tasks like restarting the program.

```sh
crontab -e
```

This will open an editor like vim and then enter

```
1 0 * * * /home/robina/code/wfc-client/run-wfc.sh
```

The entry suggests to run tour script `run-wfc.sh` at 00:01 midnight. This ensures new start of the day for logging. In the above entry, `robina` is the name of the user, make sure to substitute with appropriate user name.

### Autostart

To start the program on boot:

```sh
mkdir ~/.config/autostart
cat <<EOF | tee -a ~/.config/autostart/wfc.desktop
[Desktop Entry]
Type=Application
Exec=/bin/sh -c "sleep 10 && /home/robina/code/wfc-client/run-wfc.sh"
Name=WFC
EOF
```

You may run the below command to ensure the validity of the autostart file

```
desktop-file-validate ~/.config/autostart/wfc.desktop
```

or follow [this guide](https://learn.sparkfun.com/tutorials/how-to-run-a-raspberry-pi-program-on-startup#method-2-autostart)

## Credits

[madhums](https://github.com/madhums) and [RobBothof](https://github.com/RobBothof)
