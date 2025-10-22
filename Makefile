# === Terraform automation Makefile ===
# Usage:
#   make infra-apply
#   make addons-apply
#   make infra-destroy
#   make addons-destroy

infra-apply:
	terraform -chdir=envs/dev init
	terraform -chdir=envs/dev apply -auto-approve

addons-apply:
	terraform -chdir=envs/addons init
	terraform -chdir=envs/addons apply -auto-approve

infra-destroy:
	terraform -chdir=envs/dev destroy -auto-approve

addons-destroy:
	terraform -chdir=envs/addons destroy -auto-approve
