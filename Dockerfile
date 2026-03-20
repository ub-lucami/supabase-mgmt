FROM node:18-slim

# Install dependencies
RUN apt-get update && \
    apt-get install -y curl jq ca-certificates postgresql-client bash && \
    apt-get clean

# Install Supabase CLI (official binary)
RUN curl -sLo /usr/local/bin/supabase \
      https://github.com/supabase/cli/releases/latest/download/supabase_linux_amd64 && \
    chmod +x /usr/local/bin/supabase

WORKDIR /scripts

COPY migrate_all.sh .
COPY entrypoint.sh .

RUN chmod +x migrate_all.sh entrypoint.sh

RUN mkdir /config

ENTRYPOINT ["/scripts/entrypoint.sh"]