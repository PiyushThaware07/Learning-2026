resource "local_file" "ansible_inventory" {
  filename = "../ansible/inventory.ini"

  content = templatefile("../ansible/template.tpl", {
    instances = aws_instance.ansible_ec2
  })
}
