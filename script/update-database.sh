#!/bin/sh

# https://devcenter.heroku.com/articles/upgrading-heroku-postgres-databases#upgrading-with-pg-copy

echo 'Heroku database update about to begin (using pg:copy mechanism)'

set -e

echo 'Name of Heroku app? (or control-C ENTER to stop)'
read -r APP

DATABASE_URL="$(heroku config:get DATABASE_URL --app "$APP")"
echo "Current DATABASE_URL=$DATABASE_URL"
echo

ADDON_LEVEL="$(heroku addons --app "$APP" | grep -- heroku-postgresql |
  sed -e 's/  */ /g' | cut -d ' ' -f 3)"
echo "PostgreSQL addon level=$ADDON_LEVEL"

heroku config:set SYSTEM_ANNOUNCEMENT='The system is about to pause for some database maintenance, will be up again soon.' --app "$APP"

echo 'Existing DATABASE_COLORNAMEs are:'
heroku config --app "$APP" | grep '^HEROKU_POSTGRESQL_'
echo 'Enter name of current database colorname (DATABASE_OLD_COLORNAME):'
read -r DATABASE_OLD_COLORNAME

echo "Press ENTER to begin update (control-C ENTER to halt database update)."
# shellcheck disable=SC2034
read -r wait

echo  'Starting database creation.'
heroku addons:create heroku-postgresql:"$ADDON_LEVEL" --app "$APP"
echo  'Waiting - NOTICE the NEW colorname!!'
heroku pg:wait --app "$APP"
heroku maintenance:on --app "$APP"

echo 'Possible new DATABASE_COLORNAMEs are:'
heroku config --app "$APP" | grep '^HEROKU_POSTGRESQL_'

echo 'Enter *new* DATABASE_COLORNAME (e.g., HEROKU_POSTGRESQL_PINK):'
read -r DATABASE_NEW_COLORNAME

echo 'Waiting before turning off web and workers'
sleep 10
heroku ps:scale web=0 worker=0 --app "$APP"

echo "Copying to ${DATABASE_NEW_COLOR_NAME}"
heroku pg:copy "$DATABASE_URL" "$DATABASE_NEW_COLORNAME" --app "$APP" \
       --confirm "$APP"
echo 'Promoting.'
heroku pg:promote "$DATABASE_NEW_COLORNAME" --app "$APP"
heroku 'config:unset' 'SYSTEM_ANNOUNCEMENT' --app "$APP"

echo 'Enabling web and worker at scale 1 (do you need a larger scale?)'
heroku ps:scale web=1 worker=1 --app "$APP"

echo 'Disabling maintenance; site should soon be accessible.'
heroku maintenance:off --app "$APP"

echo 'Check that everything works. If so, press ENTER to destroy old database'
echo "About to destroy $DATABASE_OLD_COLORNAME:"
# shellcheck disable=SC2034
read -r wait
heroku addons:destroy "$DATABASE_OLD_COLORNAME" --app "$APP" \
       --confirm "$APP"

echo 'Done.'
