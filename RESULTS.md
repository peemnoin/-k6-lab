# K6 Lab Results

**Course:** ITCS386 – Software Verification and Validation  
**Test target:** https://quickpizza.grafana.com  
**Tool:** Grafana k6  
**Evidence:** Results collected from tests executed against QuickPizza; A2–A5 have HTML dashboard reports under `reports/`.

> **Completion status:** All Part A tests (A1–A5) and all Part 0 prescribed steps have been executed. The stricter Step 0.7 threshold failed as intended, and the corrected Step 0.8 script passed all checks. Only the original, uncorrected Step 0.8 failure percentages are not yet measured.

## Part 0: K6 Basics

### Step 0.1 – First test

- Command: `k6 run 01-first-test.js`
- `http_req_duration`: **256.91 ms** (avg = min = med = max = p(95), because there was one request)
- HTTP requests / iterations: **1 / 1**
- Checks: **100% (1/1)**
- HTTP request failure rate: **0.00%**
- Result: **PASS**

### Step 0.2 – More users for longer

- Command: `k6 run --vus 5 --duration 20s 01-first-test.js`
- Virtual users: **5**
- Duration: **20 seconds** (configured)
- Total requests: **80**
- Request rate: **3.867772 req/s** (approximately **3.87 req/s**)
- `http_req_duration` p(95): **257.66 ms**
- Checks: **100% (80/80)**
- HTTP request failure rate: **0.00%**

The request rate remained below 5 requests per second because each virtual user sends a request and then executes `sleep(1)`. The average HTTP duration was 255.71 ms, so an iteration takes roughly 1.26 seconds plus any additional overhead. Thus five virtual users generate fewer than five requests per second. This is an effect of simulated user think time rather than evidence of a server bottleneck.

### Step 0.3 – Fixed iterations

- Command: `k6 run --vus 5 --iterations 20 01-first-test.js`
- Completed iterations: **20/20**
- HTTP requests: **20**
- Checks: **100% (20/20)**
- `http_req_duration` p(95): **256.61 ms**
- Result: **PASS**

Unlike a fixed-duration test, an iteration-limited test ends when the specified amount of work is finished.

### Step 0.4 – Pizza API

- Command: `k6 run 04-pizza-api.js`
- HTTP requests: **1**
- Checks: **100% (3/3)**
- `http_req_duration`: **370.28 ms**
- Result: **PASS**. Status was 200, the pizza had a name, and all returned ingredients passed the vegetarian check.

### Step 0.5 – No-token request

- Command: `k6 run 05-no-token.js`
- Checks: **100% (1/1)** — the check expecting HTTP 401 passed
- HTTP request failure rate: **0.00%** because the script marks 401 as an expected status
- Result: **PASS**

### Step 0.6 – Thresholds

**Normal run** (`k6 run 06-thresholds.js`):

- Threshold `http_req_duration p(95) < 1500 ms`: **PASS**, measured **371.16 ms**
- Threshold `http_req_failed < 1%`: **PASS**, measured **0.00%**
- Threshold `checks > 99%`: **PASS**, measured **100.00%**
- Exit code: **0**

**Stricter run** (`k6 run -e P95=300 06-thresholds.js`):

- Threshold `http_req_duration p(95) < 300 ms`: **FAIL**, measured **367.16 ms**
- Threshold `http_req_failed < 1%`: **PASS**, measured **0.00%**
- Threshold `checks > 99%`: **PASS**, measured **100.00%**
- Exit code: **99**

This demonstrates that a check can pass while a performance threshold fails the overall test. Here, the stricter latency requirement caused exit code 99.

### Step 0.7 – From a requirement to thresholds

Requirement: with **3 virtual users for 30 seconds**, **p(95) < 1000 ms**, **p(99) < 1500 ms**, and an **HTTP request failure rate < 1%**.

**Original run** (`k6 run 07-requirement.js`):

- `http_req_duration p(95) < 1000 ms`: **PASS**, measured **360.53 ms**
- `http_req_duration p(99) < 1500 ms`: **PASS**, measured **371.80 ms**
- `http_req_failed < 1%`: **PASS**, measured **0.00%**
- Checks: **100.00%**
- Exit code: **0**

**Changed requirement, intentionally failing run** (`k6 run -e P95=100 07-requirement.js`):

