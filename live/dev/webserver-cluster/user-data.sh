#!/bin/bash
sudo yum -y update
sudo yum -y install git
sudo yum -y install httpd
sudo yum -y install jq
myip=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
echo "<h2>WebServer with private IP: $myip</h2><p>Build by Terraform using External Script!!!" > /var/www/html/index.html
sudo service httpd start
chkconfig httpd on

mkdir ~/downloads
wget -O ~/downloads/terraform.zip https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip
wget -O ~/downloads/atlantis.zip https://github.com/runatlantis/atlantis/releases/download/v0.12.0/atlantis_linux_386.zip
sudo unzip ~/downloads/terraform.zip -d /usr/local/bin/
sudo unzip ~/downloads/atlantis.zip -d /usr/local/bin/
rm -rf ~/downloads/

export AWS_PROFILE=ora2postgres
export URL_ALB=${alb_dns_name}/events
export URL=$URL_ALB
export USERNAME=$(aws secretsmanager get-secret-value --secret-id dev/atlantis/github --region eu-west-2 | jq -r .SecretString | jq -r .username)
export TOKEN=$(aws secretsmanager get-secret-value --secret-id dev/atlantis/github --region eu-west-2 | jq -r .SecretString | jq -r .token)
export SECRET=$(aws secretsmanager get-secret-value --secret-id dev/atlantis/github --region eu-west-2 | jq -r .SecretString | jq -r .webhook_secret)
export REPO_WHITELIST=github.com/baranovRP/$(aws secretsmanager get-secret-value --secret-id dev/atlantis/github --region eu-west-2 | jq -r .SecretString | jq -r .repo)

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
    \"url\": \"http://$URL\"
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
--atlantis-url="http://$URL" \
--gh-user="$USERNAME" \
--gh-token="$TOKEN" \
--gh-webhook-secret="$SECRET" \
--repo-whitelist="$REPO_WHITELIST" &
