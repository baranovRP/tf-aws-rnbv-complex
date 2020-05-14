###
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

/*
data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "eu-west-2"
  }
}
*/

resource "aws_launch_configuration" "tf_ami" {
  image_id        = var.image_id
  instance_type   = var.instance_type
  security_groups = [aws_security_group.this.id]
  key_name        = var.key_name

  user_data = var.user_data

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web_cluster" {
  launch_configuration = aws_launch_configuration.tf_ami.id
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids

  target_group_arns = [var.target_group_arn]
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "tf-atlantis"
  }
}

resource "aws_security_group" "this" {
  name = "${var.cluster_name}-atlantis"
}

/*
resource "aws_security_group_rule" "allow_ssh_instance" {
  type              = "ingress"
  security_group_id = aws_security_group.this.id

  from_port   = 22
  to_port     = 22
  protocol    = local.protocols.tcp
  cidr_blocks = [local.cidrblocks.cidrblock_all_ipv4]
}
*/
resource "aws_security_group_rule" "allow_http_inbound_instance" {
  type              = "ingress"
  security_group_id = aws_security_group.this.id

  from_port        = 0
  to_port          = 0
  protocol         = -1
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group_rule" "allow_all_outbound_instance" {
  type              = "egress"
  security_group_id = aws_security_group.this.id

  from_port        = 0
  to_port          = 0
  protocol         = -1
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

