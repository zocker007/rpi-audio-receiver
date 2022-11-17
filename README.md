# Raspberry Pi Audio Receiver

A simple, light weight audio receiver with Bluetooth (A2DP), AirPlay 1, Spotify Connect and UPnP.

## ⚠️ A note on Raspberry Pi OS Bullseye

The current version of Raspberry Pi OS (2021-10-30) is based on Debian 11 (Bullseye). This version does not contain the BlueALSA package (`bluealsa`) anymore. So this script will downlaod bluez-alsa sources from https://github.com/Arkq/bluez-alsa.git and build from source. You can also build bluez-alsa on another machine (like cross building or to keep target machine clean). For this you can build into a chroot'ed install dir and copy this chroot to the target machine into ../bluealsa relative to this script. It will detect this and only copy the chroot to local '/' and install neccessary dependencies. To build with chroot and copy the install dir you can do for example:

    mkdir build
    cd build
    INSTALLROOT=$HOME/bluealsa
    mkdir -p $INSTALLROOT
    ../configure --prefix=$INSTALLROOT/usr --with-systemdsystemunitdir=$INSTALLROOT/usr/lib/systemd/system --with-dbusconfdir=$INSTALLROOT/etc/dbus-1/system.d \
    --with-alsaplugindir=$INSTALLROOT/usr/lib/aarch64-linux-gnu/alsa-lib --with-alsaconfdir=$INSTALLROOT/etc/alsa/conf.d --enable-aac --enable-aptx --enable-aptx-hd \
    --with-libopenaptx --enable-faststream --enable-systemd --enable-upower --with-systemdbluealsaargs="-p a2dp-sink --a2dp-force-audio-cd --a2dp-volume --codec=aptX \
    --codec=aptX-HD --codec=FastStream --xapl-resp-name=<devicename>"  --with-systemdbluealsaaplayargs="--single-audio --pcm=hw:<alsacardname>\,0 --mixer-device=hw:<alsacardname> \
    --mixer-name=Master" --with-bluealsauser=bluealsa --with-bluealsaaplayuser=bluealsa
    make -j4
    make install
    scp -r $INSTALLROOT <user>@<host>:/home/<user>/

You may alternatively want to try [HiFiBerryOS](https://github.com/hifiberry/hifiberry-os/) for similar functionality.

## Features

Devices like phones, tablets and computers can play audio via this receiver.

## Requirements

- A USB Bluetooth dongle (the internal Raspberry Pi Bluetooth chipset turned out as not suited for audio playback and causes all kinds of strange connectivity problems)
- Raspberry Pi OS 11 Lite
- Internal audio, HDMI, USB or I2S Audio adapter (tested with [Adafruit USB Audio Adapter](https://www.adafruit.com/product/1475),  [pHAT DAC](https://shop.pimoroni.de/products/phat-dac), and [HifiBerry DAC+](https://www.hifiberry.com/products/dacplus/))

**Again: do not try to use the internal Bluetooth chip, this will only bring you many hours of frustration.**

## ⚠️ A note on Raspberry Pi OS 10 (Legacy)

The current version of Raspberry Pi OS (2022-01-28) is based on Debian 11 (Bullseye). This version does not contain the BlueALSA package (`bluealsa`) anymore. This repository now uses PulseAudio instead of ALSA. This may or may not work on slower devices like Raspberry Pi 1 and Raspberry Pi Zero.

For these devices, you might want to try [HiFiBerryOS](https://github.com/hifiberry/hifiberry-os/) for similar functionality or stick with the `debian-10` branch, which works with the "Raspberry Pi OS (Legacy)".

## Installation

The installation script asks whether to install each component.

    wget -q https://github.com/nicokaiser/rpi-audio-receiver/archive/bluez-alsa.zip
    unzip bluez-alsa.zip
    rm bluez-alsa.zip

    cd rpi-audio-receiver-bluez-alsa
    sudo ./install.sh

    reboot

### Basic setup

Lets you choose the hostname and the visible device name ("pretty hostname") which is displayed as Bluetooth name, in AirPlay clients and in Spotify.

### Bluetooth

Sets up Bluetooth, adds a simple agent that accepts every connection, and enables audio playback through PulseAudio. A udev script is installed that disables discoverability while connected.

### AirPlay 1

Installs [Shairport Sync](https://github.com/mikebrady/shairport-sync) AirPlay Audio Receiver.

### Spotify Connect

Installs [Raspotify](https://github.com/dtcooper/raspotify), an open source Spotify client for Raspberry Pi.

### Read-only mode

To avoid SD card corruption when powering off, you can boot Raspberry Pi OS in read-only mode. This can be achieved using the `raspi-config` script.

## Limitations

- Only one Bluetooth device can be connected at a time, otherwise interruptions may occur.
- The device is always open, new clients can connect at any time without authentication.
- To permanently save paired devices when using read-only mode, the Raspberry has to be switched to read-write mode until all devices have been paired once.
- You might want to use a Bluetooth USB dongle or have the script disable Wi-Fi while connected (see `bluetooth-udev`), as the BCM43438 (Raspberry Pi 3, Zero W) has severe problems with both switched on, see [raspberrypi/linux/#1402](https://github.com/raspberrypi/linux/issues/1402).
- The Pi Zero may not be powerful enough to play 192 kHz audio, you may want to change the values in `/etc/asound.conf` accordingly.

## Wiki

There are some further examples, tweaks and how-tos in the [GitHub Wiki](https://github.com/nicokaiser/rpi-audio-receiver/wiki).

## Disclaimer

These scripts are tested and work on a current Raspberry Pi OS setup on Raspberry Pi. Depending on your setup (board, configuration, sound module, Bluetooth adapter) and your preferences, you might need to adjust the scripts. They are held as simple as possible and can be used as a starting point for additional adjustments.

## Upgrading

This project does not really support upgrading to newer versions of this script. It is meant to be adjusted to your needs and run on a clean Raspberry Pi OS install. When something goes wrong, the easiest way is to just wipe the SD card and start over. Since apart from Bluetooth pairing information all parts are stateless, this should be ok.

Updating the system using `apt-get upgrade` should work however.

## Uninstallation

This project does not support uninstall at all. As stated above, it is meant to run on a dedicated device on a clean Raspberry Pi OS. If you choose to use this script along with other services on the same device, or install it on an already configured device, this can lead to unpredictable behaviour and can damage the existing installation permanently.

## Contributing

Package and configuration choices are quite opinionated but as close to the Debian defaults as possible. Customizations can be made by modifying the scripts, but the installer should stay as simple as possible, with as few choices as possible. That said, pull requests and suggestions are of course always welcome. However I might decide not to merge changes that add too much complexity.

## Related projects

As this project is kept very simple and opinionated, there are many forks and similar projects that are optimized for more specific requirements.

- [Arcaria197/rpi-audio-receiver](https://github.com/Arcadia197/rpi-audio-receiver) - a fork that uses Raspbian 10 (legacy) and runs on Raspberry Pi Zero W hardware
- [HiFiBerryOS](https://github.com/hifiberry/hifiberry-os/) - a more sophisticated approach on this, using an entirely custom (buildroot) ecosystem

## References

- [Shairport Sync: AirPlay Audio Receiver](https://github.com/mikebrady/shairport-sync)
- [Raspotify: Spotify Connect client for the Raspberry Pi that Just Works™](https://github.com/dtcooper/raspotify)

## License

[MIT](LICENSE)
