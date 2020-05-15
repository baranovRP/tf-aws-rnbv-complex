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

resource "aws_launch_configuration" "this" {
  image_id      = var.image_id
  instance_type = var.instance_type
  security_groups = [
    aws_security_group.all.id,
    aws_security_group.atlantis.id,
    aws_security_group.ssh.id
  ]
  key_name             = var.key_name
  user_data            = var.user_data
  iam_instance_profile = var.iam_instance_profile

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "this" {
  launch_configuration = aws_launch_configuration.this.id
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids

  target_group_arns = [var.target_group_atlantis_arn]
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "tf-atlantis"
  }
}

resource "aws_security_group" "ssh" {
  name = "${var.cluster_name}-ssh"
}

resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  security_group_id = aws_security_group.ssh.id

  from_port   = 22
  to_port     = 22
  protocol    = "TCP"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "atlantis" {
  name = "${var.cluster_name}-atlantis"
}

resource "aws_security_group_rule" "allow_atlantis" {
  type              = "ingress"
  security_group_id = aws_security_group.atlantis.id

  from_port   = 4141
  to_port     = 4141
  protocol    = "TCP"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "all" {
  name = "${var.cluster_name}-out"
}

resource "aws_security_group_rule" "allow_all_out" {
  type              = "egress"
  security_group_id = aws_security_group.all.id

  from_port        = 0
  to_port          = 0
  protocol         = -1
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}
