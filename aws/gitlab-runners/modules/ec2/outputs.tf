output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = local.use_existing_vpc ? var.private_subnets : module.vpc[0].private_subnets
}

output "runner_role" {
  description = "Runner role"
  value       = local.use_existing_role ? var.runner_role : aws_iam_role.runner_role[0].name
}

output "asg_name" {
  description = "Output of the name of runner ASG"
  value       = aws_autoscaling_group.runner_asg.name
}