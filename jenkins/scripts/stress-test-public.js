import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
    stages: [
        { duration: '30s', target: 50 },  // Ramp up to 50 users
        { duration: '1m', target: 100 },  // Stay at 100 users
        { duration: '30s', target: 0 },   // Ramp down
    ],
    thresholds: {
        http_req_duration: ['p(95)<500'], // 95% of requests < 500ms
        http_req_failed: ['rate<0.01'],   // <1% errors
    },
};

export default function () {
    const res = http.get(`${__ENV.TARGET_URL}`);
    check(res, {
        'status was 200': (r) => r.status == 200,
        'response time < 500ms': (r) => r.timings.duration < 500,
    });
    sleep(1);
}