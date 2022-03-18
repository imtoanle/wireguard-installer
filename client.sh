#!/bin/sh

apt-get update
apt-get upgrade -y
apt-get install wireguard -y

systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0
systemctl status wg-quick@wg0
