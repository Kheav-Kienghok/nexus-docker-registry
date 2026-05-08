.PHONY: all init plan provision configure destroy setup output help

TERRAFORM_DIR := terraform
ANSIBLE_DIR   := ansible

## Full run: setup + provision + configure
all: setup provision configure

## Interactive settings configuration
setup:
	@bash scripts/setup.sh

## Terraform init
init:
	cd $(TERRAFORM_DIR) && terraform init

## Terraform plan
plan:
	cd $(TERRAFORM_DIR) && terraform plan

## Terraform apply — creates key pair, EC2, waits for cloud-init, writes inventory
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
	@echo "  make all        Setup settings + provision server + configure Nexus (full deploy)"
	@echo "  make setup      Interactive settings configuration (region, instance type, storage)"
	@echo "  make provision  Run Terraform only (generates key pair, creates EC2, waits for cloud-init)"
	@echo "  make configure  Run Ansible only (install Docker + start Nexus)"
	@echo "  make plan       Preview Terraform changes"
	@echo "  make output     Show server IP, URLs, and SSH command"
	@echo "  make destroy    Tear down all AWS resources"
	@echo ""
