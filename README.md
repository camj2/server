# server

Void Linux based Unbound Wireguard server for Raspberry Pi.

Related:

* Raspberry Pi 3/4/5
* Void Linux (musl)
* XFS
* Unbound
* Wireguard
* [Cloudflare](https://www.cloudflare.com/)

## Pre

### Raspberry Pi 4/5

https://github.com/raspberrypi/rpi-eeprom/releases/latest

### Raspberry Pi 3

Note: Depending on the board revision,
you may need to clone the live USB boot partition to an SD card in order to boot via USB.

### QEMU

```
xbps-install qemu-user-static binfmt-support

ln -s /etc/sv/binfmt-support /var/service/
```

This is needed when creating the live USB.

## Configuration

### Wireguard

https://portforward.com/

https://ipv4.amibehindaproxy.com/

<!-- https://github.com/onemarcfifty/cheat-sheets/blob/main/networking/ipv6.md -->

<!-- https://techoverflow.net/2021/07/09/what-does-wireguard-allowedips-actually-do/ -->

Use [`cloudflared`](https://github.com/cloudflare/cloudflared)
instead of `inadyn` if your network is behind a proxy.

<br>

<!-- https://www.namecheap.com/ -->

<!-- https://developers.cloudflare.com/dns/dnssec/#enable-dnssec -->

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

<br>

Generate your wireguard peers with the provided [`wg-gen`](#wg-gen) script:

```
./utils/wg-gen -e <subdomain>.<domain>:<port> phone laptop computer backup
```

Add the wireguard config:

```
install -d -m 700 rootfs/etc/wireguard
ln -f wireguard/1-server.conf rootfs/etc/wireguard/wg0.conf
```

Add the unbound config:

```
ln -f wireguard/unbound.conf rootfs/etc/unbound.conf.d/wireguard.conf
```

You can add the wireguard config to your phone with:

```
xdg-open wireguard/2-phone.png
```

Then copy the rest of the wireguard config files to `/etc/wireguard` on your respective systems.

<br>

Example `/etc/unbound.conf.d/wireguard.conf` file:

```
local-data: "server   AAAA fd87:9b28:1e2f:b635::1"
local-data: "phone    AAAA fd87:9b28:1e2f:b635::2"
local-data: "laptop   AAAA fd87:9b28:1e2f:b635::3"
local-data: "computer AAAA fd87:9b28:1e2f:b635::4"
local-data: "backup   AAAA fd87:9b28:1e2f:b635::5"
```

<!-- `dig +short server AAAA` -->

This essentially creates a roaming network and allows for easy access between your devices:

Very useful when used in conjunction with `rsync`:

```
rsync -aAXH --delete ~/ laptop:~/ # sync laptop with computer
```

### Unbound

<!-- https://github.com/pi-hole/pi-hole/blob/60b6a1016c7f39e1db8359fc5874ae35d8c27ff9/gravity.sh#L635-L664 -->

Unbound can block ads standalone. No need for [Pi-hole](https://pi-hole.net/)!

Generate the blocklist with the provided `unbound-deny-gen` script:

```
./utils/unbound-deny-gen
```

Make sure the blocklist is under 500k domains.
Too many domains can impact performance.
Check with:

```
wc -l < deny.conf
```

Add the unbound config:

```
ln -f deny.conf rootfs/etc/unbound.conf.d/
```

### SSH

Add your keys to `rootfs/home/server/.ssh/authorized_keys`.
**This is required to login**.

Also make sure the correct bits are set:

```
chmod 700 rootfs/home/server rootfs/home/server/.ssh
```

<br>

Add the following to `~/.ssh/config`: (optional)

```
Host server
User server
```

This sets the username when connecting via ssh:

```
ssh server
```

## Install

### USB

**Warning**: This will completely wipe the USB drive!

```
./usb /dev/<usb_drive>
```

### Server

Password: `voidlinux`

Check `date` until the clock is correct.

**Warning**: This will completely wipe the SD card!

```
./server /dev/mmcblk0
```

## Notes

### DHCP

Make sure to set a static ip address for your server in your router interface.

### Update

```
xbps-install -Syu

xbps-remove -yo
xbps-remove -yO
```

### Unbound

Check with:

```
dig cloudflare.com A
dig cloudflare.com AAAA
```

https://dnscheck.tools/

<!-- https://www.dnsleaktest.com/ -->

<!-- https://www.speedtest.net/apps/cli -->

### Wireguard

Check handshake:

```
wg
```

Check endpoint:

```
dig <subdomain>.<domain>
```

### Password

Set a password if you plan on using a display and keyboard:

```
passwd server
```

### Docker

Install Home Assistant:

```
xbps-install docker

ln -s /etc/sv/docker /var/service/

usermod -a -G docker server

mkdir -p -m 700 /home-assistant

docker run -d \
  --privileged \
  --network host \
  --name home-assistant \
  --restart unless-stopped \
  -e TZ=UTC \
  -v /home-assistant:/config \
  ghcr.io/home-assistant/home-assistant:stable
```

Configure Home Assistant:

`/home-assistant/configuration.yaml`:

```
http:
  server_port: 80
```

Restart Home Assistant:

```
docker container restart home-assistant
```

## `wg-gen`

### Flags

`-o <dir>`: output (default: `./wireguard`)

`-e <host>:<port>`: endpoint (required)

`-p <port>`: listening port (default: `51820`)

`-P <prefix>`: [IPv6 ULA 64-bit prefix](https://www.unique-local-ipv6.com/) (default: random)

`-g`: generate prefix (debug)

### Flags (peer specific)

`-e <host>:<port>`: override the endpoint given above

`-s <host>:<port>`: peer endpoint (optional)

`-p <port>`: listening port (ignored without `-s`, default: `51820`)

`-k <int>`: keepalive (recommended value: `25`)

### Usage

```
wg-gen -e wg.test.com:443 \
  phone \
  laptop \
    -k 25 \
  computer \
    -e 10.0.0.2:51820 \
    -s 10.0.0.4:51820 \
  backup \
    -e 10.0.0.2:51820 \
    -s 10.0.0.3:51820
```

#### Many

```
wg-gen -e wg.test.com:443 $(seq 100)
```

## LICENSE

MIT
