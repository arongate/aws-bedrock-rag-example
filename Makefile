fmt:
	terraform fmt

init:
	terraform init

validate:
	terraform validate

plan:
	terraform plan -out tfplan

apply:
	terraform apply

apply_target:
	terraform apply -target=$(TARGET)

output:
	terraform output

destroy:
	terraform destroy
