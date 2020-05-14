###
output "target_group_arn" {
  value       = aws_lb_target_group.asg.arn
  description = "The domain name of the load balancer"
}

output "alb_dns_name" {
  value       = aws_lb.tf_balancer.dns_name
  description = "The domain name of the load balancer"
}
