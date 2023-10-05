output "asg_name" {
  value       = module.new_vpc_ec2_runner.asg_name
  description = "The name of the autoscaling group"
}
