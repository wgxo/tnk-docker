#!/bin/sh

# exit on error
set -e

# COLORS
BROWN="\033[0;33m"; BLUE="\033[1;34m"; RED="\033[0;31m"; LIGHT_RED="\033[1;31m"; PURPLE="\033[1;35m"
GREEN="\033[1;32m"; WHITE="\033[1;37m"; LIGHT_GRAY="\033[0;37m"; YELLOW="\033[1;33m"; CYAN="\033[1;36m"
NOCOLOR="\033[0m"

die() {
    echo "${RED}ERROR: $@. Exiting.${NOCOLOR}"
    exit 1
}

msg()    echo "${RED}$@${NOCOLOR}"
green()  echo "${GREEN}$@${NOCOLOR}"
out()    echo "${BROWN}$@${NOCOLOR}"
blue()   echo "${BLUE}$@${NOCOLOR}"
yellow() echo "${YELLOW}$@${NOCOLOR}"
purple() echo "${PURPLE}$@${NOCOLOR}"
cyan()   echo "${CYAN}$@${NOCOLOR}"

BUILD=""
PAUSE=0
if [ $# -gt 0 -a "$1" = "-f" ]; then BUILD="--build"; fi
if [ $# -gt 0 -a "$1" = "-p" ]; then PAUSE=1; fi

pause() {
    if [ $PAUSE -eq 1 ]; then
	yellow "Press ENTER to continue..."
	read key <&1
    fi
}

echo "${LIGHT_RED}*** SETTING UP AND DEPLOYING TNK ***${NOCOLOR}"

echo

(command -v kvpncsvc >/dev/null 2>&1 && out " - Kerio VPN is installed") || die "Kerio VPN is not installed!"
(command -v docker >/dev/null 2>&1 && out " - Docker is installed") || die "Docker is not installed!"
(command -v docker-compose >/dev/null 2>&1 && out " - Docker compose is installed") || die "Docker Compose is not installed!"
(command -v git >/dev/null 2>&1 && out " - Git is installed") || die "Git is not installed!"

echo
msg " > Kerio VPN is needed to pull the docker images from private repositories."
msg " > Also docker-compose complains about creating networks when the VPN is running."
msg " > If this issue occurs, just stop/start the VPN and run this script again."
echo

if [ -z $(grep -Poe '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(?=.*brewfictus.kayako.com)' /etc/hosts) ]; then
    out " - Setting up hosts file"
    sudo bash -c 'echo "127.0.0.1 brewfictus.kayako.com" >> /etc/hosts'
else
    out " - brewfictus.kayako.com is configured in /etc/hosts"
fi

out    " - Cloning repositories:"

purple "   - package-product"
[ -d package-product/.git ] || (git clone --single-branch --branch develop git@github.com:trilogy-group/kayako-package-product package-product >/dev/null && cd package-product && git submodule init >/dev/null && git submodule update --remote >/dev/null && pause) || die "Cannot clone repository"

purple "   - frontend-cp"
[ -d frontendcp/.git ] || (git clone --single-branch --branch develop git@github.com:trilogy-group/kayako-frontend-cp frontendcp >/dev/null && pause) || die "Cannot clone repository"

purple "   - package-backend"
[ -d package-backend/.git ] || (git clone git@github.com:trilogy-group/kayako-package-backend package-backend >/dev/null && pause) || die "Cannot clone repository"

purple "   - package-billing"
[ -d package-billing/.git ] || (git clone git@github.com:trilogy-group/kayako-package-billing package-billing >/dev/null && pause) || die "Cannot clone repository"

purple "   - aladdin"
[ -d aladdin/.git ] || (git clone git@github.com:trilogy-group/kayako-aladdin aladdin >/dev/null && pause) || die "Cannot clone repository"

out " - Fixing brewfictus hostname"
grep -rl brewfictus.kayakodev.com * 2>/dev/null | while read f; do
    # ignore ths script
    (echo $f | grep -q `basename $0`) || (blue "   - $f" && perl -pi -e 's[brewfictus.kayakodev.com][brewfictus.kayako.com]' $f)
done

pause

out " - Creating .env file"
cat <<EOF > aladdin/.env
# TNK Code
CODE_PATH=`pwd`/package-product 

# Projects that will be added next
# my.kayako.com
BACKEND_PATH=`pwd`/package-backend
# billing.kayako.com
BILLING_PATH=`pwd`/package-billing
EOF

pause

out " - Preparing frontend-cp"
cat <<EOF > frontendcp/entrypoint.sh
yarn install
bower --allow-root install
ember s -H 0.0.0.0 --ssl false --proxy https://web
EOF

chmod +x frontendcp/entrypoint.sh

cat <<EOF > frontendcp/docker-compose.yml
version: '3'
services:
  frontend-cp:
    container_name: frontendcp
    image: registry2.swarm.devfactory.com/kayako/jenkins-frontend:latest
    ports:
     - "4200:4200"
    command: /bin/sh /app/entrypoint.sh
    volumes:
     - .:/app
    working_dir: /app
    networks:
      default:
        aliases:
          - brewfictus.kayako.com
EOF

pause

out " - Starting frontend-cp"

(cd frontendcp && (docker-compose up --no-start >/dev/null || die "Unable to build frontend-cp. Check your VPN") && (docker-compose up -d || die "Unable to build frontend-cp. Check your VPN"))

pause

out " - Configuring nginx"
sed -i 's/proxy_pass http.*\:4200;/proxy_pass http\:\/\/frontendcp\:4200;/' aladdin/nginx/product.conf

out " - Updating aladdin/docker-compose.yml"
grep -q frontendcp_default aladdin/docker-compose.yml || ( \
perl -pi -e 's[networks:][external_links:\n     - frontendcp\n    networks:\n      frontendcp_default:]gs' aladdin/docker-compose.yml
cat <<EOF >> aladdin/docker-compose.yml )

networks:
  frontendcp_default:
    external: true
EOF

pause

out " - Starting aladdin"

(cd aladdin && (docker-compose up --no-start >/dev/null || die "Unable to build aladdin. Check your VPN") && (docker-compose up -d || die "Unable to build frontend-cp. Check your VPN"))

pause

out " - Rebuilding database"
sleep 5 # wait for container to be ready
(cd aladdin && (docker-compose exec -T db mysql -u root -pOGYxYmI1OTUzZmM -e 'drop database if exists `brewfictus.kayako.com`; create database `brewfictus.kayako.com` character set = utf8mb4 collate = utf8mb4_unicode_ci;' || die "Cannot setup database. Check the container status"))

out " - Flushing redis"
(cd aladdin && (docker-compose exec -T redis ash -c 'redis-cli flushall' || die "Cannot flush redis"))

pause

out " - Setting up TNK"
(cd aladdin && (docker-compose exec -T product bash -c 'cd /var/www/html/product/setup && php console.setup.php "Brewfictus" "brewfictus.kayako.com" "Brewfictus" "admin@kayako.com" "setup"' || die "Cannot setup TNK"))

green "SUCCESS!!"
