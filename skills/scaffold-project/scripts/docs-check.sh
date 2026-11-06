#!/usr/bin/env bash
# Check doc comments with the Doxyfile in the current directory.
# Usage: docs-check.sh [--report-only] [--require-file-doc <dir>...]
#   --report-only       print the problems but exit 0
#   --require-file-doc  also require a file-level doc under <dir>: an @file comment in C, C++
#                       and PHP files, and a module docstring in Python files
# Exits 1 if a function or type lacks docs, and 2 on bad usage.
# The scaffold-project skill copies this script into generated projects as scripts/docs-check.sh.
#
# Doxygen's WARN_AS_ERROR isn't used because it can't be limited by kind: it would also fail
# on every undocumented field and constant. It also never reports a missing file-level doc,
# even though it ignores undocumented global functions in a file without one.
set -uo pipefail

report_only=0
file_doc_dirs=()

missing_file_docs() { # missing_file_docs <dir...>: list source files with no file-level doc
  find "$@" -type f \
    \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp' -o -name '*.php' \) \
    -exec grep -LE '[@\\]file\b' {} + 2>/dev/null

  local file first_code

  while IFS= read -r file; do
    first_code=$(sed -n '/^[^#[:space:]]/{p;q}' "$file")

    # Files with no code, such as an empty __init__.py, need no docstring.
    if [[ -n "$first_code" ]] && ! grep -qE '^[rR]?"""' <<< "$first_code"; then
      printf '%s\n' "$file"
    fi
  done < <(find "$@" -type f -name '*.py' 2>/dev/null)
}

while (( $# )); do
  case "$1" in
    --report-only)
      report_only=1
      shift ;;
    --require-file-doc)
      shift

      while (( $# )) && [[ "$1" != --* ]]; do
        file_doc_dirs+=("$1")
        shift
      done ;;
    *)
      echo "docs-check: unknown argument '$1'" >&2
      exit 2 ;;
  esac
done

# Doxygen sends warnings to stderr, and reports only real failures through its exit status.
output=$(doxygen Doxyfile 2>&1 >/dev/null)
status=$?

if (( status != 0 )); then
  printf '%s\n' "$output" >&2
  exit "$status"
fi

problems=$(printf '%s\n' "$output" \
  | grep -vE ' Member .* \((variable|typedef|enumeration|enumvalue|friend|property|event|define|macro definition)\) of ' \
  | grep -v '^$')

if (( ${#file_doc_dirs[@]} )); then
  no_file_doc=$(missing_file_docs "${file_doc_dirs[@]}" | sed 's/$/: error: no file-level doc comment/')

  if [[ -n "$no_file_doc" ]]; then
    problems=$(printf '%s\n%s' "$no_file_doc" "$problems")
  fi
fi

if [[ -z "$problems" ]]; then
  echo "docs-check: ok"
  exit 0
fi

printf '%s\n' "$problems"

if (( report_only )); then
  echo "docs-check: report-only, not failing"
  exit 0
fi

exit 1
