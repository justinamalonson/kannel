#!/bin/bash

# Update package list and install necessary packages
sudo apt update
sudo apt install -y build-essential libxml2-dev libssl-dev libcurl4-openssl-dev

# Download and extract Kannel source code
wget http://www.kannel.org/download/1.4.5/gateway-1.4.5.tar.gz --no-check-certificate
tar -xzf gateway-1.4.5.tar.gz
cd gateway-1.4.5

# Compile and install Kannel
./configure
make
sudo make install

# Create Kannel configuration file
sudo tee /etc/kannel/kannel.conf <<EOL
group = core
admin-port = 13000
smsbox-port = 13001
log-file = "/var/log/kannel/kannel.log"
log-level = 0

group = smsbox
smsbox-id = 1
bearerbox-host = localhost
sendsms-port = 13013

group = smsc
smsc-id = smpp
smsc = smpp
host = localhost
port = 2775
smsc-username = your_username
smsc-password = your_password
EOL

# Create log directory for Kannel
sudo mkdir -p /var/log/kannel
sudo chown -R $(whoami):$(whoami) /var/log/kannel

# Start Kannel
sudo /usr/local/sbin/bearerbox /etc/kannel/kannel.conf

# Configure FreeSwitch to connect to Kannel
sudo tee /etc/freeswitch/sip_profiles/external/kannel.xml <<EOL
<include>
  <gateway name="kannel_gateway">
    <param name="realm" value="localhost"/>
    <param name="username" value="your_username"/>
    <param name="password" value="your_password"/>
    <param name="register" value="true"/>
  </gateway>
</include>
EOL

# Restart FreeSwitch to apply changes
sudo systemctl restart freeswitch

echo "Kannel installation and configuration complete."
