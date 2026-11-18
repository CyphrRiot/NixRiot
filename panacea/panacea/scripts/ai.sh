#!/bin/bash
#
cfg="$HOME/.config/panacea/settings.json"
q="$1"
[ -n "$q" ] || exit 1
url=$(jq -r '.aiUrl // ""' "$cfg" 2>/dev/null)
key=$(jq -r '.aiKey // ""' "$cfg" 2>/dev/null)
model=$(jq -r '.aiModel // ""' "$cfg" 2>/dev/null)
[ -n "$url" ] || { echo "ERROR not-configured"; exit 1; }
[ -n "$model" ] || { echo "ERROR no-model"; exit 1; }
case "$url" in */chat/completions) ;; *) url="${url%/}/chat/completions" ;; esac

body=$(jq -n --arg m "$model" --arg q "$q" '{
    model: $m,
    messages: [
        { role: "system", content: "You answer quick questions typed into a desktop app launcher. Be brief and direct: a few sentences at most, plain text. Answer in the language of the question." },
        { role: "user", content: $q }
    ]
}')
auth=()
[ -n "$key" ] && auth=(-H "Authorization: Bearer $key")
resp=$(curl -s -m 60 "$url" -H "Content-Type: application/json" "${auth[@]}" -d "$body") \
    || { echo "ERROR network"; exit 1; }

err=$(jq -r 'if (.error|type) == "object" then .error.message else (.error // empty) end' <<< "$resp" 2>/dev/null)
[ -n "$err" ] && { echo "ERROR $err"; exit 1; }
ans=$(jq -r '.choices[0].message.content // empty' <<< "$resp" 2>/dev/null)
[ -n "$ans" ] || { echo "ERROR bad-response"; exit 1; }
printf '%s\n' "$ans"
