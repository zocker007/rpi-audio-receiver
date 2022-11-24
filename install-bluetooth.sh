#!/bin/bash -e

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

echo
echo "In the following, bluez-alsa (https://github.com/Arkq/bluez-alsa.git) will be build from source."
echo "You can use a chroot'ed installation of bluez-alsa in ../bluealsa/ that was build on a remote machine to continue without building from source."
echo "Instructions on how to build from source can be found here: https://github.com/Arkq/bluez-alsa/wiki/Installation-from-source."
echo -n "Do you want to install Bluetooth Audio (BlueALSA)? [y/N] "
read REPLY
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then exit 0; fi

adduser --system --group --no-create-home bluealsa
adduser bluealsa audio
cd ..

if [ -d "bluealsa" ]; then
    apt install -y --no-install-recommends alsa-utils bluez-tools libasound2 libbluetooth3 libglib2.0-0 libsbc1 libdbus-1-3 libopenaptx0 libfdk-aac2
    cp -r bluealsa/* /
else
    apt install -y --no-install-recommends alsa-utils bluez-tools git automake build-essential libtool pkg-config python3-docutils
    apt install -y libasound2-dev libbluetooth-dev libdbus-1-dev libglib2.0-dev libsbc-dev libopenaptx-dev libfdk-aac-dev

    git clone https://github.com/Arkq/bluez-alsa.git
    cd bluez-alsa

    autoreconf --install --force
    mkdir build
    cd build
    ../configure --enable-aac --enable-aptx --enable-aptx-hd --with-libopenaptx --enable-faststream --enable-systemd --enable-upower \
    --with-systemdbluealsaargs="-p a2dp-sink --a2dp-force-audio-cd --a2dp-volume --codec=aptX --codec=aptX-HD --codec=FastStream --xapl-resp-name=<devicename>" \
    --with-systemdbluealsaaplayargs="--single-audio --pcm=hw:0\,0 --mixer-device=hw:0 --mixer-name=Master" \
    --with-bluealsauser=bluealsa --with-bluealsaaplayuser=bluealsa
    make -j4
    make install
fi

# Bluetooth settings
cat <<'EOF' > /etc/bluetooth/main.conf
[General]
Class = 0x200414
DiscoverableTimeout = 0

[Policy]
AutoEnable=true
EOF

# Make Bluetooth discoverable after initialisation
mkdir -p /etc/systemd/system/bthelper@.service.d
cat <<'EOF' > /etc/systemd/system/bthelper@.service.d/override.conf
[Service]
Type=oneshot
EOF

cat <<'EOF' > /etc/systemd/system/bt-agent@.service
[Unit]
Description=Bluetooth Agent
Requires=bluetooth.service
After=bluetooth.service

[Service]
ExecStartPre=/usr/bin/bluetoothctl discoverable on
ExecStartPre=/bin/hciconfig %I piscan
ExecStartPre=/bin/hciconfig %I sspmode 1
ExecStart=/usr/bin/bt-agent --capability=NoInputNoOutput
RestartSec=5
Restart=always
KillSignal=SIGUSR1

[Install]
WantedBy=multi-user.target
EOF

cat <<'EOF' > /etc/systemd/system/mpris-proxy.service
[Unit]
Description=Bluetooth MPRIS proxy
Wants=network-online.target
After=dbus.target bluealsa.service

[Service]
Type=simple
Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket
ExecStart=/usr/bin/mpris-proxy
StandardOutput=journal
Restart=always
RestartSec=5
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target
EOF

cat << 'EOF' > /etc/dbus-1/system.d/mpris-proxy.conf
<!-- Root can control everything on system MBUS. -->

<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>

  <policy user="root">                                    
    <!-- Allow everything to be sent -->                        
    <allow send_destination="*" eavesdrop="true"/>              
    <!-- Allow everything to be received -->                    
    <allow eavesdrop="true"/>                                
    <!-- Allow anyone to own anything -->             
    <allow own="*"/>                                  
  </policy>      

</busconfig>
EOF

# ALSA settings
sed -i.orig 's/^options snd-usb-audio index=-2$/#options snd-usb-audio index=-2/' /lib/modprobe.d/aliases.conf

# BlueALSA
systemctl daemon-reload
systemctl enable bt-agent@hci0.service
systemctl enable bluealsa
systemctl enable bluealsa-aplay
systemctl enable mpris-proxy

# Bluetooth udev script
cat <<'EOF' > /usr/local/bin/bluetooth-udev
#!/bin/bash
if [[ ! $NAME =~ ^\"([0-9A-F]{2}[:-]){5}([0-9A-F]{2})\"$ ]]; then exit 0; fi

action=$(expr "$ACTION" : "\([a-zA-Z]\+\).*")

if [ "$action" = "add" ]; then
    bluetoothctl discoverable off
    # disconnect wifi to prevent dropouts
    ip link set wlan0 down &
fi

if [ "$action" = "remove" ]; then
    # reenable wifi
    ip link set wlan0 up &
    bluetoothctl discoverable on
fi
EOF
chmod 755 /usr/local/bin/bluetooth-udev

cat <<'EOF' > /etc/udev/rules.d/99-bluetooth-udev.rules
SUBSYSTEM=="input", GROUP="input", MODE="0660"
KERNEL=="input[0-9]*", RUN+="/usr/local/bin/bluetooth-udev"
EOF
