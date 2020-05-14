###
output "target_group_atlantis_arn" {
  value       = aws_lb_target_group.atlantis.arn
  description = "The target for atlantis traffic"
}

output "alb_dns_name" {
  value       = aws_lb.this.dns_name
  description = "The domain name of the load balancer"
}
