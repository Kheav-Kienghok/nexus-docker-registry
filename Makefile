.PHONY: all init plan apply provision configure destroy help

TERRAFORM_DIR := terraform
ANSIBLE_DIR   := ansible

## Full run: provision + configure
all: provision configure

## Terraform init
init:
	cd $(TERRAFORM_DIR) && terraform init

## Terraform plan
plan:
	cd $(TERRAFORM_DIR) && terraform plan

## Terraform apply — creates EC2 + writes inventory
provision:
	cd $(TERRAFORM_DIR) && terraform init && terraform apply -auto-approve

## Ansible — install Docker + deploy Nexus
configure:
	cd $(ANSIBLE_DIR) && \
		ansible-galaxy collection install -r requirements.yml --ignore-errors && \
		ansible-playbook playbook.yml

## Tear down all AWS resources
destroy:
	cd $(TERRAFORM_DIR) && terraform destroy -auto-approve

## Print Terraform outputs
output:
	cd $(TERRAFORM_DIR) && terraform output

help:
	@echo ""
	@echo "  make all        Provision server + configure Nexus (full deploy)"
	@echo "  make provision  Run Terraform only (create EC2)"
	@echo "  make configure  Run Ansible only (install Docker + start Nexus)"
	@echo "  make plan       Preview Terraform changes"
	@echo "  make output     Show server IP and URLs"
	@echo "  make destroy    Tear down all AWS resources"
	@echo ""
