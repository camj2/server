# server

Void Linux based Unbound Wireguard server for Raspberry Pi.

Related:

* Raspberry Pi 3/4/5
* Void Linux (musl)
* ZFS
* Unbound
* Wireguard
* [Cloudflare](https://www.cloudflare.com/)

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

<!-- https://www.reddit.com/r/voidlinux/comments/q6t7o1/a_home_router_built_on_void_linux_and_zfsbootmenu/ -->

<!-- https://wiki.nftables.org/wiki-nftables/index.php/Main_Page#Examples -->

### Wireguard

https://portforward.com/

https://ipv4.amibehindaproxy.com/

<!-- https://techoverflow.net/2021/07/09/what-does-wireguard-allowedips-actually-do/ -->

Use [`cloudflared`](https://github.com/cloudflare/cloudflared)
instead of `inadyn` if your network is behind a proxy.

#### DDNS

<!-- https://www.namecheap.com/ -->

<!-- https://www.cloudflare.com/ -->

<!-- https://developers.cloudflare.com/dns/dnssec/#enable-dnssec -->

<!-- https://github.com/troglobit/inadyn -->

Create a new subdomain for your server and create an `inadyn` configuration file:

`rootfs/etc/inadyn.conf`:

```
period = 3600
user-agent = Mozilla/5.0

provider cloudflare.com {
    username = <domain>
    password = <token>
    hostname = <subdomain>.<domain>
    ttl = 1
    proxied = false
}
```

<!-- Create an [account](https://www.duckdns.org/) and add your token/subdomain to:

```
rootfs/etc/cron.hourly/duckdns
``` -->

#### Peers

<!-- PersistentKeepalive = 25 -->

<!-- ListenPort = 51820 -->

<!-- Endpoint -->

Generate:

<!-- https://en.wikipedia.org/wiki/Reserved_IP_addresses -->

<!-- https://unique-local-ipv6.com/ -->

<!-- https://www.ibm.com/docs/en/ts3500-tape-library?topic=formats-subnet-masks-ipv4-prefixes-ipv6#d78581e83 -->

```
./tools/wg-gen -h # usage

./tools/wg-gen -ru -t <peer_total> <endpoint>
```

<!-- Shared:

```
./tools/wg-gen -t <peer_total> -p 51821 <endpoint>
``` -->

Add:

```
cp -f wireguard/1-server.conf rootfs/etc/wireguard/wg0.conf

cp -f wireguard/0-unbound.conf rootfs/etc/unbound/unbound.conf.d/wireguard.conf # wireguard peers
```

Make sure to edit `wireguard.conf` and add the names of all your peers:

```
local-data: "server AAAA fd87:9b28:1e2f:b635::1"
local-data: "phone AAAA fd87:9b28:1e2f:b635::2"
local-data: "laptop AAAA fd87:9b28:1e2f:b635::3"
local-data: "computer AAAA fd87:9b28:1e2f:b635::4"
local-data: "backup AAAA fd87:9b28:1e2f:b635::5"
```

<!-- local-data-ptr: "fd87:9b28:1e2f:b635::1 server" -->
<!-- private-domain: server -->

Test:

```
dig +short server AAAA
```

This makes it easy to ssh between your peers:

```
ssh server@server # fd87:9b28:1e2f:b635::1

ssh laptop # fd87:9b28:1e2f:b635::3
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

Add:

```
mv -f deny.conf rootfs/etc/unbound/unbound.conf.d/
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

<!-- default_route = router ipv4 address -->
<!-- ip_address = server ipv4 address -->

### Server

Password: `voidlinux`

Check `date` until the clock is correct.

**Warning**: This will completely wipe the SD card!

```
./server-zfs <default_route> <ip_address> /usr/share/zoneinfo/<timezone> /dev/disk/by-id/<sd_card>
```

<!-- default_route = router ipv4 address -->
<!-- ip_address = server ipv4 address -->

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

Check with:

```
dig @server google.com
```

Check DNSSEC with:

```
dig fail01.dnssec.works @server -p 53 # SERVFAIL
dig dnssec.works @server -p 53 # NOERROR
```

https://dnscheck.tools/

### Wireguard

Check handshake:

```
wg
```

Check endpoint:

```
dig <subdomain>.duckdns.org
```

### Password

```
passwd server # optional
```

## LICENSE

MIT
