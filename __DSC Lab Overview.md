## The DSC Lab
Welcome to `DSC_LABS`. This document describes the overview of required components.
You can adjust your network and names as needed.

This document is written in markdown (`.md`) but note that most of the docs are `.ps1` files.

## About this document
We do not read-in this document or any data hereinbelow; The networks and names are shown for illustration.

## Edit LAB_OPTIONS.ps1
To make changes to the vm names or IP Addresses, edit the `LAB_OPTIONS.ps1` file.

    ise "C:\DSC_LABS\vmw\LAB_OPTIONS.ps1"

> Note: All examples use the Microsoft ISE for editing and running demo scripts

## Domain name
The domain we create is `lab.local`

    lab.local

## Network
For guest networking, we start as a `/16` when deploying with VMware, but then become `/8` with `dsc`.
You can adjust both if needed.

    10.205.0.0
    
## Optional - Login to vc

    administrator@vsphere.local
    https://myvcname

## Upstream routing
We expect that you will be able to route from lab to your production by IP Address. However, the intention is never to do that of course. As such, there should be no name resolution to upstream (see next item) once inside lab.local.

## Upstream name resolution
Except during build time, we should not consume DNS from a production network. We deploy lab.local domain controllers and consume DNS from there. When managing a guest before it has joined the domain, you may consider using a local or nearby production dns if that is appropriate. If on a home network, just use google dns `8.8.8.8` when setting up your `LAB_OPTIONS.ps1`.

## Proxy Server requirements for remote nodes
We go over an example to set the Internet Explorer (IE) proxy for your dsc test nodes to use when accessing the PowerShell Gallery (optional). The other choice is to use `Copy-Item` to add resources to our target nodes. That is detailed as well.

## IP Address range
The examples use the following range of IP Addresses:

    10.205.1.150
    to
    10.205.1.160
    
## Required virtual machines (dsc infrastructure)
These are example virtual machines, but are exactly the ones we will deploy.
You can change the names and layout if desired, just edit the `LAB_OPTIONS.ps1` script.

    dscjump01       10.205.1.150
    dc01            10.205.1.151
    dc02            10.205.1.152
    cert01          10.205.1.153
    dscpull01       10.205.1.154

## Test machines we deploy
Once we have dsc up and running, we can deploy and re-deploy these nodes for testing.

    s1              10.205.1.155 (i.e. Windows Server 2012 R2)
    s2              10.205.1.156 (i.e. Windows Server 2016)
    Linux01         10.205.1.157 (i.e. Ubuntu 16.04)
    Linux02         10.205.1.158 (i.e. CentOS 7)

## Templates
No templates are needed for Linux; However, we require at least one Windows template.

## Linx and omi
For Linux, you can deploy from ISO or your own template as desired (`New-LabVM` is only Windows). Once you have a Linux guest online and reachable, you can manage it with `omi` and `dsc`.

-end-

