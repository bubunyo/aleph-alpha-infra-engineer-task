# Aleph Alpha Platform 

## Overview

This repository contains a complete infrastructure-as-code solution for deploying a guestbook application with comprehensive monitoring, logging, and alerting capabilities. The solution uses Terraform for infrastructure management, Kubernetes (Kind) for container orchestration, and includes a full observability stack.

## Architecture

### Components

- **Kubernetes Cluster**: Local Kind cluster with NGINX Ingress
- **Applications**: 
  - MongoDB database
  - Python Flask backend API
  - Python Flask frontend web interface
- **Monitoring Stack**:
  - **Prometheus**: Metrics collection and storage
  - **Grafana**: Visualization and alerting
  - **Loki**: Log aggregation
  - **Promtail**: Log collection
- **Alerting**: Grafana with PagerDuty integration
- **CI/CD**: GitHub Actions workflows with folder-specific triggers

## Prerequisites

- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) - Kubernetes in Docker
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) - Container runtime
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) - Kubernetes CLI
- [Helm 3.12+](https://helm.sh/docs/intro/install/) - Kubernetes package manager
- [Terraform 1.0+](https://developer.hashicorp.com/terraform/downloads) - Infrastructure as Code
- [Make](https://www.gnu.org/software/make/) - Build automation (pre-installed on macOS/Linux)
- [Python 3.9+](https://www.python.org/downloads/) - Application runtime

## Quick Start

### 1. Generate Docker Socket File

Create the required `.docker_sock` file for Terraform Kind provider:

```bash
docker context inspect --format '{{.Endpoints.docker.Host}}' > infra/.docker_sock
```

### 2. Configure GitHub Secrets (Optional)

For production deployments, configure GitHub repository secrets. If not provided, default values will be used:

**Required for PagerDuty:**
- `PAGERDUTY_INTEGRATION_KEY` - Follow the [PagerDuty Integration Guide](https://grafana.com/docs/grafana/latest/alerting/configure-notifications/manage-contact-points/integrations/pager-duty/)

**Optional (defaults provided):**
- `MONGODB_ROOT_USERNAME` (default: `admin`)
- `MONGODB_ROOT_PASSWORD` (default: `admin1234`)
- `MONGODB_USERNAME` (default: `guestbook`)
- `MONGODB_PASSWORD` (default: `guestbook123`)
- `GRAFANA_ADMIN_USERNAME` (default: `admin`)
- `GRAFANA_ADMIN_PASSWORD` (default: `admin123`)

### 3. Deploy Infrastructure

```bash
# Navigate to infrastructure directory
cd infra

# Initialize Terraform
terraform init

# Create secrets file by copying the example and filling in values
cp secrets.tfvars.example secrets.tfvars
# Edit secrets.tfvars with your actual values

# Plan and apply
terraform plan -var-file="secrets.tfvars"
terraform apply -var-file="secrets.tfvars"
```

### 4. Build and Deploy Applications

```bash
# Build all components (images will be pushed to local registry)
./scripts/build.sh --component=all

# Or build and deploy individually
./scripts/backend_build_deploy.sh   # Build and deploy backend
./scripts/frontend_build_deploy.sh  # Build and deploy frontend

# Build specific component without deployment
./scripts/build.sh --component=backend    # Backend only
./scripts/build.sh --component=frontend   # Frontend only
./scripts/build.sh --no-test             # Skip tests
```

### 5. Verify Deployment

```bash
# Check all pods are running
kubectl get pods -A

# Check services
kubectl get svc -A

# Test application endpoints
curl -f http://frontend.localhost/health
curl -f http://grafana.localhost/api/health
```

## Service Endpoints

_⚠️ Accessing endpoints in safari browser wont work. Use a Chrome based browser_

- **Application Frontend**: http://localhost
- **Grafana Dashboard**: http://grafana.localhost
- **Prometheus Dashboard**: http://prometheus.localhost
- **Alert**: http://grafana.localhost/alerting/list

## Application Development

### Backend API

The backend is a Flask application providing:
- REST API for guestbook messages
- Health endpoints (`/health`, `/ready`)
- Prometheus metrics (`/metrics`)
- MongoDB integration

**Development:**
```bash
cd src/backend
make install
make test
make run
```

### Frontend Web Interface

The frontend is a Flask application providing:
- Web interface for guestbook
- Health endpoints (`/health`, `/ready`)  
- Prometheus metrics (`/metrics`)
- Backend API integration

**Development:**
```bash
cd src/frontend
make install
make test
make run
```

### Build and Deploy Scripts

The project includes automated build and deploy scripts in the `scripts/` folder:

**Main Build Script (`scripts/build.sh`):**
- Unified build script for all components
- Supports building backend, frontend, or all components
- Configurable registry URL (default: localhost:5000)
- Optional test execution
- Image tagging with git SHA and latest
- Registry verification

**Component Deploy Scripts:**
- `scripts/backend_build_deploy.sh` - Builds backend and triggers rolling deployment
- `scripts/frontend_build_deploy.sh` - Builds frontend and triggers rolling deployment

**Usage Examples:**
```bash
# Build all components with tests
./scripts/build.sh --component=all

# Build only backend without tests
./scripts/build.sh --component=backend --no-test

# Build and deploy backend with rolling update
./scripts/backend_build_deploy.sh

# Use custom registry
./scripts/build.sh --component=frontend --registry=my-registry.com:5000
```

**Script Features:**
- Automatic registry health checks
- Docker image building and pushing
- Kubernetes rolling deployments
- Component verification
- Color-coded output for better visibility

## Monitoring and Alerting

### Metrics Collection

Both applications expose Prometheus metrics including:
- HTTP request duration histograms
- HTTP request counters by status code
- Application uptime metrics
- Custom business metrics

### Alert Rules

Custom alert rules can be added in `infra/alert_rules`

### Access Monitoring

- **Grafana**: http://grafana.localhost
- **Prometheus**: http://prometheus.localhost

## Cluster Management

### Terraform-Managed Infrastructure

The entire Kubernetes cluster and infrastructure is managed by Terraform:

- **Cluster Creation**: Terraform automatically creates the Kind cluster with proper configuration
- **Registry Setup**: Docker registry is provisioned and configured for image storage
- **Ingress Controller**: NGINX ingress is deployed automatically
- **Monitoring Stack**: Prometheus, Grafana, and Loki are deployed via Helm charts
- **Applications**: Backend, frontend, and MongoDB are deployed automatically

### Manual Cluster Operations

```bash
# View cluster status
kubectl cluster-info
kubectl get nodes

# Check all pods across namespaces
kubectl get pods -A

# Access cluster directly
kind get kubeconfig --name aa-cluster

# Delete cluster (if needed)
kind delete cluster --name aa-cluster
```

### Workflow Dependencies

- **Infrastructure workflow** creates and manages the cluster
- **Application workflows** connect to the existing cluster (no manual setup required)
- All workflows assume the cluster exists and is accessible via `aa-cluster` name

## CI/CD Workflows

### Folder-Specific Triggers

**Infrastructure Deployment** (`.github/workflows/infra-deploy.yml`):
- Triggers: Changes to `infra/**`
- Actions: Terraform plan/apply, infrastructure validation

**Backend Deployment** (`.github/workflows/backend-deploy.yml`):
- Triggers: Changes to `src/backend/**` or `infra/charts/guestbook-backend/**`
- Actions: Testing, linting, Docker build, Helm deployment

**Frontend Deployment** (`.github/workflows/frontend-deploy.yml`):
- Triggers: Changes to `src/frontend/**` or `infra/charts/guestbook-frontend/**`
- Actions: Testing, linting, template validation, Docker build, Helm deployment

## Infrastructure Details

### Terraform Structure

```
infra/
├── main.tf               # Provider configuration
├── cluster_management.tf # Kind cluster and namespaces
├── prometheus.tf         # Prometheus monitoring
├── grafana.tf            # Grafana with alerting
├── loki.tf               # Log aggregation
├── mongodb.tf            # Database deployment
├── backend.tf            # Backend application
├── frontend.tf           # Frontend application
└── alert_rules/          # Alert rule definitions
    ├── service_availability_alerts.yml
    ├── request_latency_alerts.yml
    └── error_rate_alerts.yml
```

### Custom Helm Charts

```
infra/charts/
├── guestbook-mongodb/     # MongoDB StatefulSet
├── guestbook-backend/     # Backend Deployment
└── guestbook-frontend/    # Frontend Deployment
```

Each chart includes:
- Deployment/StatefulSet configurations
- Service definitions
- Ingress rules
- ServiceMonitor for Prometheus discovery
- Health check configurations

### Accessing Logs

All logs are collected with `Promtail` and inserted into Loki, queryable from grafana


## Development Workflow

1. **Feature Development**: Make changes in respective directories
2. **Local Testing**: Use Makefiles for testing and validation
3. **Pull Request**: GitHub workflows run automatically
4. **Review**: Check PR comments for test results and deployment status
5. **Merge**: Automatic deployment to Kind cluster on merge to main

## Future Improvements

- Multi-node cluster or migration to managed Kubernetes (EKS/GKE/AKS)
- Scaling for StatefulSets with replica sets
- Pod Autoscaling (HPA/VPA) for applications based on metrics & dynamic resources
- External secrets management (AWS Secrets Manager, HashiCorp Vault, Kubernetes External Secrets)
- Pod Security Standards and Network Policies
- Service mesh (Istio/Linkerd) for mTLS between services
- Container image scanning and vulnerability management
- RBAC refinement with least-privilege principles
- Custom Grafana dashboards for business metrics and SLIs
- SLO/SLI tracking with error budgets
- Distributed tracing with Jaeger or Zipkin
- Application Performance Monitoring (APM) integration
- Alert fatigue reduction through intelligent grouping and suppression
- Contract testing between frontend and backend services
- Canary deployments and blue-green deployment strategies
- ArgoCD or Flux for GitOps deployment workflows
- Terraform remote state management (S3, Terraform Cloud)
- Infrastructure testing with Terratest or similar frameworks
- Multi-environment management (dev/staging/prod)
 