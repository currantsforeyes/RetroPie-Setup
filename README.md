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
git clone --depth=1 https://github.com/currantsforeyes/RetroPie-Setup.git
```

The script is executed with:

```shell
cd RetroPie-Setup
chmod +x pine64_retropie_setup.sh
sudo ./pine64_retropie_setup.sh
```

When you first run the script it may install some additional packages that are needed.

Binaries and Sources
--------------------

Installing from binary is recommended on a Raspberry Pi as building everything from source can take a long time.

For more information, visit the site at https://retropie.org.uk or the repository at https://github.com/RetroPie/RetroPie-Setup.

Docs
----

You can find useful information about several components and answers to frequently asked questions in the [RetroPie Docs](https://retropie.org.uk/docs/). If you think that there is something missing, you are invited to submit a pull request to the [RetroPie-Docs repository](https://github.com/RetroPie/RetroPie-Docs).


Thanks
------

This script just simplifies the usage of the great works of many other people that enjoy the spirit of retrogaming. Many thanks go to them!
