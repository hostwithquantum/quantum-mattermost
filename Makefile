STACK ?= mattermost
COMPOSE ?= compose.yml

# Env comes from direnv (.envrc). Run `direnv allow` first.

.PHONY: help test lint build run-dev deploy down logs ps setup-logs

.DEFAULT_GOAL := help

help: ## Show help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

lint: ## Validate compose syntax and the setup script.
	docker compose -f $(COMPOSE) config -q

test: ## "test" = fully render the merged/interpolated config so env gaps surface.
	docker compose -f $(COMPOSE) config >/dev/null && echo "config OK"

deploy: guard-QUANTUM_ENDPOINT guard-QUANTUM_STACK guard-DOMAIN guard-POSTGRES_PASSWORD guard-S3_BUCKET guard-S3_ENDPOINT guard-S3_ACCESS_KEY guard-S3_SECRET_KEY ## deploy the stack to Planetary Quantum
	quantum-cli stack deploy

### local development

run-dev: guard-DOMAIN guard-POSTGRES_PASSWORD ## Local dev = same stack. Requires `docker swarm init` on the local host.
	docker stack deploy --detach=false -c $(COMPOSE) $(STACK)

dev-down: ## delete local stack
	docker stack rm $(STACK)

dev-ps: ## show services in local stack
	docker stack services $(STACK)

logs: ## tail logs in local stack
	docker service logs -f $(STACK)_mattermost

setup-logs: ## check setup logs in local stack
	docker service logs $(STACK)_setup


### internal

guard-%:
	@ if [ "${${*}}" = "" ]; then \
        echo "Environment variable $* not set"; \
        exit 1; \
    fi