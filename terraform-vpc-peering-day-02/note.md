# Keys generation
```
#!/bin/bash

for region in ap-south-1 ap-south-2; do
  echo "Creating key pair for $region..."

  aws ec2 create-key-pair \
    --key-name "${region}-key" \
    --region "$region" \
    --query 'KeyMaterial' \
    --output text > "${region}-key.pem"

  # Fix permissions (IMPORTANT for SSH)
  chmod 400 "${region}-key.pem"

  echo "Saved: ${region}-key.pem"
done
```