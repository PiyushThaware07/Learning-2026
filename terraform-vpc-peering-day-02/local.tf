locals {

  primary_user_data = <<-EOF
              #!/bin/bash
              exec > /var/log/user-data.log 2>&1

              apt update -y
              apt install -y apache2

              systemctl start apache2
              systemctl enable apache2

              PRIVATE_IP=$(hostname -I | awk '{print $1}')

              echo "<html>" > /var/www/html/index.html
              echo "<h1>VPC Name: ${var.providers_config["primary"].vpc_name}</h1>" >> /var/www/html/index.html
              echo "<h2>Region: ${var.providers_config["primary"].region}</h2>" >> /var/www/html/index.html
              echo "<p>Private IP: $PRIVATE_IP</p>" >> /var/www/html/index.html
              echo "</html>" >> /var/www/html/index.html
              EOF


  secondary_user_data = <<-EOF
              #!/bin/bash
              exec > /var/log/user-data.log 2>&1

              apt update -y
              apt install -y apache2

              systemctl start apache2
              systemctl enable apache2

              PRIVATE_IP=$(hostname -I | awk '{print $1}')

              echo "<html>" > /var/www/html/index.html
              echo "<h1>VPC Name: ${var.providers_config["secondary"].vpc_name}</h1>" >> /var/www/html/index.html
              echo "<h2>Region: ${var.providers_config["secondary"].region}</h2>" >> /var/www/html/index.html
              echo "<p>Private IP: $PRIVATE_IP</p>" >> /var/www/html/index.html
              echo "</html>" >> /var/www/html/index.html
              EOF
}