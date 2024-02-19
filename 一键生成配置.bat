@echo off
echo.
echo.
echo WELCOME
set /P SERVER="Domain: "
set /P PORT="Port: "


set /P PWD_TEMP="Password( 1 for Default ): "
if "%PWD_TEMP%"=="1" (
    set PWD=K33cQAXsTHwevdcToT5XN9+Fzll+
) else (
    set PWD=%PWD_TEMP%
)


set /P UP="Upload speed limit (mbps)( 1 for OFF & 2 for Default ): "
if "%UP%"=="1" (
    set SPEEDLIM=#
) else (
if "%UP%"=="2" (
set UP=50
set DOWN=200
) else (
    set SPEEDLIM=
    set /P DOWN="Download speed limit (mbps): "
)
)


(
echo.
echo server: %SERVER%:%PORT%
echo auth: %PWD%
echo.
echo %SPEEDLIM%bandwidth:
echo %SPEEDLIM%  up: %UP% mbps
echo %SPEEDLIM%  down: %DOWN% mbps
echo. 
echo tls:
echo   sni: bing.com
echo   insecure: true
echo.        
echo socks5: 
echo   listen: 127.0.0.1:1080
echo http: 
echo   listen: 127.0.0.1:8080
echo.   
) > PCcfgH2.json

echo.
echo.
echo Saved in "PEcfgH2.json" SUCCESS!
echo.
echo.

(
echo {
echo   "dns": {
echo     "servers": [
echo       {
echo         "tag": "cf",
echo         "address": "https://1.1.1.1/dns-query"
echo       },
echo       {
echo         "tag": "local",
echo         "address": "223.5.5.5",
echo         "detour": "direct"
echo       },
echo       {
echo         "tag": "block",
echo         "address": "rcode://success"
echo       }
echo     ],
echo     "rules": [
echo       {
echo         "geosite": "category-ads-all",
echo         "server": "block",
echo         "disable_cache": true
echo       },
echo       {
echo         "outbound": "any",
echo         "server": "local"
echo       },
echo       {
echo         "geosite": "cn",
echo         "server": "local"
echo       }
echo     ],
echo     "strategy": "ipv4_only"
echo   },
echo   "inbounds": [
echo     {
echo       "type": "tun",
echo       "inet4_address": "172.19.0.1/30",
echo       "auto_route": true,
echo       "strict_route": false,
echo       "sniff": true
echo     }
echo   ],
echo   "outbounds": [
echo     {
echo       "type": "hysteria2",
echo       "tag": "proxy",
echo       "server": "%SERVER%",
echo       "server_port": %PORT%,
echo       "up_mbps": %UP%,
echo       "down_mbps": %DOWN%,
echo       "password": "%PWD%",
echo       "tls": {
echo         "enabled": true,
echo         "server_name": "bing.com",
echo         "insecure": true
echo       }
echo     },
echo     {
echo       "type": "direct",
echo       "tag": "direct"
echo     },
echo     {
echo       "type": "block",
echo       "tag": "block"
echo     },
echo     {
echo       "type": "dns",
echo       "tag": "dns-out"
echo     }
echo   ],
echo   "route": {
echo     "rules": [
echo       {
echo         "protocol": "dns",
echo         "outbound": "dns-out"
echo       },
echo       {
echo         "geosite": "cn",
echo         "geoip": [
echo           "private",
echo           "cn"
echo         ],
echo         "outbound": "direct"
echo       },
echo       {
echo         "geosite": "category-ads-all",
echo         "outbound": "block"
echo       }
echo     ],
echo     "auto_detect_interface": true
echo   }
echo }
) > PEcfgH2.json

echo Saved in "PEcfgH2.json" SUCCESS!
echo.
echo.
pause
