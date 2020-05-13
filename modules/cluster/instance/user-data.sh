#!/bin/bash
sudo yum -y update
sudo yum -y install jq
mkdir ~/downloads
wget -O ~/downloads/terraform.zip https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip
wget -O ~/downloads/atlantis.zip https://github.com/runatlantis/atlantis/releases/download/v0.12.0/atlantis_linux_386.zip
sudo unzip ~/downloads/terraform.zip -d /usr/local/bin/
sudo unzip ~/downloads/atlantis.zip -d /usr/local/bin/
rm -rf ~/downloads/
sudo yum -y clean all
sudo rm -rf /var/cache/yum