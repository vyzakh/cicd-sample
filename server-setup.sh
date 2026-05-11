#!/bin/bash
# ─────────────────────────────────────────────────────────────
# server-setup.sh
# Run this ONCE on your EC2 / VPS to prepare it for deployments
# Usage: bash server-setup.sh
# ─────────────────────────────────────────────────────────────

set -e

echo "=== [1/4] Installing Docker ==="
sudo apt-get update -y
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

# Allow current user to run docker without sudo
sudo usermod -aG docker $USER
echo "Docker installed ✓"

echo ""
echo "=== [2/4] Installing AWS CLI ==="
sudo apt-get install -y awscli
aws --version
echo "AWS CLI installed ✓"

echo ""
echo "=== [3/4] Configure AWS credentials ==="
echo "Two options:"
echo ""
echo "  OPTION A (recommended for EC2): Attach an IAM Role to the EC2 instance"
echo "    → Go to EC2 console → Instance → Actions → Security → Modify IAM role"
echo "    → Attach a role with AmazonEC2ContainerRegistryReadOnly policy"
echo "    → No credentials needed on the server"
echo ""
echo "  OPTION B (any server): Set credentials manually"
echo "    Run: aws configure"
echo "    Enter: AWS Access Key ID, Secret, Region, output format"
echo ""
read -p "Press Enter to run 'aws configure' now, or Ctrl+C to skip and use IAM role..."
aws configure

echo ""
echo "=== [4/4] Verify Docker & AWS ==="
docker --version
aws sts get-caller-identity

echo ""
echo "✅ Server setup complete!"
echo ""
echo "Next steps:"
echo "  1. Add GitHub Secrets to your repo (see README.md)"
echo "  2. Push to main branch to trigger your first deployment"
echo "  3. Visit http://$(curl -s ifconfig.me) to see your app"
