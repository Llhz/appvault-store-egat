# Production environment overrides
environment = "prod"
region      = "ap-southeast-1"

eks_node_instance_types = ["m5.large"]
eks_node_desired_size   = 3
eks_node_min_size       = 2
eks_node_max_size       = 10
