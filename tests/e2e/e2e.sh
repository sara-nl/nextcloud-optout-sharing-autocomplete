#!/usr/bin/env bash
# End-to-end test against a running Nextcloud with this app enabled.
#
# usage: tests/e2e/e2e.sh <base_url> docker <container>
#        tests/e2e/e2e.sh <base_url> ssh <user@host> <nextcloud_path>
#
# Creates the users acstestalice, acstesthenk and acstestpiet in the group acstest
# and checks the share dialog search, @mention autocomplete and the settings page.
# Set E2E_PW to choose their password and E2E_CLEANUP=1 to delete them afterwards.
# Needs curl and python3.
set -uo pipefail
BASE=$1; MODE=$2; shift 2
if [ "$MODE" = docker ]; then CONTAINER=$1; else HOST=$1; NCPATH=$2; fi

PW=${E2E_PW:-'Acs-e2e-Pw-2026-Zq8!'}
A=acstestalice; B=acstesthenk; C=acstestpiet; G=acstest
pass=0; fail=0

occ() {
	if [ "$MODE" = docker ]; then
		docker exec -e OC_PASS="$PW" -u www-data "$CONTAINER" php occ "$@"
	else
		ssh -o BatchMode=yes "$HOST" "sudo -n -u www-data env OC_PASS=$(printf '%q' "$PW") php $NCPATH/occ $(printf '%q ' "$@")"
	fi
}
check() { if [ "$2" = "$3" ]; then echo "PASS  $1"; pass=$((pass+1)); else echo "FAIL  $1 (expected '$3', got '$2')"; fail=$((fail+1)); fi; }
has() { [[ ",$1," == *",$2,"* ]] && echo yes || echo no; }

# Share dialog search as alice, prints "<partial user matches>|<exact user matches>|<groups>"
sharees() {
	curl -s -u "$A:$PW" -H 'OCS-APIRequest: true' \
		"$BASE/ocs/v2.php/apps/files_sharing/api/v1/sharees?search=$1&itemType=file&perPage=50&format=json" |
		python3 -c 'import json,sys
d = json.load(sys.stdin)["ocs"]["data"]
ids = lambda matches: ",".join(sorted(str(m["value"]["shareWith"]) for m in matches))
print(ids(d.get("users", [])) + "|" + ids(d.get("exact", {}).get("users", [])) + "|" + ids(d.get("groups", []) + d.get("exact", {}).get("groups", [])))'
}
partial() { sharees "$1" | cut -d'|' -f1; }
exact() { sharees "$1" | cut -d'|' -f2; }
groups() { sharees "$1" | cut -d'|' -f3; }

# Core autocomplete as alice, used for @mentions in comments
mentions() {
	curl -s -u "$A:$PW" -H 'OCS-APIRequest: true' \
		"$BASE/ocs/v2.php/core/autocomplete/get?search=$1&itemType=files&itemId=1&shareTypes%5B%5D=0&limit=20&format=json" |
		python3 -c 'import json,sys; print(",".join(sorted(m["id"] for m in json.load(sys.stdin)["ocs"]["data"])))'
}

# Requests to the settings controller and page are done as $ME
as_user() { ME=$1; }
set_pref() {
	curl -s -u "$ME:$PW" -H 'OCS-APIRequest: true' -X POST -H 'Content-Type: application/json' \
		-d "{\"value\": $1}" -w ' %{http_code}' "$BASE/index.php/apps/autocomplete_settings/settings/preference"
}
get_pref() { curl -s -u "$ME:$PW" -H 'OCS-APIRequest: true' "$BASE/index.php/apps/autocomplete_settings/settings/preference"; }
settings_page() { curl -s -u "$ME:$PW" "$BASE/index.php/settings/user/sharing"; }
initial_state() {
	settings_page | grep -o 'id="initial-state-autocomplete_settings-exclude_user_from_autocomplete" value="[^"]*"' |
		cut -d'"' -f4 | base64 -d 2>/dev/null
}
script_status() {
	local src
	src=$(settings_page | grep -o 'src="[^"]*autocomplete_settings-main\.mjs[^"]*"' | head -1 | cut -d'"' -f2 | sed 's/&amp;/\&/g')
	[ -n "$src" ] && curl -s -o /dev/null -w '%{http_code}' -u "$ME:$PW" "$BASE$src" || echo "no script tag"
}

# --- setup ---------------------------------------------------------------
occ group:add $G >/dev/null 2>&1
for u in $A $B $C; do
	occ user:add --password-from-env --display-name="$u" --group=$G $u >/dev/null 2>&1 || occ user:resetpassword --password-from-env $u >/dev/null
	occ user:setting $u files_sharing exclude_user_from_autocomplete --delete >/dev/null 2>&1
done

echo "== $(occ status --output=json | python3 -c 'import json,sys; print("Nextcloud", json.load(sys.stdin)["versionstring"])')"

# --- baseline ------------------------------------------------------------
check "baseline: henk in share suggestions"                  "$(has "$(partial acstesth)" $B)" yes
check "baseline: henk in @mention suggestions"               "$(has "$(mentions acstesth)" $B)" yes

# --- henk opts out through the settings page --------------------------------
as_user $B
check "settings page loads the app script"                   "$(script_status)" 200
check "settings page shows the switch off"                   "$(initial_state)" false
check "henk switches on"                                     "$(set_pref true)" '{"success":true,"value":true} 200'
check "henk reads the preference back"                       "$(get_pref)" '{"value":true}'
check "settings page shows the switch on"                    "$(initial_state)" true

check "henk hidden from share suggestions"                   "$(has "$(partial acstesth)" $B)" no
check "henk not an exact match for a partial search"         "$(has "$(exact acstesth)" $B)" no
check "piet still in share suggestions"                      "$(has "$(partial acstest)" $C)" yes
check "groups are not filtered"                              "$(has "$(groups acstest)" $G)" yes
check "henk found by their exact username"                   "$(has "$(exact $B)" $B)" yes
check "henk hidden from @mention suggestions"                "$(has "$(mentions acstesth)" $B)" no
check "henk in @mentions by their exact username"            "$(has "$(mentions $B)" $B)" yes

# --- value written by version 1.0.x or by hand as the string 'true' ---------
occ user:setting $C files_sharing exclude_user_from_autocomplete true >/dev/null
as_user $C
check "legacy 'true': piet hidden"                           "$(has "$(partial acstestp)" $C)" no
check "legacy 'true': settings page shows the switch on"     "$(initial_state)" true
check "legacy 'true': piet switches off"                     "$(set_pref false)" '{"success":true,"value":false} 200'
check "piet back in share suggestions"                       "$(has "$(partial acstestp)" $C)" yes

# --- henk opts back in ----------------------------------------------------
as_user $B
check "henk switches off"                                    "$(set_pref false)" '{"success":true,"value":false} 200'
check "henk back in share suggestions"                       "$(has "$(partial acstesth)" $B)" yes
check "henk back in @mention suggestions"                    "$(has "$(mentions acstesth)" $B)" yes

# --- not logged in -------------------------------------------------------
check "anonymous requests are rejected" \
	"$(curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/json' -d '{"value":true}' "$BASE/index.php/apps/autocomplete_settings/settings/preference")" 401

if [ "${E2E_CLEANUP:-0}" = 1 ]; then
	for u in $A $B $C; do occ user:delete $u >/dev/null; done
	occ group:delete $G >/dev/null
fi

echo "== $pass passed, $fail failed"
[ "$fail" = 0 ]
