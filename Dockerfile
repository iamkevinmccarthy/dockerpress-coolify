FROM luizeof/dockerpress:latest
COPY entrypoint-custom.sh /entrypoint-custom.sh
RUN chmod +x /entrypoint-custom.sh
ENTRYPOINT ["/entrypoint-custom.sh"]
