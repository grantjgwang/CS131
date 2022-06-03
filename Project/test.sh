#!/usr/bin/bash

set -e

sed -i '/MAPS_API_URL/d' server.py
sed -i '/MAPS_API_KEY/d' server.py

sed -i '1iMAPS_API_URL = "http://example.com/"' server.py
sed -i '1iMAPS_API_KEY = "some_api_key"' server.py