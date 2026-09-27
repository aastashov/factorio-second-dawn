#!/usr/bin/env bash
# Publishes the built zip to mods.factorio.com through the mod portal API.
#
#   tools/publish.sh             # first time: creates the mod page; later: a new release
#   tools/publish.sh --page       # update description and summary only; does not build or release a mod
#   tools/publish.sh --gallery thumbnail.png docs/img/a.png ...   # replace the gallery with these pictures
#   tools/publish.sh --details                                    # category of the mod page
# Tags can't be set through the API (it answers success and ignores them): tick them on the mod page.
#
# The key comes from the environment or from .env in the repository root (FACTORIO_API_KEY=...; see
# .env.example). .env is in .gitignore and is never packed into the mod.
#
# The key is made at https://factorio.com/create-api-key with the permissions
# "ModPortal: Publish Mods", "ModPortal: Upload Mods" and "ModPortal: Edit Mods". The script only reads it.
#
# First publication also sets: the long description (the markdown block of docs/PORTAL.md), the category,
# the license (MOD_LICENSE, default "default_mit"; see the portal for other identifiers) and the gallery
# pictures listed below. Later runs upload only the new release.
set -euo pipefail
cd "$(dirname "$0")/.."
if [ -f .env ]; then set -a; . ./.env; set +a; fi

: "${FACTORIO_API_KEY:?put FACTORIO_API_KEY into .env (see .env.example) or the environment}"
API=https://mods.factorio.com/api/v2
AUTH=(-H "Authorization: Bearer $FACTORIO_API_KEY")
name=$(python3 -c "import json; print(json.load(open('info.json'))['name'])")
version=$(python3 -c "import json; print(json.load(open('info.json'))['version'])")
zip="dist/2.0/${name}_${version}.zip"

json() { python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('$1') or ''); sys.exit(0 if d.get('$1') else 1)"; }

# The initial publication includes the long description, but later releases must update it explicitly.
# Keep the portal page in sync with the bilingual Markdown in docs/PORTAL.md.
description=$(python3 - <<'EOF'
import re
s = open("docs/PORTAL.md", encoding="utf-8").read()
print(re.search(r"```markdown\n(.*?)\n```", s, re.S).group(1))
EOF
)
summary=$(python3 -c "import json; print(json.load(open('info.json'))['description'])")
update_details() {
  local answer
  answer=$(curl -s "${AUTH[@]}" -F "mod=$name" -F "summary=$summary" -F "description=$description" \
    -F "category=overhaul" "$API/mods/edit_details")
  case "$answer" in *'"success":true'*|*'"success": true'*) echo "portal description updated";;
    *) echo "portal details update failed: $answer"; exit 1;; esac
}

# Uploads the pictures and makes them the gallery, in this order (pictures not listed leave the gallery).
# Every step prints the portal's answer when it isn't what was expected.
gallery() {
  local ids=() img resp up id
  for img in "$@"; do
    resp=$(curl -s "${AUTH[@]}" -F "mod=$name" "$API/mods/images/add")
    if ! up=$(echo "$resp" | json upload_url); then echo "images/add for $img: $resp"; continue; fi
    resp=$(curl -s -F "image=@$img" "$up")
    if id=$(echo "$resp" | json id); then ids+=("$id"); echo "image $img: $id"
    elif echo "$resp" | grep -q "already exists"; then
      # the portal's image id is the file's SHA-1: an image uploaded before is reused as it is
      id=$(shasum -a 1 "$img" | awk '{print $1}'); ids+=("$id"); echo "image $img: $id (already there)"
    else echo "upload of $img: $resp"; fi
  done
  if [ ${#ids[@]} -gt 0 ]; then
    echo "images/edit: $(curl -s "${AUTH[@]}" -F "mod=$name" -F "images=$(IFS=,; echo "${ids[*]}")" "$API/mods/images/edit")"
  else
    echo "no picture uploaded, the gallery is unchanged"
  fi
}

if [ "${1:-}" = "--details" ]; then
  echo "edit_details: $(curl -s "${AUTH[@]}" -F "mod=$name" -F "category=overhaul" "$API/mods/edit_details")"
  exit 0
fi

if [ "${1:-}" = "--page" ]; then
  update_details
  echo "page: https://mods.factorio.com/mod/$name"
  exit 0
fi

if [ "${1:-}" = "--gallery" ]; then
  shift
  gallery "$@"
  echo "gallery: https://mods.factorio.com/mod/$name"
  exit 0
fi

[ -f "$zip" ] || bash build.sh
echo "mod $name $version: $zip"
exists=$(curl -s -o /dev/null -w "%{http_code}" "https://mods.factorio.com/api/mods/$name")
if [ "$exists" = "200" ]; then
  update_details
  url=$(curl -s "${AUTH[@]}" -F "mod=$name" "$API/mods/releases/init_upload" | json upload_url)
  answer=$(curl -s -F "file=@$zip" "$url"); echo "$answer"
  case "$answer" in *'"error"'*) echo "not released: the portal refused $version"; exit 1;; esac
  echo "released $version"
  exit 0
fi

# First publication: the page with its description, category and license.
url=$(curl -s "${AUTH[@]}" -F "mod=$name" "$API/mods/init_publish" | json upload_url)
curl -s -F "file=@$zip" -F "description=$description" -F "category=overhaul" \
  -F "license=${MOD_LICENSE:-default_mit}" "$url"; echo
echo "published $name $version"

# Gallery.
gallery thumbnail.png docs/img/campfire.png docs/img/map-777.png
echo "done: https://mods.factorio.com/mod/$name"
