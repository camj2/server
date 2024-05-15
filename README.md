# server

Consider these the server dotfiles. :)

Related:

* Raspberry Pi 3/4/5
* Void Linux (musl)
* ZFS
* Unbound
* Wireguard
* [Duck DNS](https://www.duckdns.org/)

## Prerequisites

### Raspberry Pi 4/5

https://github.com/raspberrypi/rpi-eeprom/releases/latest

### Raspberry Pi 3

Depending on the board revision, you may need to clone the live USB boot partition to an SD card in order to boot via USB.

### QEMU

```
xbps-install -Su qemu-user-static binfmt-support

ln -s /etc/sv/binfmt-support /var/service/
```

Check:

```
grep binfmt_misc /proc/mounts
```

This is needed when creating the live USB.
This allows an x86_64 host to chroot into a non x86_64 platform, such as aarch64.

Alternatively you could download Void Linux and setup the USB drive yourself:

https://voidlinux.org/download/#arm%20platforms

If you do, make sure to copy `./rootfs` and `./server` to the USB drive.
They will be needed later.

## Configuration

### Wireguard

#### Proxy

Make sure your network isn't behind a proxy:

https://ipv4.amibehindaproxy.com/

Otherwise you may need to use [cloudflared](https://github.com/cloudflare/cloudflared).

#### Port forward

Forward UDP port `51820` to the ip address you want to use for your server.

https://portforward.com/

#### Duck DNS

https://www.duckdns.org/

Create an account and add your token/subdomain to:

```
rootfs/etc/cron.hourly/duckdns
```

Set perms:

```
chmod 700 rootfs/etc/cron.hourly/duckdns
```

Learn more: https://www.duckdns.org/about.jsp

#### Peers

<!-- https://techoverflow.net/2021/07/09/what-does-wireguard-allowedips-actually-do/ -->

Generate your peers using `wg-gen`:

```
./tools/wg-gen <peer_total> <subdomain>
```

You can generate between 1-253 peers.
Make sure to use the same subdomain you added to `rootfs/etc/cron.hourly/duckdns`.

Peers are saved to `./wireguard`.
Feel free to edit them how you see fit.

Consider adding `PersistentKeepalive = 25` to any peers that are going to be behind a NAT.
This is not required however.

Move the server peer into the rootfs directory:

```
mv wireguard/1-server.conf rootfs/etc/wireguard/wg0.conf
```

Set perms:

```
chmod 700 rootfs/etc/wireguard
```

### Unbound

<!-- https://github.com/pi-hole/pi-hole/blob/60b6a1016c7f39e1db8359fc5874ae35d8c27ff9/gravity.sh#L635-L664 -->

Unbound can block ads standalone. No need for [Pi-hole](https://pi-hole.net/)!

Generate the blocklist using `unbound-deny-gen`:

```
./tools/unbound-deny-gen
```

Make sure the blocklist is under 500k domains.
Too many domains can impact performance.
Check with:

```
wc -l < deny.conf
```

Move the blocklist into the rootfs directory:

```
mv deny.conf rootfs/etc/unbound/
```

#### Wireguard

Consider adding the ip addresses of your peers to `rootfs/etc/unbound/wireguard.conf`.

Example:

```
local-data: "server A 10.1.1.1"
local-data: "phone A 10.1.1.2"
local-data: "laptop A 10.1.1.3"
local-data: "computer A 10.1.1.4"
```

This makes it easy to ssh between your peers:

```
ssh laptop # connect to 10.1.1.3
```

### SSH

Add your keys to:

```
rootfs/home/server/.ssh/authorized_keys
```

This is required as password authentication is disabled by the install script.

## Installation

### USB

First step is to create the live USB.
Use the `usb` install script to create the live USB:

**Warning**: This will completely wipe the USB drive!

Usage:

```
./usb <zoneinfo> <ip_address_router> <ip_address> <usb_drive>
```

Example:

```
./usb /usr/share/zoneinfo/UTC 10.0.0.1 10.0.0.2 /dev/disk/by-id/<usb_drive>
```

`10.0.0.1` being the ip address of your router and
`10.0.0.2` being the ip address you want to use for your server.

Once completed, boot the Pi and connect via SSH:

```
ssh root@<ip_address> # password: voidlinux
```

### Server

Check `date` until the clock is correct.

Once correct, use the `server` install script to create the server:

**Warning**: This will completely wipe the SD card!

Usage:

```
./server <zoneinfo> <ip_address_router> <ip_address> <sd_card>
```

Example:

```
./server /usr/share/zoneinfo/UTC 10.0.0.1 10.0.0.2 /dev/disk/by-id/<sd_card>
```

This can take a while since the ZFS DKMS driver needs to be compiled twice.

Once installation is complete, reboot the Pi and remove the live USB.

## Notes

### ZFS

You can "factory reset" the server at anytime using the base snapshots created at install:

**Warning**: This will wipe all data from the server!

```
zfs rollback -R server/root@base
zfs rollback -R server/home@base

reboot
```

### Wireguard

Check with:

```
wg
```

### Unbound

You can use [dnscheck.tools](https://dnscheck.tools/) to test Unbound.
This should print the name of your internet service provider.

Check which nameserver is being used with:

```
dig google.com
```

## LICENSE

MIT
