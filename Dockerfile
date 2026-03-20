FROM node:18-slim

# Install dependencies
RUN apt-get update && \
    apt-get install -y curl jq ca-certificates postgresql-client bash && \
    apt-get clean

RUN rm -f /usr/local/bin/supabase

# Install Supabase CLI (stable LTS v1.188.7)
RUN curl -sL \
  https://github.com/supabase/cli/releases/download/v1.188.7/supabase_linux_amd64 \
  -o /usr/local/bin/supabase && \
  chmod +x /usr/local/bin/supabase

WORKDIR /scripts

COPY migrate_all.sh .
COPY entrypoint.sh .

RUN chmod +x migrate_all.sh entrypoint.sh

RUN mkdir /config

ENTRYPOINT ["/scripts/entrypoint.sh"]