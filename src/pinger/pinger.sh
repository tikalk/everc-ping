#!/bin/sh
INTERVAL=${1:-1}
MSA_API_SERVICE_HOST=${2:-"api"}
MSA_API_SERVICE_PORT=${3:-"8080"}

API_URL="${MSA_API_SERVICE_HOST}:${MSA_API_SERVICE_PORT}"
echo "piniging API_URL -> $API_URL every ${INTERVAL} sec ..."

while true; do
	[[ "${DEBUG}" = "true" ]]
	curl -s -X POST "${API_URL}/ping" && echo "Incremented ping by 1"
	sleep ${INTERVAL}
done
