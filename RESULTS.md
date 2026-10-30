# K6 lab results

> **Status:** the scripts are complete and validated with `k6 inspect` (k6 v2.2.0).
> The numbers marked **TODO** must come from your own runs against QuickPizza.
> Run `./run-all.sh` (or `./run-all.sh --soak`) and copy them from the summaries saved
> in `reports/*.txt`.

## Part 0
- Step 0.1, http_req_duration: **TODO** ms (one request, so avg = min = med = max = p(95)).
- Step 0.2, requests, rate and p(95), and why the rate stays below 5:
  **TODO** requests, **TODO** req/s, p(95) = **TODO** ms (the sheet's reference run: 78 requests,
  about 3.7 req/s, p(95) about 290 ms).
  One iteration is one request plus `sleep(1)`. If a request takes about 0.3 s, one
  iteration takes about 1.3 s, so one virtual user makes at most 1 / 1.3 ≈ 0.77 requests
  per second and 5 users make about 5 × 0.77 ≈ 3.8 req/s. The rate can reach 5 req/s only
  if the response time is zero. The iteration running when the 20 s end also stops early.
- Step 0.6, exit code of the normal run and of the run with P95=300:
  normal run **TODO** (expected 0, all thresholds pass); `-e P95=300` **TODO** (99 if the
  p(95) is above 300 ms, which crosses the threshold).
- Step 0.7, rules that passed, p(95), p(99), exit code after your change:
  `07-requirement.js` uses `vus: 3`, `duration: '30s'`,
  `http_req_duration: ['p(95)<1000', 'p(99)<1500']` and `http_req_failed: ['rate<0.01']`.
  Passed: **TODO**. Measured p(95) = **TODO** ms, p(99) = **TODO** ms.
  Change: the p(95) limit lowered from 1 s to 100 ms (`k6 run -e P95=100 07-requirement.js`).
  Exit code after the change: **TODO** (expected 99).
- Step 0.8, what was wrong, and how the checks showed it:
  The request asked for `excludedIngredients: ['pepperoni']` and `excludedTools: ['knife']`
  in lower case. QuickPizza compares names exactly and case-sensitively
  (`slices.Contains`), and `explore.js` shows that its catalogue spells them
  `Pepperoni` and `Knife`. So the restrictions matched nothing, and the API recommended
  pizzas with pepperoni or ones cut with a knife. The fix is
  `excludedIngredients: ['Pepperoni']` and `excludedTools: ['Knife']`. After that, every
  check passes (**TODO**: confirm 100% checks).
  Before the fix, failure rate: `no pepperoni` **TODO**%, `no knife needed` **TODO**%.
  The recommendation is random, so one manual request often gets a pizza that happens to
  have neither pepperoni nor a knife, and the bug stays hidden. Under load, with 5 users
  for 20 s, the request is repeated about 75 times. The checks run on every answer and
  report the fail rate, so the bug shows up as a fraction of failed checks.

## Part A results
| Step | Test type    | Users | Req/s | p(95) | Max  | Failed | Checks |
| ---- | ------------ | ----- | ----- | ----- | ---- | ------ | ------ |
| A1   | Smoke        | 1     | TODO  | TODO  | TODO | TODO   | TODO   |
| A2   | Average load | 3     | TODO  | TODO  | TODO | TODO   | TODO   |
| A3   | Stress       | 5     | TODO  | TODO  | TODO | TODO   | TODO   |
| A4   | Spike        | 5     | TODO  | TODO  | TODO | TODO   | TODO   |
| A5   | Soak         | 2     | TODO  | TODO  | TODO | TODO   | TODO   |

## Part B
1. See the table above.
2. Each virtual user runs one iteration at a time: one request, then `sleep(1)`. An
   iteration therefore lasts 1 s plus the response time (about 1.3 s), so each user sends
   fewer than 1 request per second, and 5 users send fewer than 5 (about 3.8 req/s).
   Think time, not the server, limits the rate.
3. **TODO** compare the p(95) of A2 and A3. With 3 to 5 users that wait 3 to 7 s between
   journeys, QuickPizza gets only about 1 to 2 requests per second. That is far inside
   the operational envelope of a service built for K6 practice by people all over the
   world, so the response time should stay about the same, with differences that come
   from the network and other users rather than from our load. Our 5 users are a tiny
   part of the total traffic, so this test cannot reach the edge of the envelope, where
   the response time would start to rise.
4. **TODO** read the spike (about 0:30 to 1:10) in `reports/a4-spike.html`. Write whether
   the p(95) rose, and how many seconds after the drop back to 1 user it returned to
   the level before the spike. At this small load, expect little or no rise and an
   almost immediate return.
5. **TODO** compare the first and last minutes of `reports/a5-soak.html`. A soak test of
   several hours could reveal a **memory leak**. Memory grows a little with each
   request until the process slows down from garbage collection or crashes. Other
   examples are connection pools or file handles that are never released, a database
   or log that grows until queries slow down or the disk fills, and caches without a
   size limit.
6. The average hides the slow tail. A few very slow requests barely move the average,
   and one very slow request can hide many slow ones among fast ones. p(95) says what
   95% of users actually get, and 1 request in 20 is slower. This is the experience a
   requirement should protect, and it is stable to set limits on.
7. (a) Network: our requests cross the internet to QuickPizza, so latency, routing,
   Wi-Fi and the home connection are added to every response time. In a lab, the
   generator sits next to the server. (b) Shared load: QuickPizza is used by K6
   learners everywhere at the same time, and it may run behind a CDN, autoscaling and
   rate limits, so the load and capacity change while we test. A lab system is isolated,
   with known and fixed hardware. Also, the load generator's own machine (CPU, other
   programs) differs between runs.
8. A test with hundreds of users against someone else's site is in effect a
   denial-of-service attack. It can slow down or crash a service other people depend
   on, it costs the owner money, and it can be illegal (unauthorised use of computer
   systems) and break the site's terms of use. Your IP may be blocked, and the results
   say nothing useful because you do not control or observe the system. Run such tests
   only on systems you own, or with written permission, ideally in a separate test
   environment.
9. Vague: "The LINE app should feel fast when I send a message."
   Testable: "With 50 concurrent users each sending one message every 5 s for 10
   minutes, the send-message API answers 95% of requests within 500 ms and 99% within
   1 s, and fewer than 0.1% of requests fail."
   ```js
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
