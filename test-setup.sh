#!/bin/bash

echo "=== Log Analytics Project Testing ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    if [ $2 -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1${NC}"
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Test Docker installation
echo "🔍 Testing Docker setup..."
docker --version > /dev/null 2>&1
print_status "Docker installed" $?

docker-compose --version > /dev/null 2>&1
print_status "Docker Compose installed" $?

# Test if Docker daemon is running
docker info > /dev/null 2>&1
print_status "Docker daemon running" $?

# Test Elasticsearch
echo ""
echo "🔍 Testing Elasticsearch..."
if curl -s http://localhost:9200 > /dev/null; then
    HEALTH=$(curl -s http://localhost:9200/_cluster/health | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    if [ "$HEALTH" = "green" ] || [ "$HEALTH" = "yellow" ]; then
        print_status "Elasticsearch is healthy ($HEALTH)" 0
    else
        print_status "Elasticsearch unhealthy ($HEALTH)" 1
    fi
else
    print_status "Elasticsearch not accessible" 1
fi

# Test Kibana
echo ""
echo "🔍 Testing Kibana..."
if curl -s http://localhost:5601/api/status > /dev/null; then
    STATUS=$(curl -s http://localhost:5601/api/status | grep -o '"overall":{"level":"[^"]*"' | cut -d'"' -f6)
    if [ "$STATUS" = "available" ]; then
        print_status "Kibana is available" 0
    else
        print_status "Kibana status: $STATUS" 1
    fi
else
    print_status "Kibana not accessible" 1
fi

# Test log generation
echo ""
echo "🔍 Testing log generation..."
if [ -d "./logs" ] && [ "$(ls -A ./logs 2>/dev/null)" ]; then
    LOG_COUNT=$(find ./logs -name "*.log" -type f | wc -l)
    print_status "Log files generated ($LOG_COUNT files)" 0
    
    # Check if logs contain data
    TOTAL_LINES=$(cat ./logs/*.log 2>/dev/null | wc -l)
    if [ $TOTAL_LINES -gt 0 ]; then
        print_status "Logs contain data ($TOTAL_LINES lines)" 0
    else
        print_status "Logs are empty" 1
    fi
else
    print_status "No log files found" 1
fi

# Test Elasticsearch indices
echo ""
echo "🔍 Testing Elasticsearch indices..."
if curl -s http://localhost:9200/_cat/indices > /dev/null; then
    INDICES=$(curl -s http://localhost:9200/_cat/indices | wc -l)
    if [ $INDICES -gt 0 ]; then
        print_status "Elasticsearch indices created ($INDICES indices)" 0
        echo "Indices:"
        curl -s http://localhost:9200/_cat/indices?v
    else
        print_status "No Elasticsearch indices found" 1
    fi
else
    print_status "Cannot access Elasticsearch indices" 1
fi

# Test data ingestion
echo ""
echo "🔍 Testing data ingestion..."
if curl -s http://localhost:9200/_cat/count/filebeat-* > /dev/null 2>&1; then
    FILEBEAT_COUNT=$(curl -s http://localhost:9200/_cat/count/filebeat-* | awk '{print $3}')
    print_status "Filebeat data ingested ($FILEBEAT_COUNT documents)" 0
else
    print_warning "Filebeat indices not found or empty"
fi

if curl -s http://localhost:9200/_cat/count/logstash-* > /dev/null 2>&1; then
    LOGSTASH_COUNT=$(curl -s http://localhost:9200/_cat/count/logstash-* | awk '{print $3}')
    print_status "Logstash data ingested ($LOGSTASH_COUNT documents)" 0
else
    print_warning "Logstash indices not found or empty"
fi

# Test sample queries
echo ""
echo "🔍 Testing sample queries..."

# Test basic search
SEARCH_RESULT=$(curl -s -X GET "localhost:9200/_search?size=1" -H 'Content-Type: application/json' -d'{"query":{"match_all":{}}}' | grep -o '"hits":{"total":{"value":[0-9]*' | cut -d':' -f4)

if [ ! -z "$SEARCH_RESULT" ] && [ $SEARCH_RESULT -gt 0 ]; then
    print_status "Basic search working ($SEARCH_RESULT total documents)" 0
else
    print_status "Basic search failed or no documents" 1
fi

# Performance check
echo ""
echo "🔍 Performance check..."
RESPONSE_TIME=$(curl -o /dev/null -s -w '%{time_total}' http://localhost:9200)
if (( $(echo "$RESPONSE_TIME < 1.0" | bc -l) )); then
    print_status "Elasticsearch response time good (${RESPONSE_TIME}s)" 0
else
    print_warning "Elasticsearch response time slow (${RESPONSE_TIME}s)"
fi

# Container health check
echo ""
echo "🔍 Container health check..."
if command -v docker-compose &> /dev/null; then
    RUNNING_CONTAINERS=$(docker-compose ps | grep "Up" | wc -l)
    TOTAL_CONTAINERS=$(docker-compose ps | tail -n +3 | wc -l)
    
    if [ $RUNNING_CONTAINERS -eq $TOTAL_CONTAINERS ] && [ $TOTAL_CONTAINERS -gt 0 ]; then
        print_status "All containers running ($RUNNING_CONTAINERS/$TOTAL_CONTAINERS)" 0
    else
        print_status "Some containers not running ($RUNNING_CONTAINERS/$TOTAL_CONTAINERS)" 1
        echo "Container status:"
        docker-compose ps
    fi
fi

# Resource usage check
echo ""
echo "🔍 Resource usage check..."
if command -v docker &> /dev/null; then
    echo "Docker resource usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
fi

# Final recommendations
echo ""
echo "📋 Recommendations:"

if [ ! -f "./logs/app.log" ]; then
    print_warning "Create sample log files for testing"
fi

if ! curl -s http://localhost:9200 > /dev/null; then
    echo "   - Start Elasticsearch: docker-compose up elasticsearch -d"
fi

if ! curl -s http://localhost:5601 > /dev/null; then
    echo "   - Start Kibana: docker-compose up kibana -d"
fi

echo ""
echo "📊 Quick access URLs:"
echo "   - Elasticsearch: http://localhost:9200"
echo "   - Kibana: http://localhost:5601"
echo "   - Elasticsearch Health: http://localhost:9200/_cluster/health"
echo "   - Kibana Status: http://localhost:5601/api/status"

echo ""
echo "🔧 Useful debugging commands:"
echo "   docker-compose logs elasticsearch"
echo "   docker-compose logs kibana"
echo "   docker-compose logs filebeat"
echo "   curl -X GET 'localhost:9200/_cat/indices?v'"
echo "   curl -X GET 'localhost:9200/_cluster/health?pretty'"

echo ""
echo "=== Testing Complete ==="