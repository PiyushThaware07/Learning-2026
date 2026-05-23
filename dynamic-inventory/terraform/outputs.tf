output "instance_ids" {
  description = "Map of EC2 instance names and their instance IDs"
  value = {
    for key, instance in aws_instance.ansible_ec2 :
    key => instance.id
  }
}

output "public_ips" {
  description = "Map of EC2 instance names and their public IP addresses"
  value = {
    for key, instance in aws_instance.ansible_ec2 :
    key => instance.public_ip
  }
}
