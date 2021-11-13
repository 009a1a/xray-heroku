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

if [[ -z "${X_Path}" ]]; then
  X_Path="/static"
fi
echo ${X_Path}

if [[ -z "${X_QR_Path}" ]]; then
  X_QR_Path="qr_img"
fi
echo ${X_QR_Path}

rm -rf /etc/localtime
ln -sf /usr/share/zoneinfo/Europe/UnitedKingdom/etc/localtime
date -R

if [ "$VER" = "latest" ]; then
  XRAY_URL="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-32.zip"
else
  X_VER="v$VER"
  XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/$X_VER/Xray-linux-32.zip"
fi

if [ "$VER" = "latest" ]; then
  XRAY_URL="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip"
else
  X_VER="v$VER"
  XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/$X_VER/Xray-linux-64.zip"
fi

V_VER="latest"
mkdir /Xraybin
cd /Xraybin
echo ${XRAY_URL}
wget --no-check-certificate -qO 'Xray-linux-64.zip' ${XRAY_URL}
unzip Xray-linux-64.zip
rm -rf Xray-linux-64.zip
chmod +x Xray

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

cat <<-EOF > /Xraybin/config.json
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
        "listen":"8.8.8.8",
        "port":10808,
        "settings": {
                "clients": [
                    {
                        "id": "${vless_UUID}"
                    }
                ],
                "encryption": "none"
            },
            "streamSettings":{
                "network":"ws",
                "wsSettings":{
                    "path":"${X_Path}"
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

echo /Xraybin/config.json
cat /Xraybin/config.json

cat <<-EOF > /caddybin/Caddyfile
https://8.8.8.8:${PORT}
{
	root /wwwroot
	index index.html
	timeouts none
	proxy ${X_Path} localhost:10808 {
		websocket
		header_upstream -Origin
	}
}
EOF

cat <<-EOF > /Xraybin/vless.json
{
    "X": "ray",
    "ps": "${AppName}.herokuapp.com",
    "add": "${AppName}.herokuapp.com",
    "port": "443",
    "id": "${UUID}",
    "encryption": "none",
    "net": "ws",
    "type": "none",
    "host": "",
    "path": "${X_Path}",
    "tls": "tls"
}
EOF

if [ "$AppName" = "no" ]; then
  echo "Do not generate QR code"
else
  mkdir /wwwroot/${X_QR_Path}
  vless="vless://$(cat /Xraybin/vless.json | base64 -w 0)"
  Linkbase64=$(echo -n "${vless}" | tr -d '\n' | base64 -w 0)
  echo "${Linkbase64}" | tr -d '\n' > /wwwroot/${X_QR_Path}/index.html
  echo -n "${vless}" | qrencode -s 6 -o /wwwroot/${X_QR_Path}/X.png
fi

cd /Xraybin
./Xray run -config config.json &
cd /caddybin
./caddy -conf="Caddyfile"

