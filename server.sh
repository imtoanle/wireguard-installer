#!/bin/sh

apt-get update
#apt-get upgrade -y
apt-get install wireguard -y
cd /etc/wireguard/
umask 077
wg genkey | tee server_privatekey | wg pubkey > server_publickey
wg genkey | tee client_privatekey | wg pubkey > client_publickey

cat >> /etc/wireguard/wg0.conf << EOF
[Interface]
## My VPN server private IP address ##
Address = 192.168.6.1/24

## My VPN server port ##
ListenPort = 41194

PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o enp1s0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o enp1s0 -j MASQUERADE

## VPN server's private key i.e. /etc/wireguard/privatekey ##
PrivateKey = $(cat server_privatekey)

[Peer]
PublicKey = $(cat client_publickey)
AllowedIPs = 192.168.6.2/32
EOF

cat >> /etc/wireguard/client_wg0.conf << EOF
[Interface]
PrivateKey = $(cat client_privatekey)
Address = 192.168.6.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = $(cat server_publickey)
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = $(dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | tr -d '"'):41194
PersistentKeepalive = 25
EOF

# Enable firewall
sysctl -w net.ipv4.ip_forward=1
sed -i 's,#net.ipv4.ip_forward=1,net.ipv4.ip_forward=1,g' /etc/sysctl.conf
ufw allow 41194/udp

systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0
systemctl status wg-quick@wg0

echo ---------------
cat client_wg0.conf

