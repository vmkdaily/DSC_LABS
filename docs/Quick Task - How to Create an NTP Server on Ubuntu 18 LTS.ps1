# How to Create an NTP Server on Ubuntu 18 LTS

## Introduction
## In this demo we install chrony on Ubuntu 18 LTS to
## create an NTP Server for our lab.local domain.
## We modify the default time servers and add our own.

## Supporting Article

    https://help.ubuntu.com/lts/serverguide/NTP.html

## System Requirements
## You could get away with a tiny system for this, but I made mine
## 2 CPU and 4 GB RAM; Still on the small side as modern systems go.

## Check for system updates

    sudp apt -y update


## Install updates

    sudo apt -y upgrade


## Optional - Create a user
## Here, we create a user called "timesvc"

    sudo adduser timesvc

## Add to sudo
## If you created a user above, finish up with

    sudo usermod -aG sudo timesvc

## install chrony

    sudo apt install chrony

## Optional - list default time sources.

    chronyc sources

## show configuration file

    cat /etc/chrony/chrony.conf

## modify config

    sudo nano /etc/chrony/chrony.conf

## Example config changes
## Commented out the defaults and added 1 internal server
## The "iburst" makes it sync rapidly at startup. We use
## the "server" instead of "pool" when specifying our ntp
## server. Finally, there is no "maxsources" since that
## is for pools only.

    #defaults
    #pool ntp.ubuntu.com        iburst maxsources 4
    #pool 0.ubuntu.pool.ntp.org iburst maxsources 1
    #pool 1.ubuntu.pool.ntp.org iburst maxsources 1
    #pool 2.ubuntu.pool.ntp.org iburst maxsources 2

    #custom
    server 10.1.2.3 iburst

    #Allow clients from specified subnet (this allows 10.4.5.x)
    allow 10.4.5

# Note: See the following for more detail on the "allow" directive:
# https://chrony.tuxfamily.org/doc/3.4/chrony.conf.html

## restart chrony service

    sudo systemctl restart chrony.service

## Show updated time source(s)

    chronyc sources

## show stats

    sudo chronyc sourcestats

## Configure Ubuntu Firewall

    sudo apt-get install ufw
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow from 10.205.0.0/16 to any port 123
    sudo ufw enable

#Note: You cannot use 'telnet' to test port 123 against UBuntu; You must use a real ntp client to query your new NTP server.

## Command to test ntp from ESXi
## SSH to ESXi and run the following (host must be configured to talk to your time source already)

    watch ntpq -p localhost

## Summary
## This demo showed how to create an NTP server on Ubuntu 18 LTS.
## Also, we showed how to perform a quick test from ESXi to ensure
## the time source is working.

