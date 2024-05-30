# server

Void Linux based Unbound Wireguard server for Raspberry Pi.

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

Note: Depending on the board revision,
you may need to clone the live USB boot partition to an SD card in order to boot via USB.

### QEMU

```
xbps-install -Syu qemu-user-static binfmt-support

ln -sf /etc/sv/binfmt-support /var/service/
```

This is needed when creating the live USB.

## Configuration

### Wireguard

https://portforward.com/

https://ipv4.amibehindaproxy.com/

<!-- https://github.com/cloudflare/cloudflared -->

<!-- https://www.duckdns.org/ -->

<!-- https://www.duckdns.org/about.jsp -->

<!-- https://techoverflow.net/2021/07/09/what-does-wireguard-allowedips-actually-do/ -->

#### DDNS

Create an [account](https://www.duckdns.org/) and add your token/subdomain to:

```
rootfs/etc/cron.hourly/duckdns
```

#### Peers

<!-- PersistentKeepalive = 25 -->

<!-- ListenPort = 51820 -->

<!-- Endpoint -->

Generate peers:

```
./tools/wg-gen <peer_total> <subdomain>
```

Add to rootfs:

```
cp -f wireguard/1-server.conf rootfs/etc/wireguard/wg0.conf

chmod 700 rootfs/etc/wireguard
```

### Unbound

<!-- https://github.com/pi-hole/pi-hole/blob/60b6a1016c7f39e1db8359fc5874ae35d8c27ff9/gravity.sh#L635-L664 -->

Unbound can block ads standalone. No need for [Pi-hole](https://pi-hole.net/)!

Generate the blocklist:

```
./tools/unbound-deny-gen
```

Make sure the blocklist is under 500k domains.
Too many domains can impact performance.
Check with:

```
wc -l < deny.conf
```

Add to rootfs:

```
mv -f deny.conf rootfs/etc/unbound/unbound.conf.d/
```

#### Wireguard

Consider adding the ip addresses of your peers to `rootfs/etc/unbound/wireguard.conf`:

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

## Installation

### USB

**Warning**: This will completely wipe the USB drive!

```
./usb <default_route> <ip_address> /usr/share/zoneinfo/<timezone> /dev/disk/by-id/<usb_drive>
```

### Server

Password: `voidlinux`

Check `date` until the clock is correct.

**Warning**: This will completely wipe the SD card!

```
./server-zfs <default_route> <ip_address> /usr/share/zoneinfo/<timezone> /dev/disk/by-id/<sd_card>
```

## Notes

### ZFS

You can "factory reset" the server at anytime using the base snapshots created at install:

**Warning**: This will wipe all data from your server!

```
zfs rollback -R server/root@base
zfs rollback -R server/home@base

reboot
```

### Unbound

You can use [dnscheck.tools](https://dnscheck.tools/) to test Unbound.
This should print the name of your internet service provider.

Check which nameserver is being used with:

```
dig google.com
```

### Wireguard

Check handshake:

```
wg
```

Check endpoint:

```
dig <subdomain>.duckdns.org
```

## LICENSE

MIT
