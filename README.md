# Azure DevOps Bulk Repo Sync 🔁

A simple script to **automate Azure DevOps Git repo creation and initial code push** from local Terraform project folders. Designed to streamline Infrastructure-as-Code workflows.

---

## ✨ Features

- Creates missing Azure Repos using Azure DevOps REST API
- Initializes local Git repositories if needed
- Pushes code to `main`, `master`, or all branches
- Logs output to a file for easy tracking
- Designed for bulk processing multiple folders

---

## 📦 Requirements

- Bash (Linux/macOS or WSL on Windows)
- Git CLI
- Azure DevOps Personal Access Token (PAT) with repo permissions

---

## ⚙️ Configuration

Update the following values in the script:

```bash
AZURE_ORG="your-org-name"
AZURE_PROJECT_ID="your-project-id"
PAT="your-pat-token"
BASE_DIR="/absolute/path/to/your/terraform-folders"
