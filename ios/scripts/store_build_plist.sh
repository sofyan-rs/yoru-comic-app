#!/bin/sh
# Xcode build phase (Runner → "Store build Info.plist"). In a store build
# (--dart-define=STORE_BUILD=true, AppVariables.storeBuild) the app has no
# self-update, so the built Info.plist drops the URL schemes of the
# sideloading stores (altstore, sidestore) the updater opens.
#
# Flutter passes the dart-defines to Xcode as DART_DEFINES: base64 values,
# comma-separated (Generated.xcconfig). The phase runs before code signing.
set -e

store=0
old_ifs=$IFS
IFS=','
for define in $DART_DEFINES; do
  if [ "$(printf '%s' "$define" | /usr/bin/base64 --decode 2>/dev/null)" = "STORE_BUILD=true" ]; then
    store=1
  fi
done
IFS=$old_ifs

[ "$store" = 1 ] || exit 0

plist="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
if /usr/libexec/PlistBuddy -c "Print :LSApplicationQueriesSchemes" "$plist" >/dev/null 2>&1; then
  /usr/libexec/PlistBuddy -c "Delete :LSApplicationQueriesSchemes" "$plist"
  echo "Store build: removed LSApplicationQueriesSchemes from $plist"
fi
