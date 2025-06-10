from prometheus_flask_exporter import PrometheusMetrics
from prometheus_client import Counter

def init_prometheus_metrics(app):
    metrics = PrometheusMetrics(app)
    metrics.info('app_info', 'Application Info', version='1.0.0')

    # Create custom counters using prometheus_client directly
    metrics.public_requests = Counter(
        'public_requests',
        'Number of requests to the public endpoint',
        ['endpoint']
    )
    
    metrics.private_requests = Counter(
        'private_requests',
        'Number of requests to the private endpoint',
        ['endpoint']
    )

    return metrics