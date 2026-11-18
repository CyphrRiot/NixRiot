#!/usr/bin/env bash
#
#
#
set -u

command -v jq >/dev/null 2>&1 || { printf '{"agents":[],"error":"jq"}\n'; exit 0; }

iso_ms() {
    [ -n "${1:-}" ] && [ "$1" != "null" ] || { echo "0"; return; }
    date -d "$1" +%s%3N 2>/dev/null || echo "0"
}

# ------------------------------------------------------------------ claude
claude_json() {
    local cfg="$HOME/.claude.json"
    local bin; bin="$(command -v claude 2>/dev/null)"
    [ -n "$bin" ] || [ -f "$cfg" ] || return 1

    local ver=""
    [ -n "$bin" ] && ver="$("$bin" --version 2>/dev/null | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')"

    local plan="" raw="" fetched=0
    if [ -f "$cfg" ]; then
        raw="$(jq -r '.oauthAccount.organizationType // ""' "$cfg" 2>/dev/null)"
        fetched="$(jq -r '.cachedUsageUtilization.fetchedAtMs // 0' "$cfg" 2>/dev/null)"
    fi

    case "$raw" in
        claude_pro)        plan="Claude Pro" ;;
        claude_max_5x)     plan="Claude Max 5x" ;;
        claude_max_20x)    plan="Claude Max 20x" ;;
        claude_team)       plan="Claude Team" ;;
        claude_enterprise) plan="Claude Enterprise" ;;
        "")                plan="" ;;
        *)                 plan="$(printf '%s' "$raw" | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')" ;;
    esac

    local acct cacheAcct
    acct="$(jq -r '.oauthAccount.accountUuid // ""' "$cfg" 2>/dev/null)"
    cacheAcct="$(jq -r '.cachedUsageUtilization.accountUuid // ""' "$cfg" 2>/dev/null)"

    local limits='[]'
    if [ -f "$cfg" ] && [ -n "$cacheAcct" ] && [ "$cacheAcct" = "$acct" ]; then
        #
        limits="$(jq -c '
            (.cachedUsageUtilization.utilization) as $u
            | if (($u.limits // []) | length) > 0 then
                [ $u.limits[]
                  | select(.percent != null)
                  | { kind: (.kind // "unknown"),
                      percent: (.percent | floor),
                      severity: (.severity // "normal"),
                      resetsAtIso: (.resets_at // "") } ]
              else
                [ { kind: "session",    v: $u.five_hour },
                  { kind: "weekly_all", v: $u.seven_day } ]
                | map(select(.v != null and .v.utilization != null))
                | map({ kind: .kind,
                        percent: (.v.utilization | floor),
                        severity: "normal",
                        resetsAtIso: (.v.resets_at // "") })
              end
        ' "$cfg" 2>/dev/null)" || limits='[]'
    fi
    [ -n "$limits" ] && [ "$limits" != "null" ] || limits='[]'

    local note=""
    [ "$limits" = "[]" ] && note="nodata"

    local out='[]' i=0 n
    n="$(printf '%s' "$limits" | jq 'length')"
    while [ "$i" -lt "${n:-0}" ]; do
        local one iso ms
        one="$(printf '%s' "$limits" | jq -c ".[$i]")"
        iso="$(printf '%s' "$one" | jq -r '.resetsAtIso')"
        ms="$(iso_ms "$iso")"
        out="$(printf '%s' "$out" | jq -c --argjson one "$one" --argjson ms "${ms:-0}" \
               '. + [ ($one | del(.resetsAtIso) | .resetsAt = $ms) ]')"
        i=$((i + 1))
    done

    jq -cn --arg name "Claude Code" --arg ver "$ver" --arg plan "$plan" \
           --arg note "$note" \
           --argjson fetched "${fetched:-0}" --argjson limits "$out" '
        { id: "claude", name: $name, version: $ver, plan: $plan,
          note: $note, fetchedAt: $fetched, limits: $limits }'
}

# -------------------------------------------------------------------- codex
codex_plan() {
    local auth="$HOME/.codex/auth.json"
    [ -f "$auth" ] || return 0
    local tok; tok="$(jq -r '.tokens.id_token // ""' "$auth" 2>/dev/null)"
    [ -n "$tok" ] && [ "$tok" != "null" ] || return 0

    local body; body="$(printf '%s' "$tok" | cut -d. -f2)"
    [ -n "$body" ] || return 0
    case $(( ${#body} % 4 )) in 2) body="$body==" ;; 3) body="$body=" ;; esac

    local raw; raw="$(printf '%s' "$body" | tr '_-' '/+' | base64 -d 2>/dev/null \
        | jq -r '.["https://api.openai.com/auth"].chatgpt_plan_type // ""' 2>/dev/null)"
    case "$raw" in
        plus)  echo "ChatGPT Plus" ;;
        pro)   echo "ChatGPT Pro" ;;
        team)  echo "ChatGPT Team" ;;
        enterprise) echo "ChatGPT Enterprise" ;;
        free)  echo "ChatGPT Free" ;;
        "")    ;;
        *)     printf 'ChatGPT %s\n' "$(printf '%s' "$raw" | sed 's/\b\(.\)/\u\1/g')" ;;
    esac
}

#
other_agent() {
    local bin="$1" name="$2" plan="${3:-}"
    command -v "$bin" >/dev/null 2>&1 || return 1
    local ver; ver="$("$bin" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)"
    jq -cn --arg id "$bin" --arg name "$name" --arg ver "$ver" --arg plan "$plan" '
        { id: $id, name: $name, version: $ver, plan: $plan,
          note: "unsupported", fetchedAt: 0, limits: [] }'
}

agents='[]'
add() {
    local one="$1"
    [ -n "$one" ] || return 0
    agents="$(printf '%s' "$agents" | jq -c --argjson one "$one" '. + [$one]')"
}

add "$(claude_json || true)"
add "$(other_agent codex        "Codex CLI"     "$(codex_plan)" || true)"
add "$(other_agent antigravity  "Antigravity"   || true)"
add "$(other_agent gemini       "Gemini CLI"    || true)"
add "$(other_agent opencode     "OpenCode"      || true)"
add "$(other_agent cursor-agent "Cursor Agent"  || true)"
add "$(other_agent windsurf     "Windsurf"      || true)"
add "$(other_agent copilot      "GitHub Copilot" || true)"
add "$(other_agent amp          "Amp"           || true)"
add "$(other_agent aider        "Aider"         || true)"
add "$(other_agent goose        "Goose"         || true)"
add "$(other_agent crush        "Crush"         || true)"
add "$(other_agent droid        "Droid"         || true)"
add "$(other_agent openhands    "OpenHands"     || true)"
add "$(other_agent qwen         "Qwen Code"     || true)"

printf '%s' "$agents" | jq -c --argjson now "$(date +%s%3N)" '{ now: $now, agents: . }'
