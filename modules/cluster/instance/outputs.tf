###
output "subnet_ids" {
  description = "The list of subnets' ids"
  value       = data.aws_subnet_ids.default
}
