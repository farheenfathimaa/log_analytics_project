#!/bin/bash

echo "=== Log Analytics Project Setup ==="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p logs
mkdir -p logstash/config
mkdir -p logstash/pipeline
mkdir -p filebeat
mkdir -p k8s

# Set permissions for logs directory
chmod 777 logs

echo "🐳 Starting with Docker Compose..."

# Build and start services
docker-compose down -v 2>/dev/null
docker-compose up --build -d

echo "⏳ Waiting for services to start..."

# Wait for Elasticsearch
echo "Waiting for Elasticsearch..."
until curl -s http://localhost:9200/_cluster/health | grep -q '"status":"green\|yellow"'; do
    echo "Elasticsearch is starting..."
    sleep 10
done

echo "✅ Elasticsearch is ready!"

# Wait for Kibana
echo "Waiting for Kibana..."
until curl -s http://localhost:5601/api/status | grep -q '"status":"green"'; do
    echo "Kibana is starting..."
    sleep 10
done

echo "✅ Kibana is ready!"

echo "🎉 Services are running!"
echo ""
echo "📊 Access URLs:"
echo "   Elasticsearch: http://localhost:9200"
echo "   Kibana: http://localhost:5601"
echo ""
echo "📋 To check logs:"
echo "   docker-compose logs -f"
echo ""
echo "🛑 To stop:"
echo "   docker-compose down"
echo ""
echo "🔄 To restart:"
echo "   docker-compose restart"

# Optional: Setup Kibana index patterns
echo ""
echo "🔧 Setting up Kibana index patterns..."
sleep 30

# Create index patterns
curl -X POST "localhost:5601/api/saved_objects/index-pattern/filebeat-*" \
  -H "kbn-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "filebeat-*",
      "timeFieldName": "@timestamp"
    }
  }' 2>/dev/null

curl -X POST "localhost:5601/api/saved_objects/index-pattern/logstash-*" \
  -H "kbn-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "logstash-*",
      "timeFieldName": "@timestamp"
    }
  }' 2>/dev/null

echo "✅ Setup complete!"