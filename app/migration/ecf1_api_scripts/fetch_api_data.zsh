#!/bin/zsh

# inputs are:
# -o outputpath
# -k apikey
# -u uri for api end point
# -p page number
# -P items per-page number
#

page=1
per_page=3000

while [[ "$#" -gt 0 ]]
do case $1 in
    -o|--outputpath) output_path="$2"
    shift;;
    -k|--key) api_key="$2"
    shift;;
    -u|--uri) api_uri="$2"
    shift;;
    -p|--page) page="$2"
    shift;;
    -P|--per-page) per_page="$2"
esac
shift
done

if [[ -z $output_path ]]; then
  echo "-o|--outputpath <path> is required"
  exit 1
elif [[ -z $api_key ]]; then
  echo "-k|--key <api-key> is required"
  exit 1
elif [[ -z $api_uri ]]; then
  echo "-u|--uri <api-uri> is required"
  exit 1
fi

mkdir -p $output_path

echo "Reading data from: [${api_uri}]"

while true; do
  file="${output_path}/page${page}.json"
  echo "Writing ${file}"

  curl -sS "${api_uri}?page\[page\]=${page}&page\[per_page\]=${per_page}" -H "Accept: application/json" -H "Authorization: Bearer ${api_key}" | jq '.' > $file

  len=`jq '.data | length' $file`
  if [ $len -lt $per_page ]; then
    break
  fi
  ((page++))
done

echo "📚 Combining and sorting..."
jq -s '[.[].data[]] | { data: sort_by(.id) }' ${output_path}/page*.json > "${output_path}/combined.json"
