#!/usr/bin/env bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# Update and upgrade the system
apt-get update && apt-get dist-upgrade -y

# Install core tools
apt-get install -y git jq unzip curl software-properties-common \
                   docker.io openjdk-17-jdk

# Enable and start Docker
systemctl enable --now docker

# Add the default user and Jenkins user to the Docker group
usermod -aG docker ubuntu
usermod -aG docker jenkins || true  # Jenkins user may not exist yet

# Install Jenkins (stable repo)
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
  tee /usr/share/keyrings/jenkins.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins.asc] \
  https://pkg.jenkins.io/debian-stable binary/" \
  > /etc/apt/sources.list.d/jenkins.list
apt-get update && apt-get install -y jenkins
systemctl enable --now jenkins

# Re-add Jenkins user to Docker group after Jenkins installation
usermod -aG docker jenkins
systemctl restart jenkins

# Install AWS CLI v2
curl -Lo awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
unzip -q awscliv2.zip && sudo ./aws/install && rm -rf aws awscliv2.zip

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client

# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version

# Install Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform
terraform version

# Install Helm
snap install helm --classic
helm version

# Install Trivy
apt-get install -y wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt update && sudo apt install -y trivy
trivy --version

# Configure kubectl for Jenkins
mkdir -p /var/lib/jenkins/.kube
chown -R jenkins:jenkins /var/lib/jenkins/.kube
chmod 700 /var/lib/jenkins/.kube
aws eks update-kubeconfig --name ${cluster_name} --region ${region}