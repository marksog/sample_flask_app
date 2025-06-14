#!/bin/bash
set -e

# Install k6 if not present
if ! command -v k6 &> /dev/null; then
    sudo yum install -y https://dl.k6.io/rpm/repo.rpm
    sudo yum install -y k6
fi

# Get internal endpoint
INTERNAL_ENDPOINT=$(kubectl get svc internal-service -n dev -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Run test
k6 run - < <(cat <<'EOF'
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
    stages: [
        { duration: '30s', target: 20 },
        { duration: '1m', target: 50 },
        { duration: '30s', target: 0 },
    ],
    thresholds: {
        http_req_duration: ['p(95)<1000'],
    },
};

export default function () {
    // First authenticate (simplified for demo)
    const loginRes = http.post(`http://${__ENV.INTERNAL_ENDPOINT}/login`, {
        username: 'demo',
        password: 'password123',
    });
    
    if (loginRes.status === 200) {
        const internalRes = http.get(`http://${__ENV.INTERNAL_ENDPOINT}/internal`);
        check(internalRes, {
            'internal status 200': (r) => r.status === 200,
            'response contains internal content': (r) => r.body.includes('Internal Service'),
        });
    }
    sleep(1);
}
EOF
)