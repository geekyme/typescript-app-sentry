#!/bin/bash

if [[ -z "${SENTRY_AUTH_TOKEN}" ]]; then
  echo "Please set the SENTRY_AUTH_TOKEN environment variable"
  exit 1
fi

if [[ -z "${SENTRY_URL}" ]]; then
  echo "Please set the SENTRY_URL environment variable"
  exit 1
fi

# allow script to work from any location
parentPath=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd $parentPath

# Ask the user for the release
releaseHistoryFile=history.txt
lastRelease=$( tail -n 1 $releaseHistoryFile )
if [ "$?" != "0" ]
then
  echo "Creating first release..."
  touch $releaseHistoryFile
  echo "done"
else
  echo "Last release was $lastRelease."
fi

echo "Please name current release"
read newRelease

echo $newRelease >> $releaseHistoryFile

cd ..

npm version $newRelease
npm run build

npx sentry-cli --auth-token $SENTRY_AUTH_TOKEN --url $SENTRY_URL releases -o sentry -p app new $newRelease

npx sentry-cli --auth-token $SENTRY_AUTH_TOKEN --url $SENTRY_URL releases -o sentry -p app files $newRelease upload-sourcemaps ./dist

npx sentry-cli --auth-token $SENTRY_AUTH_TOKEN --url $SENTRY_URL releases -o sentry -p app finalize $newRelease

