output "cluster_name" {
  description = "The name of the cluster"
  value       = module.new_vpc_eks_runner.cluster_name
}

output "self_managed_node_groups" {
  description = "Map of attribute maps for all self managed node groups created"
  value       = module.new_vpc_eks_runner.self_managed_node_groups
}
