FROM ubuntu:latest

COPY conf/ /conf
COPY entrypoint.sh /entrypoint.sh

RUN set -ex\
    && apt update -y \
    && apt upgrade -y \
    && apt install -y wget unzip qrencode\
    && chmod +x /entrypoint.sh

CMD /entrypoint.sh
