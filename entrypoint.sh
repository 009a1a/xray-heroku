#! /bin/bash
set -ex
if [[ -z "${VER}" ]]; then
  VER="latest"
fi
echo ${VER}

if [[ -z "${vmess_UUID}" ]]; then
  UUID="86d9b8a7-9dfa-42f4-b9ac-f6b9a9beacda"
fi
echo ${vmess_UUID}

if [[ -z "${vmess_AlterID}" ]]; then
  AlterID="64"
fi
echo ${vmess_AlterID}

if [[ -z "${vmess_Path}" ]]; then
  vmess_Path="/static"
fi
echo ${vmess_Path}

if [[ -z "${vmess_QR_Path}" ]]; then
  vmess_QR_Path="qr_img"
fi
echo ${vmess_QR_Path}

if [[ -z "${Vless_UUID}" ]]; then
  Vless_UUID="5c301bb8-6c77-41a0-a606-4ba11bbab084"
fi
echo ${Vless_UUID}

if [[ -z "${Vless_Path}" ]]; then
  Vless_Path="/static"
fi
echo ${Vless_Path}

if [[ -z "${vless_QR_Path}" ]]; then
  vless_QR_Path="qr_img"
fi
echo ${vless_QR_Path}

rm -rf /etc/localtime
ln -sf /usr/share/zoneinfo/Europe/UnitedKingdom/etc/localtime
date -R

if [ "$VER" = "latest" ]; then
  XRAY_URL="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-32.zip"
else
  X_VER="v$VER"
  XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/$V_VER/Xray-linux-32.zip"
fi

if [ "$VER" = "latest" ]; then
  XRAY_URL="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip"
else
  X_VER="v$VER"
  XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/$V_VER/Xray-linux-64.zip"
fi

X_VER="latest"
mkdir /Xraybin
cd /Xraybin
echo ${XRAY_URL}
wget --no-check-certificate -qO 'Xray.zip' ${XRAY_URL}
unzip Xray.zip
rm -rf Xray.zip
chmod +x Xray

server {
    listen       ${PORT};
    listen       [::]:${PORT};

    root /wwwroot;

    resolver 8.8.8.8:53;
    location / {
        proxy_pass https://${ProxySite};
    }
    
    location ${Share_Path} {
        root /wwwroot;
    }

    location = ${Vless_Path} {
        if ($http_upgrade != "websocket") { # WebSocket协商失败时返回404
            return 404;
        }
        proxy_redirect off;
        proxy_pass http://127.0.0.1:12345;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
        # Show real IP in access.log
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location = ${Vmess_Path} {
        if ($http_upgrade != "websocket") { # WebSocket协商失败时返回404
            return 404;
        }
        proxy_redirect off;
        proxy_pass http://127.0.0.1:12346;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
        # Show real IP in access.log
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

cd /wwwroot
tar xvf wwwroot.tar.gz
rm -rf wwwroot.tar.gz

cat <<-EOF > /etc/Xraybin/config.json
{
    "log":{
        "loglevel":"warning"
    },
"inbounds": [
        {
            "listen": "0.0.0.0",
            "port": 12346,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "${Vless_UUID}"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "acceptProxyProtocol": false,
                    "path": "${Vless_Path}"
                }
            }
        },
        {
            "listen": "0.0.0.0",
            "port": 12346,
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                    "id": "${Vmess_UUID}",
                    "level": 0,
                    "alterId": 0,
                    "email": "love@xray.com"
                    }
                ],
                "disableInsecureEncryption": false
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "acceptProxyProtocol": false,
                    "path": "${Vmess_Path}"
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        },
        {
            "protocol": "blackhole",
            "tag": "block"
        }
    ]
}
EOF                          

echo /etc/Xraybin/config.json
cat /etc/Xraybin/config.json

cat <<-EOF > /caddybin/Caddyfile
http://0.0.0.0:${PORT}
{
	root /wwwroot
	index index.html
	timeouts none
	proxy ${X_Path} localhost:12346 {
		websocket
		header_upstream -Origin
	}
}
EOF

cat <<-EOF > /etc/Xraybin/vmess.json
{
    "x": "ray",
    "ps": "${AppName}.herokuapp.com",
    "add": "${AppName}.herokuapp.com",
    "port": "443",
    "id": "${UUID}",
    "aid": "${AlterID}",
    "net": "ws",
    "type": "none",
    "host": "",
    "path": "${Vmess_Path}",
    "tls": "tls"
}
EOF

cat <<-EOF > /etc/Xraybin/vless.json
{
    "x": "ray",
    "ps": "${AppName}.herokuapp.com",
    "add": "${AppName}.herokuapp.com",
    "port": "443",
    "id": "${UUID}",
    "decryption": "none"
    "net": "ws",
    "type": "none",
    "host": "",
    "path": "${Vless_Path}",
    "tls": "tls"
}
EOF

if [ "$AppName" = "no" ]; then
  echo "Do not generate QR code"
else
  mkdir /wwwroot/${vmess_QR_Path}
  vmess="vmess://$(cat /xraybin/vmess.json | base64 -w 0)"
  Linkbase64=$(echo -n "${vmess}" | tr -d '\n' | base64 -w 0)
  echo "${Linkbase64}" | tr -d '\n' > /wwwroot/${vmess_QR_Path}/index.html
  echo -n "${vmess}" | qrencode -s 6 -o /wwwroot/${vmess_QR_Path}/vmess.png
else
  mkdir /wwwroot/${vless_QR_Path}
  vless="vless://$(cat /etc/xraybin/vless.json | base64 -w 0)"
  Linkbase64=$(echo -n "${vless}" | tr -d '\n' | base64 -w 0)
  echo "${Linkbase64}" | tr -d '\n' > /wwwroot/${vless_QR_Path}/index.html
  echo -n "${vless}" | qrencode -s 6 -o /wwwroot/${vless_QR_Path}/vless.png
fi

cd /Xraybin
./Xray -config config.json &
cd /caddybin
./caddy -conf="Caddyfile"
