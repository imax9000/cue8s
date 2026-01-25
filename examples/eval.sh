#!/bin/sh

package_name="$(grep --max-count=1 --no-filename '^package' $1/*.cue | awk '{print $2}' | sort -u)"

if [ x"${package_name}" = x ]; then
  echo "Unable to figure out package name" >&2
  exit 1
fi

if [ "$(echo "${package_name}" | wc -l)" -gt 1 ]; then
  filtered="$(echo "${package_name}" | grep -v -E '^(.*export|kube)$')"
  if [ "$(echo "${filtered}" | wc -l)" -eq 1 ]; then
    package_name="${filtered}"
  else
    echo "Multiple packages found: $(echo "${package_name}" | tr '\n' ' ')" >&2
    exit 1
  fi
fi

module_name="$(cue export --out=text -e module ./cue.mod/module.cue)"

cat <<-EOF | cue export --out=text -
package export

import (
  pkg "${module_name}/$1:${package_name}"
)

// {pkg.#export, #entries: [pkg]}.yamlStream can trigger stack overflows,
// but the intermediate step with _tmp somehow avoids it.
// (Might be fixed in CUE v0.16, see https://github.com/cue-lang/cue/issues/4228)
_tmp: {pkg.#export, #entries: [pkg]}
_tmp.yamlStream
EOF
