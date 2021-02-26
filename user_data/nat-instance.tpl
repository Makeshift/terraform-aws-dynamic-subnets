#!/bin/bash
script_name="nat-instance.tpl"
echo -e "\e[33m####################\e[39m\e[45mSTARTING USERDATA SCRIPT \e[44m$script_name\e[49m\e[33m####################\e[39m"

apt-get update -y
apt-get upgrade -y

default_interface=$(ip route get 1.1.1.1 | grep -Po "(?<=(dev )).*(?= src| proto)")

# Set NAT instance defaults
echo "# Maximize console logging level for kernel printk messages
kernel.printk = 8 4 1 7
kernel.printk_ratelimit_burst = 10
kernel.printk_ratelimit = 5

# Wait 30 seconds and then reboot
kernel.panic = 30

# Allow neighbor cache entries to expire even when the cache is not full
net.ipv4.neigh.default.gc_thresh1 = 0
net.ipv6.neigh.default.gc_thresh1 = 0

# Avoid neighbor table contention in large subnets
net.ipv4.neigh.default.gc_thresh2 = 15360
net.ipv6.neigh.default.gc_thresh2 = 15360
net.ipv4.neigh.default.gc_thresh3 = 16384
net.ipv6.neigh.default.gc_thresh3 = 16384
" | tee /etc/sysctl.d/00-defaults.conf

# Set specific sysctl settings for NAT instance
echo "#
# NAT AMI settings
#

net.ipv4.ip_forward = 1
net.ipv4.conf.$default_interface.send_redirects = 0
" | tee /etc/sysctl.d/10-nat-settings.conf

# Reload sysctl
sysctl --system

# To run on each startup for PAT
echo $'#!/bin/bash
# Configure the instance to run as a Port Address Translator (PAT) to provide
# Internet connectivity to private instances.

function log { logger -s -t "vpc" -- $1; }

function die {
    [ -n "$1" ] && log "$1"
    log "Configuration of PAT failed!"
    exit 1
}

# Sanitize PATH
export PATH="/usr/sbin:/sbin:/usr/bin:/bin"

# Get default interface
default_interface=$(ip route get 1.1.1.1 | grep -Po "(?<=(dev )).*(?= src| proto)")
echo "Default interface set to: $default_interface"

log "Determining the MAC address on $default_interface..."
ETH0_MAC=$(cat /sys/class/net/$default_interface/address) ||
    die "Unable to determine MAC address on eth0."
log "Found MAC $ETH0_MAC for $default_interface."

# This script is intended to run only on a NAT instance for a VPC
# Check if the instance is a VPC instance by trying to retrieve vpc id
VPC_ID_URI="http://169.254.169.254/latest/meta-data/network/interfaces/macs/$ETH0_MAC/vpc-id"

VPC_ID=$(curl --retry 3 --silent --fail $VPC_ID_URI)
if [ $? -ne 0 ]; then
   log "The script is not running on a VPC instance. PAT may masquerade traffic for Internet hosts!"
fi

log "Enabling PAT..."
sysctl -q -w net.ipv4.ip_forward=1 net.ipv4.conf.$default_interface.send_redirects=0
iptables -t nat -A POSTROUTING -o $default_interface -j MASQUERADE
iptables -I DOCKER-USER -i $default_interface -o $default_interface -j ACCEPT || die

sysctl net.ipv4.ip_forward net.ipv4.conf.$default_interface.send_redirects | log
iptables -n -t nat -L POSTROUTING | log
iptables -n -L DOCKER-USER | log

log "Adding self to hosts"
echo "127.0.0.1 $(hostname)" >> /etc/hosts

log "Configuration of PAT complete."

log "Starting takeover of routing for this subnet"
INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
# Get the EIP I should have
EIP_ID=$(/usr/bin/aws --region ${region} ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" | jq -r \'.Tags | .[] | select(.Key | contains("eip")) | .Value\')
# Get the route table I should manage
ROUTE_TABLE_ID=$(/usr/bin/aws --region ${region} ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" | jq -r \'.Tags | .[] | select(.Key | contains("route_table")) | .Value\')
# Attach route table to EIP (if it isnt already)
/usr/bin/aws --region ${region} ec2 delete-route --destination-cidr-block 0.0.0.0/0 --route-table-id "$ROUTE_TABLE_ID" || true
/usr/bin/aws --region ${region} ec2 create-route --destination-cidr-block 0.0.0.0/0 --instance-id "$INSTANCE_ID" --route-table-id "$ROUTE_TABLE_ID"
# Attach EIP to me
/usr/bin/aws --region ${region} ec2 associate-address --instance-id "$INSTANCE_ID" --allow-reassociation --allocation-id "$EIP_ID"
# Remove the source/destination check to allow for actual NAT-ness to happen
/usr/bin/aws --region ${region} ec2 modify-instance-attribute --instance-id "$INSTANCE_ID" --no-source-dest-check
# I am the captain now (The captain of routing anyway)
exit 0
' | tee /usr/sbin/configure-pat.sh
chmod 755 /usr/sbin/configure-pat.sh

echo "[Unit]
Description=Set up NAT

[Service]
Type=oneshot
ExecStart=/bin/bash /usr/sbin/configure-pat.sh

[Install]
WantedBy=multi-user.target
" | tee /etc/systemd/system/nat.service

systemctl enable nat.service
systemctl start nat.service
systemctl status nat.service || true

echo -e "\e[94m####################\e[39m\e[104mENDING USERDATA SCRIPT \e[47m\e[36m$script_name\e[49m\e[94m####################\e[39m"
