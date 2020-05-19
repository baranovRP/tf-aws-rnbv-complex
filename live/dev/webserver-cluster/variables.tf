locals {
  instance_type     = "t2.micro"
  secretmanager_key = "dev/atlantis/github"
  atlantis_url      = "http://${module.alb.alb_dns_name}/events"
  webhook_secret    = module.security.webhook_secret
  github_username   = module.security.github_username
  github_token      = module.security.github_token
  github_repo       = "tf-aws-rnbv-complex"
  github_repo_url   = "github.com/${local.github_username}/${local.github_repo}"
}
