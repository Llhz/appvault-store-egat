# Staging environment overrides
environment = "stg"
region      = "ap-southeast-1"

eks_node_instance_types = ["t3.medium"]
eks_node_desired_size   = 2
eks_node_min_size       = 1
eks_node_max_size       = 3
