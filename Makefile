.PHONY: init build plan apply destroy seed demo bad duplicate poison

init:
	cd terraform && terraform init

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

bad:
	python3 simulator/mlbb_simulator.py --bad --count 1

duplicate:
	python3 simulator/mlbb_simulator.py --duplicate --count 1

poison:
	python3 simulator/mlbb_simulator.py --poison --count 1
