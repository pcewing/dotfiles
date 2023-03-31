# Windows 10 Additional Setup Steps

These are some recommended steps to get Windows 10 set up the way I like and
limit how intrusive Microsoft is.

## Disable Cortana

TODO

## Clean Up Task bar

TODO

## Hide Desktop Icons

TODO

## Disable "Let's finish setting up your device" reminders

- Open Settings from Start Menu
- Navigate to the "Notifications & actions" tab
- Under Notifications, uncheck the following boxes:
    - Show me the Windows welcome experience after updates and occasionally
      when I sign in to highlight what's new and suggested
    - Suggest ways I can finish setting up my device to get the most out of
      Windows
    - Get tips, tricks, and suggestions as you use Windows

## Install Powerline Fonts

TODO

## Install vim-plug

TODO

## AMD Graphics Driver

I've had an issue on my Desktop PC where the AMD graphics driver crashes fairly
often, especially when using some combination of Zoom, remote desktop, parsec,
and VPN.

Using the "Pro" driver instead of the standard Adrenaline driver seems to
improve this. I've still encountered some crashes but they seem far less
frequent.

Got this idea from the following video:
https://www.youtube.com/watch?v=O94izh6mwOk&ab_channel=WikkyPlays

Drivers for RX 6700 XT (My current desktop graphics card) are available here:
https://www.amd.com/en/support/graphics/amd-radeon-6000-series/amd-radeon-6700-series/amd-radeon-rx-6700-xt

# Rode AI-1 Microphone Issue

There is an issue with the AI-1 audio interface where the sample rate and bit
depth of the playback and recording interfaces will not match by default. If
they don't match, only one or the other will work.

To fix this, navigate to Control Panel and then to Sound. In the Playback tab,
find the Rode AI-1 device, click Properties, and navigate to the Advanced tab.
Set the sample rate and bit depth to the desired setting; I'm currently using
`2 channel, 24 bit, 96000 Hz`.

Next, back in the Sound Control Panel, navigate to the Recording tab, find the
Rode AI-1 device, click Properties, and navigate to the Advanced tab. Set the
sample rate and bit depth to match the value selected above. Note that the
channel will not match so for example, I'm currently using `1 channel, 24 bit,
96000 Hz`.
