#!/usr/bin/env bash
set -euo pipefail

THRESHOLD=${1:-90}

if [ ! -f coverage/lcov.info ]; then
  echo "coverage/lcov.info not found. Run 'flutter test --coverage' first."
  exit 1
fi

# Filter to lib/ only to avoid counting tests/example
TMP=$(mktemp)
awk '
  /^SF:/ {print $0; inlib = index($0, "/lib/") > 0}
  /^DA:/ && inlib {print $0}
  /^end_of_record/ && inlib {print $0}
' coverage/lcov.info > "$TMP"

TOTAL=$(grep -h "^DA:" "$TMP" | wc -l | xargs)
HIT=$(grep -h "^DA:" "$TMP" | awk -F, '''{if ($2>0) c++} END{print c+0}''')

if [ "$TOTAL" -eq 0 ]; then
  PCT=0
else
  PCT=$(awk -v h="$HIT" -v t="$TOTAL" 'BEGIN{printf "%.2f", (h*100)/t}')
fi

echo "Coverage (lib/): $PCT% (hits=$HIT total=$TOTAL), threshold=${THRESHOLD}%"
awk -v p="$PCT" -v th="$THRESHOLD" 'BEGIN{ exit (p+0.0001 < th) ? 1 : 0 }' || {
  echo "Coverage below threshold."
  exit 1
}
