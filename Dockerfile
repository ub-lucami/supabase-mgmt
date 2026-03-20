FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y curl jq ca-certificates postgresql-client && \
    apt-get clean

# Install node + supabase CLI
RUN apt-get update && \
    apt-get install -y nodejs npm && \
    npm install -g supabase

WORKDIR /scripts

COPY migrate_all.sh .
COPY entrypoint.sh .
RUN chmod +x migrate_all.sh entrypoint.sh

# Secrets are mounted into /config
RUN mkdir /config

ENTRYPOINT ["/scripts/entrypoint.sh"]