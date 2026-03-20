build:
    docker compose build

run:
    docker compose run --rm mgmt

shell:
    docker compose run --rm mgmt bash

clean:
    docker compose down --rmi all