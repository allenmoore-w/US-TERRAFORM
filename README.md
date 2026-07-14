# VMware Enterprise Provisioning Execution Environment

This repository contains the Terraform configurations and automation scripts for deploying Windows/Linux VMs within the vSphere enterprise environment, integrated with BlueCat IPAM and CyberArk credential retrieval.

To ensure consistency across engineer laptops, jump boxes, and the upcoming CI/CD pipeline, all executions are run inside a standardized Linux Docker container.

---

## Prerequisites

Before running the automation, ensure your local workstation has the following installed:

1. **Docker Desktop** (or Rancher Desktop)
2. **Git Bash** (or a native Linux/WSL terminal)
3. **Kubernetes Access**: A valid `~/.kube/config` file giving you access to the `terraform-automation` namespace in our internal cluster (where the global state file lives).

---

## Local Quickstart Guide

Follow these steps to run a `terraform plan` or `apply` inside the isolated execution environment.

### A. Build the Execution Container
From the root of the repository, build the standardized runner image:
```bash
docker build -t tf-runner .


B. docker run -it --rm \
  -e TF_VAR_cyberark_password='YOUR_CYBERARK_API_PASSWORD' \
  -v "$PWD:/workspace" \
  -v "$HOME/.kube:/root/.kube" \
  tf-runner

C. # 1. Install required python libraries for CyberArk hooks
pip3 install requests

# 2. Navigate to your target environment
cd environments/dev

# 3. Initialize the Kubernetes backend
terraform init -reconfigure

# 4. Plan and Apply changes safely
terraform plan
terraform apply  
