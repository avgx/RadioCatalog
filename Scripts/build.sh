#!/bin/bash
set -e

echo "Downloading..."
#curl -s "https://de2.api.radio-browser.info/json/stations?hidebroken=true&limit=100000&order=votes&reverse=true" | jq . > offline.json

echo "Building..."
swift build -c release --product radiocatalog-builder

#swift run radiocatalog-builder $TMP stations
.build/release/radiocatalog-builder offline.json stations

echo "Zipping..."

zip stations-small.zip stations-small.json
zip stations-medium.zip stations-medium.json
zip stations-large.zip stations-large.json

echo "Done"
