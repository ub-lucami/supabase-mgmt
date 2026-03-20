# Default target
.DEFAULT_GOAL := help

# Colors
GREEN := \033[0;32m
YELLOW := \033[1;33m
CYAN := \033[0;36m
RESET := \033[0m

help:
	@echo ""
	@echo -e "${CYAN}SUPABASE MANAGEMENT CONTAINER COMMANDS${RESET}"
	@echo ""
	@echo -e "${YELLOW}Konfiguracijska datoteka za migracijo mora biti tukaj:${RESET}"
	@echo -e "	${CYAN}~/secrets/migration.env${RESET}"
	@echo -e "Predloga je v ${CYAN}sample.env${RESET}"
	@echo ""
	@echo "Datoteka NI del git repozitorija in jo moraš ustvariti ročno."
	@echo "Vsebuje Cloud + lokalne Supabase ključe."
	@echo ""
	@echo -e "${GREEN}make build${RESET}	 - zgradi mgmt container"
	@echo -e "${GREEN}make rebuild${RESET}   - zgradi brez cache"
	@echo -e "${GREEN}make dry-run${RESET}   - preveri konfiguracijo in povezave"
	@echo -e "${GREEN}make run${RESET}	   - zaženi migracijo (ko so Cloud ključi OK)"
	@echo -e "${GREEN}make shell${RESET}	 - odpri bash v mgmt containerju"
	@echo -e "${GREEN}make log${RESET}	   - logi mgmt containera"
	@echo -e "${GREEN}make clean${RESET}	 - počisti slike/kontejnarje"
	@echo ""

build:
	docker compose build

rebuild:
	docker compose build --no-cache

run:
	@echo -e "${YELLOW}Starting migration...${RESET}"
	docker compose run --rm mgmt

dry-run:
	@echo -e "${YELLOW}=== DRY RUN: CHECKING ENV, DOCKER, NETWORK & ACCESS ===${RESET}"
	@echo ""
	@echo "🔍 Checking docker.sock..."
	docker compose run --rm --entrypoint "" mgmt sh -c 'test -S /var/run/docker.sock && echo "✔ docker.sock OK" || echo "❌ docker.sock missing"'
	@echo ""
	@echo "🔍 Checking if migration.env is mounted..."
	docker compose run --rm --entrypoint "" mgmt sh -c 'test -f /config/migration.env && echo "✔ migration.env OK" || echo "❌ migration.env missing"'
	@echo ""
	@echo "🔍 Checking NPX Supabase CLI..."
	docker compose run --rm --entrypoint "" mgmt sh -c 'npx supabase --version || echo "❌ npx supabase failed"'
	@echo ""
	@echo "🔍 Checking Cloud API availability..."
	docker compose run --rm --entrypoint "" mgmt sh -c 'source /config/migration.env && curl -s -o /dev/null -w "%{http_code}\n" "$$CLOUD_PROJECT_URL/auth/v1/health"'
	@echo ""
	@echo "🔍 Checking local Kong API..."
	docker compose run --rm --entrypoint "" mgmt sh -c 'curl -s -o /dev/null -w "%{http_code}\n" http://kong:8000'
	@echo ""
	@echo "🔍 Checking local Postgres..."
	docker compose run --rm --entrypoint "" mgmt sh -c 'source /config/migration.env && psql "$$SELF_HOSTED_DB_URL" -c "SELECT 1;"'
	@echo ""
	@echo -e "${GREEN}Dry run complete.${RESET}"

shell:
	docker compose run --rm --entrypoint "" mgmt bash

log:
	docker logs supabase-mgmt || true

clean:
	docker compose down --rmi all --remove-orphans