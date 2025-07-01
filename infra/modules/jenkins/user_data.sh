#!/usr/bin/env bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update && apt-get dist-upgrade -y

# Core tools
apt-get install -y git jq unzip curl software-properties-common \
                   docker.io openjdk-17-jdk

systemctl enable --now docker
usermod -aG docker ubuntu          # default user

# Jenkins (stable repo)
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
  tee /usr/share/keyrings/jenkins.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins.asc] \
  https://pkg.jenkins.io/debian-stable binary/" \
  > /etc/apt/sources.list.d/jenkins.list
apt-get update && apt-get install -y jenkins
systemctl enable --now jenkins
usermod -aG docker jenkins

# AWS CLI v2
curl -Lo awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
unzip -q awscliv2.zip && sudo ./aws/install && rm -rf aws awscliv2.zip

# kubectl, eksctl, Terraform, Helm – exactly as in your original script
# (all curl installs remain the same; just drop the yum-specific lines)

mkdir -p /var/lib/jenkins/.kube
aws eks update-kubeconfig --name ${cluster_name} --region ${region}
chown -R jenkins:jenkins /var/lib/jenkins/.kube

# Install dependencies
sudo apt update && sudo apt install -y curl

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verify kubectl installation
kubectl version --client