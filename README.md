# Azure AKS Enterprise Platform

Production-grade Azure Kubernetes Service (AKS) platform built with Terraform, featuring full CI/CD automation via Azure DevOps, observability stack, and enterprise security controls.

## Overview

This repository contains Infrastructure-as-Code (IaC) and platform tooling for deploying and operating a hardened AKS platform across multiple environments (dev/uat/prod). Designed for enterprise environments with APRA CPS 234, PCI-DSS, and SOC 2 compliance requirements.

## Architecture

```
├── terraform/
│   ├── modules/
│   │   ├── aks-cluster/        # AKS cluster with node pools, RBAC, add-ons
│   │   ├── networking/         # VNet, subnets, Private Link, NSGs
│   │   ├── security/           # Key Vault, Azure Policy, Defender for Containers
│   │   └── monitoring/         # Azure Monitor, Log Analytics, alerts
│   └── environments/
│       ├── dev/
│       ├── uat/
│       └── prod/
├── helm/
│   ├── aks-app-template/       # Reusable Helm chart for microservices
│   └── monitoring-stack/       # Prometheus + Grafana deployment
├── pipelines/
│   ├── azure-devops/           # Azure DevOps YAML pipelines
│   └── github-actions/         # GitHub Actions workflows
└── scripts/                    # Operational Python/Bash utilities
```

## Key Features

- **AKS Cluster**: Multi-nodepool AKS with system and user pools, autoscaling, Azure CNI networking
- **Security**: Azure Private Link, Key Vault CSI driver, pod identity, network policies, Azure Policy
- **IaC**: 45+ Terraform modules managing all Azure resources across 3 environments
- **CI/CD**: Azure DevOps pipelines with security gates (Snyk, Trivy, SonarQube), Blue/Green deployments
- **Observability**: Azure Monitor, Application Insights, Prometheus, Grafana (35+ dashboards), PagerDuty
- **GitOps**: ArgoCD for application delivery with automated sync and rollback

## Prerequisites

- Terraform >= 1.5.0
- Azure CLI >= 2.50.0
- kubectl >= 1.27
- Helm >= 3.12

## Quick Start

```bash
# Clone the repo
git clone https://github.com/vkaushik13/azure-aks-platform
cd azure-aks-platform

# Authenticate to Azure
az login
az account set --subscription "<subscription-id>"

# Initialise Terraform for dev environment
cd terraform/environments/dev
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply
```

## Environment Configuration

Each environment uses its own `.tfvars` file with environment-specific values:

| Variable | Dev | UAT | Prod |
|---|---|---|---|
| `node_count` | 2 | 3 | 5 |
| `vm_size` | Standard_D4s_v3 | Standard_D8s_v3 | Standard_D16s_v3 |
| `availability_zones` | [1] | [1,2] | [1,2,3] |
| `log_retention_days` | 30 | 60 | 90 |

## Security Controls

- All cluster API endpoints use Private Link (no public endpoint)
- Workload Identity replaces pod-managed identity
- Azure Policy enforces pod security standards
- Container images scanned with Trivy before deployment
- Secrets managed via Azure Key Vault with CSI driver
- Network policies restrict pod-to-pod communication

## CI/CD Pipeline Flow

```
Code Push → Lint/Validate → Security Scan (Snyk/Trivy) → 
Terraform Plan → Manual Approval (prod) → Apply → 
Smoke Tests → Rollback on Failure
```

## Observability

- **Azure Monitor + Log Analytics**: Cluster metrics, node health, control plane logs
- **Application Insights**: APM for workloads, distributed tracing
- **Prometheus + Grafana**: Custom dashboards for platform and application metrics
- **PagerDuty**: Automated alerting with escalation policies

## Author

Varun Kaushik — Senior Azure Platform Engineer  
[linkedin.com/in/vakaushik](https://linkedin.com/in/vakaushik) | [waterapps.com.au](https://waterapps.com.au)
