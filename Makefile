# =========================
# Config
# =========================
TERRAFORM_DIR = infra
TFVARS_DEV    = environments/dev.tfvars
TFVARS_PROD   = environments/prod.tfvars

# =========================
# Docker (utilidades)
# =========================
restart:
	sudo systemctl restart docker

start:
	sudo docker start $(c)

stop:
	sudo docker stop $(c)

ps:
	sudo docker ps

logs:
	sudo docker logs -f $(c)

# =========================
# Build app
# =========================
build-dev:
	sudo docker build --no-cache -f dockerfile/dev_Dockerfile -t app:dev .

build-prod:
	sudo docker build --no-cache -f dockerfile/prod_Dockerfile -t app:prod .

# =========================
# Terraform - DEV
# =========================
init-dev:
	cd $(TERRAFORM_DIR) && sudo terraform init
	cd $(TERRAFORM_DIR) && (sudo terraform workspace select dev || sudo terraform workspace new dev)

plan-dev:
	cd $(TERRAFORM_DIR) && sudo terraform init
	cd $(TERRAFORM_DIR) && (sudo terraform workspace select dev || sudo terraform workspace new dev)
	cd $(TERRAFORM_DIR) && sudo terraform plan -var-file=$(TFVARS_DEV)

apply-dev:
	cd $(TERRAFORM_DIR) && sudo terraform init
	cd $(TERRAFORM_DIR) && (sudo terraform workspace select dev || sudo terraform workspace new dev)
	cd $(TERRAFORM_DIR) && sudo terraform apply -var-file=$(TFVARS_DEV)

down-dev:
	cd $(TERRAFORM_DIR) && sudo terraform init
	cd $(TERRAFORM_DIR) && (sudo terraform workspace select dev || sudo terraform workspace new dev)
	cd $(TERRAFORM_DIR) && sudo terraform destroy -var-file=$(TFVARS_DEV)

restart-dev:
	@echo "Recreando entorno de desarrollo (destroy + build + apply)..."
	cd $(TERRAFORM_DIR) && sudo terraform init
	cd $(TERRAFORM_DIR) && (sudo terraform workspace select dev || sudo terraform workspace new dev)
	cd $(TERRAFORM_DIR) && sudo terraform destroy -var-file=$(TFVARS_DEV) -auto-approve
	sudo docker build --no-cache -f dockerfile/dev_Dockerfile -t app:dev .
	cd $(TERRAFORM_DIR) && sudo terraform apply -var-file=$(TFVARS_DEV) -auto-approve

clean-dev:
	cd $(TERRAFORM_DIR) && sudo terraform init
	cd $(TERRAFORM_DIR) && (sudo terraform workspace select dev || sudo terraform workspace new dev)
	cd $(TERRAFORM_DIR) && sudo terraform destroy -var-file=$(TFVARS_DEV) -auto-approve
	sudo docker system prune -f

# =========================
# Terraform - PROD
# =========================
init-prod:
	cd $(TERRAFORM_DIR) && sudo terraform init
	cd $(TERRAFORM_DIR) && (sudo terraform workspace select prod || sudo terraform workspace new prod)

plan-prod:
	cd $(TERRAFORM_DIR) && sudo terraform init
	cd $(TERRAFORM_DIR) && (sudo terraform workspace select prod || sudo terraform workspace new prod)
	cd $(TERRAFORM_DIR) && sudo terraform plan -var-file=$(TFVARS_PROD)

apply-prod:
	cd $(TERRAFORM_DIR) && sudo terraform init
	cd $(TERRAFORM_DIR) && (sudo terraform workspace select prod || sudo terraform workspace new prod)
	cd $(TERRAFORM_DIR) && sudo terraform apply -var-file=$(TFVARS_PROD)

down-prod:
	cd $(TERRAFORM_DIR) && sudo terraform init
	cd $(TERRAFORM_DIR) && (sudo terraform workspace select prod || sudo terraform workspace new prod)
	cd $(TERRAFORM_DIR) && sudo terraform destroy -var-file=$(TFVARS_PROD)

restart-prod:
	@echo "Recreando entorno de producción (destroy + build + apply)..."
	cd $(TERRAFORM_DIR) && sudo terraform init
	cd $(TERRAFORM_DIR) && (sudo terraform workspace select prod || sudo terraform workspace new prod)
	cd $(TERRAFORM_DIR) && sudo terraform destroy -var-file=$(TFVARS_PROD) -auto-approve
	sudo docker build --no-cache -f dockerfile/prod_Dockerfile -t app:prod .
	cd $(TERRAFORM_DIR) && sudo terraform apply -var-file=$(TFVARS_PROD) -auto-approve

clean-prod:
	cd $(TERRAFORM_DIR) && sudo terraform init
	cd $(TERRAFORM_DIR) && (sudo terraform workspace select prod || sudo terraform workspace new prod)
	cd $(TERRAFORM_DIR) && sudo terraform destroy -var-file=$(TFVARS_PROD) -auto-approve
	sudo docker system prune -f

# =========================
# Help
# =========================
help:
	@echo ""
	@echo "Comandos disponibles:"
	@echo "  make restart                       - Reinicia el servicio de Docker"
	@echo "  make start c=CONTAINER_ID          - Inicia un contenedor especificado"
	@echo "  make stop c=CONTAINER_ID           - Para un contenedor especificado"
	@echo "  make ps                            - Muestra todos los contenedores en ejecución"
	@echo "  make logs c=CONTAINER_ID           - Muestra logs en tiempo real del contenedor"
	@echo ""
	@echo "  make build-dev                     - Construye la imagen de desarrollo (app:dev)"
	@echo "  make build-prod                    - Construye la imagen de producción (app:prod)"
	@echo ""
	@echo "  make init-dev                      - Inicializa Terraform y selecciona/crea workspace dev"
	@echo "  make plan-dev                      - Muestra el plan de ejecución para dev"
	@echo "  make apply-dev                     - Aplica la configuración para dev"
	@echo "  make down-dev                      - Destruye el entorno de desarrollo"
	@echo "  make restart-dev                   - Recrea completamente el entorno dev"
	@echo "  make clean-dev                     - Destruye dev y limpia recursos Docker"
	@echo ""
	@echo "  make init-prod                     - Inicializa Terraform y selecciona/crea workspace prod"
	@echo "  make plan-prod                     - Muestra el plan de ejecución para prod"
	@echo "  make apply-prod                    - Aplica la configuración para prod"
	@echo "  make down-prod                     - Destruye el entorno de producción"
	@echo "  make restart-prod                  - Recrea completamente el entorno prod"
	@echo "  make clean-prod                    - Destruye prod y limpia recursos Docker"
	@echo ""