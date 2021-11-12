#! /bin/bash
set -ex
if [[ -z "${VER}" ]]; then
  VER="latest"
fi
echo ${VER}

if [[ -z "${UUID}" ]]; then
  UUID="86d9b8a7-9dfa-42f4-b9ac-f6b9a9beacda"
fi
echo ${UUID}

if [[ -z "${V2_Path}" ]]; then
  V2_Path="/static"
fi
echo ${V2_Path}

if [[ -z "${V2_QR_Path}" ]]; then
  V2_QR_Path="qr_img"
fi
echo ${V2_QR_Path}

rm -rf /etc/localtime
ln -sf /usr/share/zoneinfo/Europe/UnitedKingdom/etc/localtime
date -R

if [ "$VER" = "latest" ]; then
  V2RAY_URL="https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-32.zip"
else
  V_VER="v$VER"
  V2RAY_URL="https://github.com/v2fly/v2ray-core/releases/download/$V_VER/v2ray-linux-32.zip"
fi

if [ "$VER" = "latest" ]; then
  V2RAY_URL="https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip"
else
  V_VER="v$VER"
  V2RAY_URL="https://github.com/v2fly/v2ray-core/releases/download/$V_VER/v2ray-linux-64.zip"
fi

V_VER="latest"
mkdir /v2raybin
cd /v2raybin
echo ${V2RAY_URL}
wget --no-check-certificate -qO 'v2ray.zip' ${V2RAY_URL}
unzip v2ray.zip
rm -rf v2ray.zip
chmod +x v2ray

C_VER="v1.0.4"
mkdir /caddybin
cd /caddybin
CADDY_URL="https://github.com/caddyserver/caddy/releases/download/$C_VER/caddy_${C_VER}_linux_amd64.tar.gz"
echo ${CADDY_URL}
wget --no-check-certificate -qO 'caddy.tar.gz' ${CADDY_URL}
tar xvf caddy.tar.gz
rm -rf caddy.tar.gz
chmod +x caddy

cd /wwwroot
tar xvf wwwroot.tar.gz
rm -rf wwwroot.tar.gz

cat <<-EOF > /v2raybin/config.json
{
    "log": {
        "loglevel": "none"
    },
    "routing": {
        "domainStrategy": "IPOnDemand",
        "rules": [
            {
                "type": "field",
                "ip": [
                    "geoip:private"
                ],
                "outboundTag": "block"
            }
        ]
    },
    "inbounds":{
        "protocol":"vless",
        "listen":"0.0.0.0",
        "port":10808,
        "settings": {
                "clients": [
                    {
                        "id": "${Vless_UUID}"
                    }
                ],
                "encryption": "none"
            },
            "streamSettings":{
                "network":"ws",
                "wsSettings":{
                    "path":"${V2_Path}"
            }
        }
    },
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "block"
        },
        {
            "protocol": "blackhole",
            "tag": "block"
        }
    ]
}
EOF

echo /v2raybin/config.json
cat /v2raybin/config.json

cat <<-EOF > /caddybin/Caddyfile
https://0.0.0.0:${PORT}
{
	root /wwwroot
	index index.html
	timeouts none
	proxy ${V2_Path} localhost:10808 {
		websocket
		header_upstream -Origin
	}
}
EOF

cat <<-EOF > /v2raybin/vless.json
{
    "v": "2",
    "ps": "${AppName}.herokuapp.com",
    "add": "${AppName}.herokuapp.com",
    "port": "443",
    "id": "${UUID}",
    "encryption": "none",
    "net": "ws",
    "type": "none",
    "host": "",
    "path": "${V2_Path}",
    "tls": "tls"
}
EOF

if [ "$AppName" = "no" ]; then
  echo "Do not generate QR code"
else
  mkdir /wwwroot/${V2_QR_Path}
  vless="vless://$(cat /v2raybin/vless.json | base64 -w 0)"
  Linkbase64=$(echo -n "${vless}" | tr -d '\n' | base64 -w 0)
  echo "${Linkbase64}" | tr -d '\n' > /wwwroot/${V2_QR_Path}/index.html
  echo -n "${vless}" | qrencode -s 6 -o /wwwroot/${V2_QR_Path}/v2.png
fi

cd /v2raybin
./v2ray -config config.json &
cd /caddybin
./caddy -conf="Caddyfile"

