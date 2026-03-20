FROM node:18-slim

# Install basic tools needed in mgmt container
RUN apt-get update && \
    apt-get install -y \
        curl \
        jq \
        ca-certificates \
        postgresql-client \
        bash && \
    apt-get clean

# Workdir for scripts
WORKDIR /scripts

# Copy migration + entrypoint scripts
COPY migrate_all.sh .
COPY entrypoint.sh .

# Make scripts executable
RUN chmod +x migrate_all.sh entrypoint.sh

# Directory where migration.env will be mounted
RUN mkdir /config

# Use simple entrypoint
ENTRYPOINT ["/scripts/entrypoint.sh"]