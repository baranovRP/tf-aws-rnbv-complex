###
output "target_group_web_arn" {
  value       = aws_lb_target_group.web.arn
  description = "The target for web traffic"
}

output "target_group_atlantis_arn" {
  value       = aws_lb_target_group.atlantis.arn
  description = "The target for atlantis traffic"
}

output "alb_dns_name" {
  value       = aws_lb.tf_balancer.dns_name
  description = "The domain name of the load balancer"
}
