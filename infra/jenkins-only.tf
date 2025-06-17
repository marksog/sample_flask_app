module "jenkins_first" {
  source         = "./modules/jenkins"
  env            = "dev"
  vpc_id         = module.network.vpc_id
  public_subnets = module.network.public_subnets
  key_name       = var.key_name

  bastion_sg_id = module.bastion.security_group_id
  cluster_name = module.eks.cluster_name
  # disable other modules 
  
}