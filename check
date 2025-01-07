#!/bin/sh

shfmt -f "$@" | while IFS= read -r sh; do
  printf "'./%s'\n" "$sh"
  shfmt -w -d -p -i 2 -ci -sr "$sh"
  shellcheck "$sh"
done

exit 0
