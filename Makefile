.PHONY: help build init plan apply destroy seed demo bad duplicate

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "  build      package Lambda zips"
	@echo "  init       terraform init"
	@echo "  plan       terraform plan"
	@echo "  apply      terraform apply"
	@echo "  destroy    terraform destroy"
	@echo "  seed       pre-load DynamoDB with starting scores"
	@echo "  demo       run simulator with 30 events"
	@echo "  bad        upload an invalid file"
	@echo "  duplicate  send the same match_id twice"

build:
	bash scripts/build_lambdas.sh

init:
	cd terraform && terraform init

plan:
	cd terraform && terraform plan

apply:
	cd terraform && terraform apply

destroy:
	cd terraform && terraform destroy

seed:
	uv run --with boto3 python3 scripts/seed.py

demo:
	uv run --with boto3 python3 simulator/mlbb_simulator.py --count 30

bad:
	uv run --with boto3 python3 simulator/mlbb_simulator.py --bad --count 1

duplicate:
	uv run --with boto3 python3 simulator/mlbb_simulator.py --duplicate --count 1
