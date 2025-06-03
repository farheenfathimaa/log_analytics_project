#!/bin/bash

echo "=== Kubernetes Setup for Log Analytics ==="

# Check if minikube is running
if ! minikube status | grep -q "Running"; then
    echo "🚀 Starting Minikube..."
    minikube start --memory=4096 --cpus=2
fi

# Enable required addons
echo "🔧 Enabling Minikube addons..."
minikube addons enable ingress

# Set docker environment
echo "🐳 Setting Docker environment..."
eval $(minikube docker-env)

# Build the application image
echo "🏗️  Building application image..."
docker build -t log-generator:latest .

# Apply Kubernetes manifests
echo "📦 Deploying to Kubernetes..."

# Create namespace
kubectl apply -f k8s/namespace.yaml

# Deploy Elasticsearch
kubectl apply -f k8s/elasticsearch.yaml

# Wait for Elasticsearch
echo "⏳ Waiting for Elasticsearch..."
kubectl wait --for=condition=available --timeout=300s deployment/elasticsearch -n log-analytics

# Deploy Kibana
kubectl apply -f k8s/kibana.yaml

# Wait for Kibana
echo "⏳ Waiting for Kibana..."
kubectl wait --for=condition=available --timeout=300s deployment/kibana -n log-analytics

# Deploy Application
kubectl apply -f k8s/app.yaml

echo "✅ Deployment complete!"

# Get service URLs
KIBANA_URL=$(minikube service kibana-service -n log-analytics --url)
ELASTICSEARCH_URL="http://$(minikube ip):$(kubectl get svc elasticsearch-service -n log-analytics -o jsonpath='{.spec.ports[0].nodePort}')"

echo ""
echo "📊 Service URLs:"
echo "   Kibana: $KIBANA_URL"
echo "   Elasticsearch: http://$(minikube ip):9200 (port-forward required)"
echo ""
echo "🔧 Useful commands:"
echo "   kubectl get pods -n log-analytics"
echo "   kubectl logs deployment/log-generator -n log-analytics"
echo "   kubectl port-forward svc/elasticsearch-service 9200:9200 -n log-analytics"
echo "   kubectl port-forward svc/kibana-service 5601:5601 -n log-analytics"
echo ""
echo "🛑 To clean up:"
echo "   kubectl delete namespace log-analytics"
echo "   minikube stop"