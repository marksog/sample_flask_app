import os
import socket
from flask import Flask, jsonify
from prometheus_monitory import init_prometheus_metrics

app = Flask(__name__)
metrics = init_prometheus_metrics(app)

@app.route('/')
def public_endpoint():
    """
    Public endpoint that returns a welcome message.
    """
    metrics.public_requests.labels(endpoint='/').inc()  # Increment the counter
    hostname = socket.gethostname()
    message = f"Public Service | Host: {hostname} | Serving external users"

    return jsonify(message=message), 200

@app.route('/internal')
def internal_endpoint():
    """
    Internal endpoint that returns a message for internal users.
    """
    metrics.private_requests.labels(endpoint='/internal').inc() # Increment the counter
    hostname = socket.gethostname()
    message = f"Internal Service | Host: {hostname} | Serving internal users"

    return jsonify(message=message), 200

@app.route('/health')
def health_check():
    """
    Health check endpoint to verify the service is running.
    """
    return jsonify(status='healthy'), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 5001)), debug=True)