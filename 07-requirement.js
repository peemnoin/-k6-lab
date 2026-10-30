import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = 'https://quickpizza.grafana.com';
const PARAMS = {
  headers: {
    'Content-Type': 'application/json',
    Authorization: 'token abcdef0123456789',
  },
};
// Requirement: 3 concurrent users for 30 s, p(95) < 1 s, p(99) < 1.5 s,
// fewer than 1% failed requests. Override P95 / P99 with -e to make it fail.
const P95 = __ENV.P95 || 1000;
const P99 = __ENV.P99 || 1500;

export const options = {
  vus: 3,
  duration: '30s',
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)'],
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: [`p(95)<${P95}`, `p(99)<${P99}`],
  },
};

export default function () {
  const body = JSON.stringify({ mustBeVegetarian: true });
  const res = http.post(`${BASE_URL}/api/pizza`, body, PARAMS);
  check(res, {
    'status is 200': (r) => r.status === 200,
    'pizza has a name': (r) => r.json('pizza.name') !== undefined,
  });
  sleep(1);
}
