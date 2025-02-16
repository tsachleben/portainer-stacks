FROM ubuntu:22.04

RUN true \
 && apt-get update \
 && apt-get install -y vim cron certbot python3-certbot-dns-cloudflare

ENTRYPOINT [ "/usr/sbin/cron" ]
CMD [ "-f", "-P", "-n" ]

