#!/bin/bash
sudo yum -y update
sudo yum -y install git

mkdir ~/downloads
wget -O ~/downloads/terraform.zip https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip
wget -O ~/downloads/atlantis.zip https://github.com/runatlantis/atlantis/releases/download/v0.12.0/atlantis_linux_386.zip
sudo unzip -o ~/downloads/terraform.zip -d /usr/local/bin/
sudo unzip -o ~/downloads/atlantis.zip -d /usr/local/bin/
sudo rm -rf ~/downloads/

export URL=${url}
export USERNAME=${username}
export TOKEN=${token}
export SECRET=${webhook_secret}
export REPO_WHITELIST=${repo_whitelist}

echo "{
  \"name\": \"web\",
  \"active\": true,
  \"events\": [
    \"issue_comment\",
    \"pull_request\",
    \"pull_request_review\",
    \"push\"
  ],
  \"config\": {
    \"content_type\": \"json\",
    \"insecure_ssl\": \"0\",
    \"secret\": \"$SECRET\",
    \"url\": \"$URL\"
  }
}"  > data.json

curl -X POST \
-u $USERNAME:$TOKEN \
-H "Content-Type: application/json" \
-d @data.json \
https://api.github.com/repos/baranovRP/tf-aws-rnbv-complex/hooks

sudo yum -y clean all
sudo rm -rf /var/cache/yum

atlantis server \
--atlantis-url="$URL" \
--gh-user="$USERNAME" \
--gh-token="$TOKEN" \
--gh-webhook-secret="$SECRET" \
--repo-whitelist="$REPO_WHITELIST" &> /tmp/atlantis-server.log &
