FROM luizeof/dockerpress:latest
RUN apt-get update && apt-get install -y socat
