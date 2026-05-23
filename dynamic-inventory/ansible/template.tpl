[servers]
%{ for name, instance in instances ~}
${name} ansible_host=${instance.public_ip} ansible_user=${instance.tags.user}
%{ endfor ~}


[all:vars]
ansible_ssh_private_key_file=./aws-key.pem
ansible_python_interpreter=/usr/bin/python3