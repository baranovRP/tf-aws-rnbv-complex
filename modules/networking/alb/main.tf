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

resource "aws_lb" "this" {
  name = "${var.cluster_name}-alb"

  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default.ids
  security_groups    = [aws_security_group.atlantis.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = "404"
    }
  }
}

resource "aws_security_group" "atlantis" {
  name = "${var.cluster_name}-alb"
}

resource "aws_security_group_rule" "allow_atlantis_in" {
  type              = "ingress"
  security_group_id = aws_security_group.atlantis.id

  from_port        = 80
  to_port          = 4141
  protocol         = "TCP"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group_rule" "allow_all_out" {
  type              = "egress"
  security_group_id = aws_security_group.atlantis.id

  from_port        = 0
  to_port          = 0
  protocol         = -1
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_lb_target_group" "atlantis" {
  name = "${var.cluster_name}-atlantis"

  port     = 4141
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "atlantis" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["/events"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.atlantis.arn
  }
}
