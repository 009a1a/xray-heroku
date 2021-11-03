FROM ubuntu:latest

COPY wwwroot.tar.gz /wwwroot/wwwroot.tar.gz
COPY entrypoint.sh /entrypoint.sh

RUN set -ex\
    && apt update -y \
    && apt upgrade -y \
    && apt install -y wget unzip qrencode\
    && chmod +x /entrypoint.sh

RUN chmod +x /entrypoint.sh

CMD /entrypoint.sh
