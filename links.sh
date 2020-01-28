#!/bin/bash

for dir in admin agent api console cron desktop geoip index.php intranet oauth service setup __src staffapi standards tests visitor winapp worker
do
    ln -fs "./Novo/novo/$dir" "$dir"
done

mkdir -p __apps
mkdir -p __config
mkdir -p __data/cache
mkdir -p __data/files
mkdir -p __data/logs
mkdir -p __data/tmp

for app in account base cases chat facebook frontend helpcenter insights mail reports search social twitter widget
do
    if [ "$app" = "cases" ] || [ "$app" = "mail" ] || [ "$app" == "social" ]
    then
        ln -fs "../Novo/apps/$app" "__apps/$app"
    else
        ln -fs "../Novo/app-$app" "__apps/$app"
    fi
done
