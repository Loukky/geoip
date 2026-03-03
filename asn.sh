#!/usr/bin/env bash

input="./asn.csv"
mkdir -p ./tmp ./data

while IFS= read -r line; do
  filename=$(echo ${line} | awk -F ',' '{print $1}')
  IFS='|' read -r -a asns <<<$(echo ${line} | awk -F ',' '{print $2}')
  file="data/${filename}"

  echo "==================================="
  echo "Generating ${filename} CIDR list..."
  rm -rf ${file} && touch ${file}
  # for asn in ${asns[@]}; do
  #   url="https://stat.ripe.net/data/ris-prefixes/data.json?list_prefixes=true&types=o&resource=${asn}"
  #   echo "-----------------------"
  #   echo "Fetching ${asn}..."
  #   curl -sL ${url} -o ./tmp/${filename}-${asn}.txt \
  #     -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36'
  #   jq --raw-output '.data.prefixes.v4.originating[]' ./tmp/${filename}-${asn}.txt | sort -u >>${file}
  #   jq --raw-output '.data.prefixes.v6.originating[]' ./tmp/${filename}-${asn}.txt | sort -u >>${file}
  # done
  for asn in "${asns[@]}"; do
  url="https://stat.ripe.net/data/ris-prefixes/data.json?list_prefixes=true&types=o&resource=${asn}"
  response="./tmp/${filename}-${asn}.txt"

  echo "-----------------------"
  echo "Fetching ${asn}..."

  if ! curl -sL \
    --connect-timeout 5 \
    --max-time 20 \
    --retry 3 \
    --retry-delay 2 \
    --retry-connrefused \
    --fail \
    -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36' \
    "${url}" \
    -o "${response}"; then
      echo "Request failed or timed out for ${asn}, skipping..."
      continue
  fi

  if ! jq empty "${response}" 2>/dev/null; then
    echo "Invalid JSON returned for ${asn}, skipping..."
    continue
  fi

  jq --raw-output '.data.prefixes.v4.originating[]?' "${response}" >>"${file}"
  jq --raw-output '.data.prefixes.v6.originating[]?' "${response}" >>"${file}"
done
done <${input}
