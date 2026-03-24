FROM node:18-slim

RUN apt-get update && \
    apt-get install -y curl jq ca-certificates postgresql-client bash && \
    apt-get clean

WORKDIR /scripts

COPY migrate_all.sh .
COPY entrypoint.sh .
COPY cloud_size_check.sh .
RUN chmod +x cloud_size_check.sh
RUN chmod +x migrate_all.sh entrypoint.sh
RUN mkdir /config

ENTRYPOINT ["/scripts/entrypoint.sh"]