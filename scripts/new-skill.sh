#!/usr/bin/env bash
# Create a new skill from the template: ./scripts/new-skill.sh <kebab-name>
set -euo pipefail

name="${1:-}"
root="$(cd "$(dirname "$0")/.." && pwd)"

if [[ ! "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "usage: $0 <kebab-case-name>" >&2
  exit 1
fi

dir="$root/skills/$name"
if [[ -e "$dir" ]]; then
  echo "error: $dir already exists" >&2
  exit 1
fi

mkdir -p "$dir"
sed "s/{{name}}/$name/g" "$root/templates/SKILL.template.md" > "$dir/SKILL.md"
echo "created skills/$name/SKILL.md"
