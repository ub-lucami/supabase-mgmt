FROM node:18-slim

# Install dependencies
RUN apt-get update && \
    apt-get install -y curl jq ca-certificates postgresql-client && \
    apt-get clean

# Install Supabase CLI
RUN npm install -g supabase

WORKDIR /scripts

COPY migrate_all.sh .
COPY entrypoint.sh .

RUN chmod +x migrate_all.sh entrypoint.sh

RUN mkdir /config

ENTRYPOINT ["/scripts/entrypoint.sh"]