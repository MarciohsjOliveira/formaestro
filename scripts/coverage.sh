#!/usr/bin/env bash
set -euo pipefail

THRESHOLD=${1:-90}
LCOV=${2:-coverage/lcov.info}

if [[ ! -f "$LCOV" ]]; then
  echo "::error::LCOV file not found at $LCOV"
  echo "Run: flutter test --coverage"
  exit 1
fi

total=0
hit=0
inlib=0
path=""

# Conta só linhas DA: de arquivos dentro de lib/ (relativo ou absoluto)
while IFS= read -r line; do
  if [[ "$line" == SF:* ]]; then
    path="${line#SF:}"
    if [[ "$path" == lib/* || "$path" == */lib/* ]]; then
      inlib=1
    else
      inlib=0
    fi
  elif [[ $inlib -eq 1 && "$line" == DA:* ]]; then
    (( total++ ))
    rest="${line#DA:}"
    IFS=',' read -r _ count <<< "$rest"
    if (( count > 0 )); then (( hit++ )); fi
  fi
done < "$LCOV"

pct="0.00"
if (( total > 0 )); then
  pct=$(awk -v h="$hit" -v t="$total" 'BEGIN{printf "%.2f", (h*100)/t}')
fi

echo "Coverage (lib/): ${pct}% (hits=${hit} total=${total}) — threshold=${THRESHOLD}%"

# 5 piores arquivos (diagnóstico, sem duplicados)
awk '
  BEGIN{FS=":"}
  /^SF:/ {
    path=substr($0,4)
    islib = (index(path,"/lib/")>0 || substr(path,1,4)=="lib/")
    if (islib) { files[path,"t"]=0; files[path,"h"]=0 }
    next
  }
  /^DA:/ {
    if (path!="") {
      islib = (index(path,"/lib/")>0 || substr(path,1,4)=="lib/")
      if (islib) {
        files[path,"t"]++
        split($0,a,":"); split(a[2],b,","); if (b[2]+0>0) files[path,"h"]++
      }
    }
    next
  }
  END {
    for (k in files) {
      split(k, parts, SUBSEP); f = parts[1]
      t = files[f,"t"]; h = files[f,"h"]
      if (t>0) { pc = (h*100)/t; printf("%.2f%%\t%s\n", pc, f) }
    }
  }
' "$LCOV" | sort -n | awk '!seen[$0]++' | head -n 5 | sed 's/^/  - /'

# Enforce threshold
awk -v p="$pct" -v th="$THRESHOLD" 'BEGIN{ exit (p+0.0001 < th) ? 1 : 0 }' || {
  echo "::error::Coverage below threshold (${pct}% < ${THRESHOLD}%)"
  exit 1
}
