from flask import Flask
import logging
import time
from elasticsearch import Elasticsearch

app = Flask(__name__)

# Configure Elasticsearch (will run inside Kubernetes)
es = Elasticsearch(["http://elasticsearch:9200"])

# Log generator
@app.route('/log')
def generate_log():
    log_message = f"User accessed the system at {time.ctime()}"
    app.logger.warning(log_message)  # Log to console
    
    # Send log to Elasticsearch
    es.index(index="app-logs", body={"message": log_message, "level": "INFO"})
    return "Log generated!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)