#!/bin/bash
sudo apt-get update -y
sudo apt-get  upgrade -y
echo "127.0.0.1 $HOSTNAME" | sudo tee -a   /etc/hosts
echo 'export PS1="\[\033[0;34m\][\u:\h\[\033[0;35m\]:\w]\[\033[0;39m\]\n\[\033[0;33m\]\342\226\210\342\226\210\[\033[0;39m\]"' >> /home/ubuntu/.bashrc
sudo sysctl net.ipv4.ip_forward=1
sudo iptables -t nat -A PREROUTING -p tcp --dport 8951  -j DNAT --to-destination ${ip}:80
sudo iptables -t nat -A POSTROUTING -j MASQUERADE
