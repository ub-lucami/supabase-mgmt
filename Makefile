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
	@echo -e "    ${CYAN}~/secrets/migration.env${RESET}"
	@echo -e "Predloga je v ${CYAN}sample.env${RESET}"
	@echo ""
	@echo "Datoteka NI del git repozitorija in jo moraš ustvariti ročno."
	@echo "Vsebuje Cloud + lokalne Supabase ključe."
	@echo ""
	@echo -e "${GREEN}make build${RESET}     - zgradi mgmt container"
	@echo -e "${GREEN}make rebuild${RESET}   - zgradi brez cache (priporočeno po spremembah)"
	@echo -e "${GREEN}make run${RESET}       - zaženi migracijo"
	@echo -e "${GREEN}make shell${RESET}     - odpri bash v mgmt containerju"
	@echo -e "${GREEN}make log${RESET}       - izpiši zadnje loge migracije"
	@echo -e "${GREEN}make clean${RESET}     - pobriši vse slike in kontejnarje"
	@echo ""

build:
	docker compose build

rebuild:
	docker compose build --no-cache

run:
	@echo "${YELLOW}Starting migration...${RESET}"
	docker compose run --rm mgmt

shell:
	docker compose run --rm mgmt bash

log:
	docker logs supabase-mgmt || true

clean:
	docker compose down --rmi all