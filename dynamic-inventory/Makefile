TF_DIR=terraform
ANSIBLE_DIR=ansible
AWS_KEY=$(ANSIBLE_DIR)/aws-key.pem

.PHONY: start pre tf-init tf-apply ansible clean

start: pre tf-init tf-apply ansible
	@echo "🚀 Done"

pre:
	@test -f $(AWS_KEY) || (echo "❌ Missing key $(AWS_KEY)" && exit 1)
	@chmod 400 $(AWS_KEY)

tf-init:
	@cd $(TF_DIR) && terraform init

tf-apply:
	@cd $(TF_DIR) && terraform apply --auto-approve

ansible:
	@cd $(ANSIBLE_DIR) && ansible-playbook -i inventory.ini playbook.yml

clean:
	@cd $(TF_DIR) && terraform destroy --auto-approve
	@cd $(TF_DIR) && rm -rf .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup