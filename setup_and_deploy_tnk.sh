#!/bin/sh

# COLORS
BROWN="\033[0;33m"; BLUE="\033[1;34m"; RED="\033[0;31m"; LIGHT_RED="\033[1;31m"; PURPLE="\033[1;35m"
GREEN="\033[1;32m"; WHITE="\033[1;37m"; LIGHT_GRAY="\033[0;37m"; YELLOW="\033[1;33m"; CYAN="\033[1;36m"
NOCOLOR="\033[0m"

die() {
    echo "${RED}ERROR: $@. Exiting.${NOCOLOR}"
    exit 1
}

green()  echo "${GREEN}$@${NOCOLOR}"
out()    echo "${BROWN}$@${NOCOLOR}"
blue()   echo "${BLUE}$@${NOCOLOR}"
yellow() echo "${YELLOW}$@${NOCOLOR}"
purple() echo "${PURPLE}$@${NOCOLOR}"
cyan()   echo "${CYAN}$@${NOCOLOR}"

blue "*** SETTING UP AND DEPLOYING TNK ***"

(command -v docker >/dev/null 2>&1 && out " - Docker is installed") || die "Docker is not installed!"
(command -v docker-compose >/dev/null 2>&1 && out " - Docker compose is installed") || die "Docker Compose is not installed!"
(command -v git >/dev/null 2>&1 && out " - Git is installed") || die "Git is not installed!"

if [ -z $(grep -Poe '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(?=.*brewfictus.kayako.com)' /etc/hosts) ]; then
    out " - Setting up hosts file"
    sudo bash -c 'echo "127.0.0.1 brewfictus.kayako.com" >> /etc/hosts'
else
    out " - brewfictus.kayako.com is configured in /etc/hosts"
fi

out    " - Cloning repositories:"

purple "   - aladdin"
[ -d aladdin/.git ] || git clone git@github.com:trilogy-group/kayako-aladdin aladdin >/dev/null || die "Cannot clone repository"

purple "   - novo-api"
[ -d novo-api/.git ] || git clone git@github.com:trilogy-group/kayako-novo-api novo-api >/dev/null || die "Cannot clone repository"

purple "   - app-frontend"
[ -d novo-api/Novo/app-frontend/.git ] || git clone git@github.com:trilogy-group/kayako-app-frontend novo-api/Novo/app-frontend >/dev/null || die "Cannot clone repository"

purple "   - app-widget"
[ -d novo-api/Novo/app-widget/.git ] || git clone git@github.com:trilogy-group/kayako-app-widget novo-api/Novo/app-widget >/dev/null || die "Cannot clone repository"

purple "   - realtime-engine"
[ -d realtime-engine/.git ] || git clone git@github.com:trilogy-group/kayako-realtime-engine realtime-engine >/dev/null || die "Cannot clone repository"

purple "   - novo-relay"
[ -d novo-relay/.git ] || git clone git@github.com:trilogy-group/kayako-novo-relay novo-relay >/dev/null || die "Cannot clone repository"

purple "   - service-purify"
[ -d service-purify/.git ] || git clone git@github.com:trilogy-group/kayako-service-purify service-purify >/dev/null || die "Cannot clone repository"

purple "   - novobean"
[ -d novobean/.git ] || git clone git@github.com:trilogy-group/kayako-novobean novobean >/dev/null || die "Cannot clone repository"


cd novo-api

out " - Updating submodules"
[ -f Novo/app-account/.git ] || (git submodule init && git submodule update --remote || die "Cannot initialize submodules")

out " - Setting up symbolic links"
./links.sh

cd ../aladdin

out " - Fixing brewfictus hostname"
grep -rl brewfictus.kayako.com ../* 2>/dev/null | while read f; do
    perl -pi -e 's[brewfictus.kayako.com][brewfictus.kayako.com]' $f
done

out " - Copying config files"
cp -fva configs/novo-api/* ../novo-api/__config/ | sed -e 's/^.*\///' -e "s/'//" 

out " - Creating .env file"
cat <<EOF > .env
CODE_PATH=../novo-api
# here to stop docker complaining that the variable is not set
BLACKFIRE_CLIENT_ID=
BLACKFIRE_CLIENT_TOKEN=
BLACKFIRE_SERVER_ID=
BLACKFIRE_SERVER_TOKEN=
EOF

out " - Updating docker-compose file"
perl -pi -e 's[context: ../kayako-realtime-engine][context: ../realtime-engine]' docker-compose.yml
perl -pi -e 's[context: ../relay][context: ../novo-relay]' docker-compose.yml

out " - Updating php container reference in site.conf"
perl -pi -e 's[php5:9000][php:9000]' web/site.conf

out " - Building web container"
docker-compose up -d --build web || die "Cannot start web container"

out " - Rebuilding database"
docker-compose exec -T db mysql -u root -pOGYxYmI1OTUzZmM -e 'drop database if exists `brewfictus.kayako.com`; create database `brewfictus.kayako.com`;' || die "Cannot setup database"
docker-compose exec -T redis ash -c 'redis-cli flushall' || die "Cannot flush redis"

out " - Setting up TNK"
docker-compose exec -T php bash -c 'cd /var/www/html/product/setup && php console.setup.php "Brewfictus" "brewfictus.kayako.com" "Brewfictus" "admin@kayako.com" "setup"' || die "Cannot setup TNK"

green "SUCCESS!!"
