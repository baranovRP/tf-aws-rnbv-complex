###
provider "aws" {
  version                 = "~> 2.0"
  region                  = "eu-west-2"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "ora2postgres"
}

data "aws_vpc" "default" {
  default = true
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

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")
}
data "aws_iam_instance_profile" "ora2postgres" {
  name = "ora2postgres_ASM_to_EC2"
}

resource "aws_key_pair" "deployer" {
  key_name   = "atlantis"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCfObcpiUJAYEGXnJ0FOcyTM6pFvs1tTFKhpuNWfE/sssk7oGnM2Kw3zdktg7Ykq/LV+tOlxl9VtBa9FN6BQmxMi/bW96c47rGYL8VMPCQ3e7Qa7mKjbx1coBcQg9gxaLpWA73oD41O2cHYit084SlS8BTiRl1f4Lc9nPKM9RKyOzC6zajyIBFLDjOcRgVkEVoEW8QYroAFLJwKuKqu9oI9HAuov0c1o99J4ASqKmC/rm/76d1Fhs83dXNhLldmme7aN7M7XKX+8NM7hPeJtG3LGuxOtVMmMOhPkqG7FbtFWhKuXvD5CdU/S7QkxGo3lkZE+cwrUqKWQmEB6t4lKkxB"
}

resource "aws_instance" "this" {
  ami           = data.aws_ami.ami2.id
  instance_type = "t2.micro"

  subnet_id            = tolist(data.aws_subnet_ids.default.ids)[0]
  security_groups      = [aws_security_group.web_dmz.id]
  key_name             = aws_key_pair.deployer.key_name
  user_data            = data.template_file.user_data.rendered
  iam_instance_profile = data.aws_iam_instance_profile.ora2postgres.name

  tags = {
    Name = "atlantis"
  }
}

resource "aws_security_group" "web_dmz" {
  name = "tf-web-dmz"
}

resource "aws_security_group_rule" "allow_ssh_instance" {
  type              = "ingress"
  security_group_id = aws_security_group.web_dmz.id

  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_outbound_instance" {
  type              = "egress"
  security_group_id = aws_security_group.web_dmz.id

  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]
}