- New p(95) threshold: **p(95) < 100 ms**
- Measured p(95): **360.69 ms — FAIL**
- p(99) threshold: **p(99) < 1500 ms — PASS**, measured **368.00 ms**
- HTTP failure-rate threshold: **< 1% — PASS**, measured **0.00%**
- Checks: **100% (138/138)**
- HTTP requests: **69**
- Exit code: **99**, as expected for a crossed threshold

The strict run intentionally failed because **360.69 ms > 100 ms**, even though all functional checks and the other performance thresholds passed.

### Step 0.8 – Bug hunt

The original request excluded `pepperoni` and `knife` in lowercase, whereas the catalog lists `Pepperoni` and `Knife`. Since exclusion matching is case-sensitive, the corrected request uses:

```javascript
excludedIngredients: ['Pepperoni'],
excludedTools: ['Knife'],
```

The corrected script was run using `k6 run --vus 5 --duration 20s 08-bug-hunt.js`:

- Virtual users: **5**; configured duration: **20 seconds**
- Completed iterations / HTTP requests: **75 / 75**
- Checks passed: **225/225 (100.00%)**
- Checks failed: **0/225 (0.00%)**
- Each check (`status is 200`, `no pepperoni`, `no knife needed`): **PASS**
- HTTP request failure rate: **0.00% (0/75)**
- `http_req_duration` p(95): **369.60 ms**

**Conclusion:** The corrected exclusions were validated across 75 responses, and every check passed. The response is randomized, so a single request might not expose the original mistake; repeated requests make incorrect recommendations more likely to be detected.

**Unmeasured baseline:** The original lowercase version was not run in the supplied logs, so its `no pepperoni` and `no knife needed` failure percentages are **not available**. Those numbers are not inferred from the successful corrected test.

## Part A: Load-testing results

| Step | Test type | Users (max VUs) | Req/s | p(95) | Max | Failed | Checks |
|:--|:--|--:|--:|--:|--:|--:|--:|
| A1 | Smoke | 1 | 0.54 | 328.68 ms | 347.03 ms | 0.0% | 100.0% |
| A2 | Average load | 3 | 1.31 | 358 ms | 459 ms | 0.0% | 100.0% |
| A3 | Stress | 5 | 2.11 | 353 ms | 385 ms | 0.0% | 100.0% |
| A4 | Spike | 5 | 1.07 | 360 ms | 370 ms | 0.0% | 100.0% |
| A5 | Soak | 2 | 0.99 | 357 ms | 376 ms | 0.0% | 100.0% |

*Req/s is the run-wide request rate. The p(95) and maximum values are for `http_req_duration` across the complete run, not for individual request groups.*

### Observations

**A1 – Smoke.** The 1-VU test executed **18 HTTP requests** and **6 complete iterations**. All **24/24 checks** passed, no requests failed, and the configured check and error-rate thresholds passed.

**A2 – Average load.** The test generated **243 requests** at **1.31 req/s** with **p(95) = 358 ms**, **0% failures**, and **100% checks passed**.

**A3 – Stress.** At up to **5 VUs**, the test generated **387 requests** at **2.11 req/s**. Its **p(95) = 353 ms**, slightly below A2's 358 ms. There were **0% failures** and **100% checks passed**.

**A4 – Spike.** The test generated **153 requests** at an overall rate of **1.07 req/s**, with **p(95) = 360 ms**, **0% failures**, and **100% checks passed**. The overall rate includes low-load phases and must not be mistaken for the peak rate during the spike.

**A5 – Soak.** The test generated **651 requests** at **0.99 req/s**, with **p(95) = 357 ms**, **0% failures**, and **100% checks passed**. These aggregate results are stable compared with the other tests; time-series inspection is needed to assess trends during the run.

## Part B: Reflection

### 1. Fill in the results table for Steps A1 to A5.

The Part A table contains measured results for all five tests against QuickPizza. Every test recorded **100% successful checks** and **0% failed HTTP requests**. A1 also passed its two configured thresholds.

### 2. In Step 0.2, why was the request rate below 5 requests per second with 5 virtual users?

Each VU makes one HTTP request and then sleeps for one second. Step 0.2 measured an average HTTP request duration of **255.71 ms**, so even without extra overhead one iteration takes around **1.26 seconds**. The observed request rate was **3.87 req/s**, not 5 req/s. The sleep simulates user think time and limits throughput.

