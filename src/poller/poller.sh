#!/bin/sh
MSA_API_SERVICE_HOST=${1:-"api"}
MSA_API_SERVICE_PORT=${2:-"8080"}
API_URL="${MSA_API_SERVICE_HOST}:${MSA_API_SERVICE_PORT}"
echo "polling API_URL -> $API_URL"

while true; do
	[[ "${DEBUG}" = "true" ]]
	curl -s "${API_URL}/"
	sleep ${3:-1}
done
