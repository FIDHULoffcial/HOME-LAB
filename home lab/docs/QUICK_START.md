# 🚀 AndroidLab — Quick Start Guide

Get your Android phone server running in under 30 minutes.

## Prerequisites

- Android phone (5.0+, 2GB+ RAM)
- F-Droid app store installed ([f-droid.org](https://f-droid.org))
- Both phone and laptop on the same Wi-Fi

## Step 1: Install Apps (5 min)

1. Install **F-Droid** from [f-droid.org](https://f-droid.org)
2. Open F-Droid → search **Termux** → Install
3. Search **Termux:Boot** → Install
4. Open **Termux:Boot** once (then close it)
5. Open **Termux**

## Step 2: Grant Permissions (2 min)

```bash
# Inside Termux:
termux-setup-storage
```

Then go to **Settings → Battery → Termux** → Set to "Unrestricted"

## Step 3: Clone & Run Setup (15 min)

```bash
# Update packages first
pkg update -y && pkg upgrade -y

# Install git
pkg install -y git

# Clone this repo
git clone https://github.com/yourusername/androidlab.git ~/androidlab

# Run the setup script
bash ~/androidlab/scripts/setup.sh
```

## Step 4: Set Password & Start (2 min)

```bash
# Set your SSH password
passwd

# Start all services
server start

# Check status
server status

# Get your IP
myip
```

## Step 5: Connect from Laptop (1 min)

```bash
# From your laptop terminal:
ssh -p 8022 YOUR_PHONE_IP

# Example:
ssh -p 8022 192.168.1.100
```

## You're Done! 🎉

Your phone is now a server with:
- **SSH** on port 8022
- **Nginx** on port 8080
- **FileBrowser** on port 8081
- **Python API** on port 5000
- **MariaDB** on port 3306

## Next Steps

- Read the full [README](../README.md) for all 13 phases
- Set up [SSH key authentication](../README.md#step-38--set-up-ssh-key-authentication-strongly-recommended) for password-free login
- Configure [Cloudflare Tunnel](../README.md#-phase-11--remote-internet-access-cloudflare-tunnel) for internet access
- Review the [Security Guide](SECURITY.md)