### 3. Did the response time grow from the average-load test to the stress test? Explain using the operational envelope.

No. The overall p(95) was **358 ms** in A2 (up to **3 VUs**, **1.31 req/s**) and **353 ms** in A3 (up to **5 VUs**, **2.11 req/s**). This 5 ms difference, approximately **1.4%**, is small; it is not proof that a heavier load makes the service faster. Both tests had **0% HTTP failures** and **100% successful checks**. The observations are consistent with the tested loads being inside QuickPizza's operational envelope, where more load does not produce noticeable degradation. Since the lab permits only five VUs, these tests cannot locate the actual capacity limit.

### 4. In the spike test, how long did the response time take to return to normal after the spike?

The A4 test raised load quickly from **1 to 5 VUs** and then brought it back to **1 VU**. Its whole-run p(95) was **360 ms**, with **0% HTTP failures**. In the dashboard's time-series comparison, response time stayed close to its pre-spike level, so no distinct slowdown or recovery period was observed. Consequently, there is **no defensible nonzero recovery time to report**; the aggregate p(95) does not by itself quantify recovery time. Any finer recovery estimate would require more detailed time-series measurement.

### 5. In the soak test, did response time or error rate worsen over time? Name one defect a longer soak test could reveal.

A5 completed **651 HTTP requests** with **0% HTTP failures** and an overall **p(95) of 357 ms**. The time-series inspection did not show a clear, sustained increase in response time from the beginning to the end, and the error rate did not rise. A soak test lasting several hours might uncover a **memory leak**: unreleased allocations can accumulate until the application slows down or crashes. The short lab run cannot rule out defects that require a longer time to develop.

### 6. Why use p(95) rather than the average?

An average can conceal a slow tail: a minority of very slow responses may have little effect on the mean. The p(95) is the value at or below which approximately **95% of requests** finish. It therefore represents performance experienced by most requests while exposing slow-tail behavior that an average alone could obscure.

### 7. Give two reasons the same tests could produce different numbers in a laboratory environment.

First, **network conditions** differ: internet routing, latency and connection quality affect requests to a public website, while a local lab may have shorter and more stable network paths. Second, **shared load and infrastructure** differ: other users can access QuickPizza simultaneously, whereas a dedicated lab can control background traffic and hardware capacity.

### 8. Why must you never run hundreds of users against a site you do not own?

Large unauthorized stress or breakpoint tests can overload a service, deny access to legitimate users, impose infrastructure costs, and breach policies or laws. Such testing requires explicit permission and a controlled test environment. QuickPizza's lab rule is **no more than 5 VUs**.

### 9. Rewrite a vague app performance requirement as a measurable one and show k6 thresholds.

**Vague requirement:** “The LINE messaging app should respond quickly when sending a message.”

**Testable hypothetical requirement:** “In an authorized test environment, with 50 concurrent users each sending one message every five seconds for ten minutes, the send-message API must complete at least 95% of requests in under 500 ms, 99% in under 1000 ms, and have fewer than 0.1% failed requests.”

```javascript
export const options = {
  stages: [
    { duration: '1m', target: 50 },
    { duration: '10m', target: 50 },
    { duration: '1m', target: 0 },
  ],
  thresholds: {
    'http_req_duration{name:send-message}': ['p(95)<500', 'p(99)<1000'],
    'http_req_failed{name:send-message}': ['rate<0.001'],
  },
};
```

The scenario and metric tags are hypothetical; the test would require an implemented, permitted endpoint and suitable request tags. It is **not** authorization to run a 50-VU test against QuickPizza or LINE's production services.

## Conclusion

All five Part A workload tests (A1–A5) were executed against QuickPizza. They recorded **100% successful checks** and **0% failed HTTP requests**. The whole-run p(95) response times ranged from **328.68 ms to 360 ms**. In the observed tests, moving from three to five VUs did not cause a noticeable increase in response time, while the spike and soak tests showed no clear degradation at the tested small loads. These findings cannot establish the service's maximum operational capacity.

In Part 0, the basic, API, security-response, and threshold runs were executed. Step 0.7 passed its original thresholds and correctly returned **exit code 99** when the p(95) limit was tightened to 100 ms. The fixed Step 0.8 bug-hunt script passed **225/225 checks** over **75 requests**. The only missing optional comparison measurement is the original uncorrected Step 0.8 check-failure percentage; it is not claimed as a measured result.
