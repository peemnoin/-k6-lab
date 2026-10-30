#!/usr/bin/env bash
# Runs every step of the lab in order and saves each k6 summary to reports/.
# Usage: ./run-all.sh            (Part 0 + A1-A4, about 12 minutes)
#        ./run-all.sh --soak     (also runs A5, adds 11 minutes)
set -u
cd "$(dirname "$0")"
mkdir -p reports

run() { # name, k6 args...
  local name=$1; shift
  echo "=== $name: k6 run $*"
  k6 run "$@" 2>&1 | tee "reports/$name.txt"
  local code=${PIPESTATUS[0]}
  echo "exit code: $code" | tee -a "reports/$name.txt"
}

run 0.1-first-test        01-first-test.js
run 0.2-5vus-20s          --vus 5 --duration 20s 01-first-test.js
run 0.3-20-iterations     --vus 5 --iterations 20 01-first-test.js
run 0.4-pizza-api         04-pizza-api.js
run 0.5-no-token          05-no-token.js
run 0.6-thresholds        06-thresholds.js
run 0.6-thresholds-p95-300 -e P95=300 06-thresholds.js
run 0.7-requirement       07-requirement.js
run 0.7-requirement-fail  -e P95=100 07-requirement.js
run 0.8-explore           explore.js
run 0.8-bug-hunt          --vus 5 --duration 20s 08-bug-hunt.js
run A1-smoke              a1-smoke.js
run A2-average            --out web-dashboard=export=reports/a2-average.html a2-average.js
run A3-stress             --out web-dashboard=export=reports/a3-stress.html a3-stress.js
run A4-spike              --out web-dashboard=export=reports/a4-spike.html a4-spike.js
if [ "${1:-}" = "--soak" ]; then
  run A5-soak             --out web-dashboard=export=reports/a5-soak.html a5-soak.js
fi
