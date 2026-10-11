.PHONY: build plan apply destroy seed demo

build:
	bash scripts/build_lambdas.sh

plan:
	cd terraform && terraform plan

apply:
	cd terraform && terraform apply

destroy:
	cd terraform && terraform destroy

seed:
	python3 scripts/seed.py

demo:
	python3 simulator/mlbb_simulator.py --count 30
