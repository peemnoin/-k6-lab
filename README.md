# k6-lab

ITCS386 Software Verification and Validation: Performance Testing with Grafana K6.

All tests target [QuickPizza](https://quickpizza.grafana.com), the public K6 demo site,
and follow its rules: at most 5 virtual users, at most 3 minutes per run (except the
2-user soak test).

| File | Step | What it does |
| --- | --- | --- |
| `01-first-test.js` | 0.1–0.3 | GET the home page and check status 200 |
| `04-pizza-api.js` | 0.4 | POST `/api/pizza` and check the answer is vegetarian |
| `05-no-token.js` | 0.5 | The same request without a token must get 401 |
| `06-thresholds.js` | 0.6 | Thresholds on failure rate, p(95) (`-e P95=...`) and checks |
| `07-requirement.js` | 0.7 | The product owner's requirement as thresholds |
| `08-bug-hunt.js` | 0.8 | No pepperoni, no knife (fixed) |
| `explore.js` | 0.8 | Prints QuickPizza's toppings and tools |
| `journey.js` | A | One visit: home, quotes, vegetarian pizza |
| `a1-smoke.js` … `a5-soak.js` | A1–A5 | Smoke, average-load, stress, spike and soak tests |
| `run-all.sh` | all | Runs every step and saves the summaries in `reports/` |

Results and answers are in [RESULTS.md](RESULTS.md); HTML reports are in `reports/`.
