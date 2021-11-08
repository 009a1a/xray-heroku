#!/bin/bash

set -ex
if [[ -z "${VER}" ]]; then
  VER="latest"
fi
echo ${VER}

if [[ -z "${Vless_Path}" ]]; then
  Vless_Path="/s233"
fi
echo ${Vless_Path}

if [[ -z "${Vless_UUID}" ]]; then
  Vless_UUID="5c301bb8-6c77-41a0-a606-4ba11bbab084"
fi
echo ${Vless_UUID}

if [[ -z "${Vmess_Path}" ]]; then
  Vmess_Path="/s244"
fi
echo ${Vmess_Path}

if [[ -z "${Vmess_UUID}" ]]; then
  Vmess_UUID="5c301bb8-6c77-41a0-a606-4ba11bbab084"
fi
echo ${Vmess_UUID}

if [[ -z "${Share_Path}" ]]; then
  Share_Path="/share233"
fi
echo ${Share_Path}

rm -rf /etc/localtime
ln -sf /usr/share/zoneinfo/Europe/UnitedKingdom/etc/localtime
date -R

if [ "$VER" = "latest" ]; then
  XRAY_URL="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-32.zip"
else
  VER="v$VER"
  XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/${VER}/Xray-linux-32.zip"
fi

if [ "$VER" = "latest" ]; then
  XRAY_URL="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip"
else
  VER="v$VER"
  XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/${VER}/Xray-linux-64.zip"
fi

VER="latest"
mkdir /Xraybin
cd /Xraybin
echo ${XRAY_URL}
wget --no-check-certificate -qO 'Xray.zip' ${XRAY_URL}
unzip Xray.zip
rm -rf Xray.zip
chmod +x Xray
ls -al

cd /wwwroot
tar xvf wwwroot.tar.gz
rm -rf wwwroot.tar.gz

cat <<-EOF > /xraybin/config.json
{
    "log": {
        "loglevel": "warning"
    },
    "routing": {
        "domainStrategy": "AsIs",
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
    "inbounds": [
        {
            "listen": "0.0.0.0",
            "port": 12345,
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

echo /xraybin/config.json
cat /xraybin/config.json

if [[ -z "${ProxySite}" ]]; then
  s="s/proxy_pass/#proxy_pass/g"
  echo "site:use local wwwroot html"
else
  s="s|\${ProxySite}|${ProxySite}|g"
  echo "site: ${ProxySite}"
fi

cat <<-EOF > /nginxbin/Nginxfile
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
EOF

echo /etc/nginx/conf.d/ray.conf
cat /etc/nginx/conf.d/ray.conf

[ ! -d /wwwroot/${Share_Path} ] && mkdir -p /wwwroot/${Share_Path}
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport" content="width=device-width, initial-scale=1">

  <title>Letter - Simple Sign Up Form</title>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Open+Sans:300,400">  <!-- Google web font "Open Sans" -->
  <link rel="stylesheet" href="css/font-awesome.min.css">
  <link rel="stylesheet" href="css/bootstrap.min.css">
  
  <link rel="stylesheet" href="css/demo.css" />
  <link rel="stylesheet" href="css/templatemo-style.css">
  
  <script type="text/javascript" src="js/modernizr.custom.86080.js"></script>
		
	</head>

	<body>

			<div id="particles-js"></div>
		
			<ul class="cb-slideshow">
	            <li></li>
	            <li></li>
	            <li></li>
	            <li></li>
	            <li></li>
	            <li></li>
	        </ul>

			<div class="container-fluid">
				<div class="row cb-slideshow-text-container ">
					<div class= "tm-content col-xl-6 col-sm-8 col-xs-8 ml-auto section">
					<header class="mb-5"><h1>Letter</h1></header>
					<P class="mb-5">A sign-up letter template with three background images shuffling by fade in out movements. Thank you for visiting our site!</P>
					
                    <form action="#" method="get" class="subscribe-form">
               	    	<div class="row form-section">

							<div class="col-md-7 col-sm-7 col-xs-7">
			                      <input name="email" type="text" class="form-control" id="contact_email" placeholder="Your Email..." required/>
				  			</div>
							<div class="col-md-5 col-sm-5 col-xs-5">
								<button type="submit" class="tm-btn-subscribe">Subscribe</button>
							</div>
						
						</div>
                    </form>
                    
					<div class="tm-social-icons-container text-xs-center">
	                    <a href="#" class="tm-social-link"><i class="fa fa-facebook"></i></a>
	                    <a href="#" class="tm-social-link"><i class="fa fa-google-plus"></i></a>
	                    <a href="#" class="tm-social-link"><i class="fa fa-twitter"></i></a>
	                    <a href="#" class="tm-social-link"><i class="fa fa-linkedin"></i></a>
	                </div>

					</div>
				</div>	
				<div class="footer-link">
					<p>Copyright © 2018 Your Company 
                    
                    - Design: <a rel="nofollow" href="#" target="_parent">Templatemo</a></p>
                   
				</div>
			</div>	
	</body>

	<script type="text/javascript" src="js/particles.js"></script>
	<script type="text/javascript" src="js/app.js"></script>
</html>

echo /wwwroot/${Share_Path}/index.html
cat /wwwroot/${Share_Path}/index.html

cd /xraybin
./xray run -c ./config.json &
rm -rf /etc/nginx/sites-enabled/default
nginx -g 'daemon off;'






