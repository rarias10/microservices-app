#!/bin/bash
# EC2 Security Hardening Script

set -e

echo "🔒 Applying security hardening..."

# Update system
sudo yum update -y

# Install fail2ban
sudo yum install -y epel-release
sudo yum install -y fail2ban

# Configure fail2ban
sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
logpath = /var/log/secure
maxretry = 3
EOF

sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Secure Docker daemon
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true
}
EOF

sudo systemctl restart docker

# Set up firewall rules
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --remove-service=ssh
sudo firewall-cmd --permanent --add-port=22/tcp --source=YOUR_IP_HERE
sudo firewall-cmd --reload

echo "✅ Security hardening complete!"
echo "⚠️  Remember to:"
echo "1. Change YOUR_IP_HERE to your actual IP"
echo "2. Generate strong secrets for .env.production"
echo "3. Set up SSL certificates"