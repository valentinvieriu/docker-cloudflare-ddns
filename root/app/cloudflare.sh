#!/usr/bin/with-contenv sh

cloudflare() {
  if [ -z "$EMAIL" ]; then
      curl -sSL \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $API_KEY" \
      "$@"
  else
      curl -sSL \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      -H "X-Auth-Email: $EMAIL" \
      -H "X-Auth-Key: $API_KEY" \
      "$@"
  fi
}

getLocalIpAddress() {
    IP_ADDRESS=$(ip addr show $INTERFACE | awk '$1 == "inet" {gsub(/\/.*$/, "", $2); print $2}')
    
    echo $IP_ADDRESS
}

getPublicIpAddress() {
  if [ "$RRTYPE" == "A" ]; then
    # try dns method first.
    IP_ADDRESS=$(dig +short @1.1.1.1 ch txt whoami.cloudflare | tr -d '"')

    # if dns method fails, use http method
    if [ "$IP_ADDRESS" = "" ]; then
      IP_ADDRESS=$(curl -sf4 https://ipinfo.io | jq -r '.ip')
    fi

    echo $IP_ADDRESS
  elif [ "$RRTYPE" == "AAAA" ]; then
    # try dns method first.
    IP_ADDRESS=$(dig +short @2606:4700:4700::1111 -6 ch txt whoami.cloudflare | tr -d '"')

    # if dns method fails, use http method
    if [ "$IP_ADDRESS" = "" ]; then
      IP_ADDRESS=$(curl -sf6 https://ifconfig.co)
    fi

    echo $IP_ADDRESS
  fi
}

getDnsRecordName() {
  if [ ! -z "$SUBDOMAIN" ]; then
    echo $SUBDOMAIN.$ZONE
  else
    echo $ZONE
  fi
}

verifyToken() {
  if [ -z "$EMAIL" ]; then
    cloudflare -o /dev/null -w "%{http_code}" "$CF_API"/user/tokens/verify
  else
    cloudflare -o /dev/null -w "%{http_code}" "$CF_API"/user
  fi
}

getZoneId() {
  cloudflare "$CF_API/zones?name=$ZONE" | jq -r '.result[0].id'
}

getDnsRecordId() {
  cloudflare "$CF_API/zones/$1/dns_records?type=$RRTYPE&name=$2" | jq -r '.result[0].id'
}

createDnsRecord() {
  if [[ "$PROXIED" != "true" && "$PROXIED" != "false" ]]; then
    PROXIED="false"
  fi

  cloudflare -X POST -d "{\"type\": \"$RRTYPE\",\"name\":\"$2\",\"content\":\"$3\",\"proxied\":$PROXIED,\"ttl\":180 }" "$CF_API/zones/$1/dns_records" | jq -r '.result.id'
}

updateDnsRecord() {
  if [[ "$PROXIED" != "true" && "$PROXIED" != "false" ]]; then
    PROXIED="false"
  fi

  cloudflare -X PUT -d "{\"type\": \"$RRTYPE\",\"name\":\"$3\",\"content\":\"$4\",\"proxied\":$PROXIED,\"ttl\":180 }" "$CF_API/zones/$1/dns_records/$2" | jq -r '.result.id'
}

deleteDnsRecord() {
  cloudflare -X DELETE "$CF_API/zones/$1/dns_records/$2" | jq -r '.result.id'
}

getDnsRecordIp() {
  cloudflare "$CF_API/zones/$1/dns_records/$2" | jq -r '.result.content'
}
