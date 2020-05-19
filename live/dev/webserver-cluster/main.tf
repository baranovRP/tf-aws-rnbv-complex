###
provider "aws" {
  version = "~> 2.0"
  region  = "eu-west-2"
}

terraform {
  required_version = "~> v0.12"

  backend "s3" {
    bucket = "tf-state-eu-west-2-rnbv"
    key    = "dev/services/webserver-cluster/terraform.tfstate"
    region = "eu-west-2"

    dynamodb_table = "tf-locks-eu-west-2-rnbv"
    encrypt        = true
  }
}

data "aws_ami" "ami2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-*-gp2"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  vars = {
    url            = local.atlantis_url
    webhook_secret = local.webhook_secret
    username       = local.github_username
    token          = local.github_token
    repo_whitelist = local.github_repo_url
  }
}

data "aws_iam_instance_profile" "ora2postgres_atlantis" {
  name = "ora2postgres_atlantis"
}

resource "aws_key_pair" "deployer" {
  key_name   = "atlantis"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCfObcpiUJAYEGXnJ0FOcyTM6pFvs1tTFKhpuNWfE/sssk7oGnM2Kw3zdktg7Ykq/LV+tOlxl9VtBa9FN6BQmxMi/bW96c47rGYL8VMPCQ3e7Qa7mKjbx1coBcQg9gxaLpWA73oD41O2cHYit084SlS8BTiRl1f4Lc9nPKM9RKyOzC6zajyIBFLDjOcRgVkEVoEW8QYroAFLJwKuKqu9oI9HAuov0c1o99J4ASqKmC/rm/76d1Fhs83dXNhLldmme7aN7M7XKX+8NM7hPeJtG3LGuxOtVMmMOhPkqG7FbtFWhKuXvD5CdU/S7QkxGo3lkZE+cwrUqKWQmEB6t4lKkxB"
}

//resource "null_resource" "demo" {}

module "asg" {
  source = "../../../modules/cluster/asg"

  cluster_name           = "tf-atlantis"
  db_remote_state_bucket = "tf-state-eu-west-2-rnbv"
  db_remote_state_key    = "dev/services/webserver-cluster/terraform.tfstate"

  min_size             = 1
  max_size             = 4
  image_id             = data.aws_ami.ami2.id
  instance_type        = local.instance_type
  key_name             = aws_key_pair.deployer.key_name
  user_data            = data.template_file.user_data.rendered
  iam_instance_profile = data.aws_iam_instance_profile.ora2postgres_atlantis.name

  target_group_atlantis_arn = module.alb.target_group_atlantis_arn
}

module "alb" {
  source = "../../../modules/networking/alb"

  cluster_name           = "tf-atlantis"
  db_remote_state_bucket = "tf-state-eu-west-2-rnbv"
  db_remote_state_key    = "dev/services/webserver-cluster/terraform.tfstate"
}

module "security" {
  source = "../../../modules/security/secret"

  name = local.secretmanager_key
}

// future github integration
/*
module "github" {
  source = "../../../modules/common/github"

  webhook_url = local.atlantis_url
  webhook_secret = local.webhook_secret
  github_token = local.github_token
  atlantis_allowed_repo_names = [local.github_repo_url]
}
*/

// for demo purpose
/*
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

data "aws_subnet" "default" {
  availability_zone = "eu-west-2a"
}

resource "aws_instance" "secondserver" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  tags = {
    Name = "updated by atlantis"
  }
  subnet_id = data.aws_subnet.default.id
}
*/
