RetroPie-Setup
==============

General Usage
-------------

Shell script to setup the Pine64 A64 running Armbian with many emulators and games, using EmulationStation as the graphical front end. There are no bootable pre-made images for the Pine A64 as it is not widely supported and quite an old device.

This script is designed for use on Pine A64 mainline kernel implemented in Armbian.

To run the Pine64 RetroPie Setup Script make sure that your APT repositories are up-to-date and that Git is installed:

```shell
sudo apt update
sudo apt upgrade
sudo apt install git
```

Then you can download the latest Pine64 RetroPie setup script with:

```shell
cd
git clone --depth=1 https://github.com/RetroPie/RetroPie-Setup.git
```

The script is executed with:

```shell
cd RetroPie-Setup
chmod +x retropie_setup.sh
sudo ./retropie_setup.sh
```

When you first run the script it may install some additional packages that are needed.

Binaries and Sources
--------------------

Since the Pine64 has different hardware to the Raspberry Pi family, installing from source is recommended but does take a long time.

**I also have a Mali GPU optimisation script.**

What It Does:
Phase 1: Performance governors via systemd service
Phase 2: 128MB CMA allocation in /boot/armbianEnv.txt
Phase 3: RetroArch Mali-400MP2 configuration
Phase 4: N64-specific optimizations
Phase 5: Verification of GPU status

# Save the script
```shell
curl -o pine_a64_gpu_setup.sh https://github.com/currantsforeyes/RetroPie-Setup/pine_a64_gpu_setup.sh
chmod +x pine_a64_gpu_setup.sh
./pine_a64_gpu_setup.sh
```

# Or copy the script content by creating the file:
```shell
nano pine_a64_gpu_setup.sh
```

# Reboot to apply changes
```shell
sudo reboot
```

# Install PulseAudio if missing
```shell
sudo apt update
sudo apt install pulseaudio pulseaudio-utils
```

# Start PulseAudio
```shell
pulseaudio --start
```

# Set HDMI as default
```shell
pactl set-default-sink 1
```

Hardware requirements (Pine A64, Mali-400MP2 compatibility)
Prerequisites (Armbian 25.8.1 Bookworm, Lima drivers)
Known working emulators (NES, SNES, N64 with mupen64plus-glide64)
Known issues (analog audio problems on some boards)

Verification commands users can run after the script:
Confirm optimizations applied
```shell
cat /sys/devices/platform/soc/1c40000.gpu/devfreq/1c40000.gpu/governor
dmesg | grep -i cma
```

Notes
----
This process has been tested on the Pine A64+ board with 1GB of RAM and it works. It isn't perfect (there is still some audio stutter) but the N64 is quite demanding on resources. I would expect any emulator prior to the N64 should work. I haven't tested any disc-based consoles as i didn't see much point.

My Pine A64+ was sat doing nothing since i backed it on Kickstarter many moons ago and this has given it new life :D

Docs
----

You can find more information on the [RetroPie website](https://retropie.org.uk/)
or there may be something in the [RetroPie-Docs repository](https://github.com/RetroPie/RetroPie-Docs).


Thanks
------

This script just simplifies the usage of the great works of many other people that enjoy the spirit of retrogaming. Many thanks go to them!
