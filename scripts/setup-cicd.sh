#!/usr/bin/env bash
#
# setup-cicd.sh - reproducible CLI half of Lab 3 Part 2 (Jenkins CI/CD on GKE).
#
# Automates the parts of the lab that are pure gcloud/helm/kubectl, so the
# report can cite exact commands and you can re-run instead of clicking.
# It does NOT click through the Jenkins UI (job creation, credentials,
# webhook) - those stay manual, see RUNBOOK.md.
#
# Run this in GCP Cloud Shell (where $GOOGLE_CLOUD_PROJECT is preset and a
# GKE cluster already exists), or locally with gcloud/helm/kubectl and an
# active login. Every step is idempotent: safe to re-run.
#
# Usage:
#   ./scripts/setup-cicd.sh sa        # step 1: service account + roles + key
#   ./scripts/setup-cicd.sh jenkins   # step 2: helm install Jenkins on GKE
#   ./scripts/setup-cicd.sh info      # step 3: print project/repo/cluster values for Jenkins credentials
#   ./scripts/setup-cicd.sh ip        # step 4: print the deployed app's external IP
#   ./scripts/setup-cicd.sh all       # sa + jenkins
#
set -euo pipefail

PROJECT="${GOOGLE_CLOUD_PROJECT:-${PROJECT:-}}"
SA="jenkins-sa"
KEY_FILE="${KEY_FILE:-service_account.json}"
VALUES="${VALUES:-jenkins/values.yaml}"   # path relative to repo root
RELEASE="cd-jenkins"

require_project() {
  if [[ -z "$PROJECT" ]]; then
    echo "ERROR: set PROJECT or GOOGLE_CLOUD_PROJECT to your GCP project id." >&2
    exit 1
  fi
  echo "Project: $PROJECT"
}

member() { echo "serviceAccount:${SA}@${PROJECT}.iam.gserviceaccount.com"; }

grant() {  # grant <role>, idempotent (add-iam-policy-binding is upsert)
  gcloud projects add-iam-policy-binding "$PROJECT" \
    --member "$(member)" \
    --role "$1" \
    --condition=None >/dev/null
  echo "  granted $1"
}

do_sa() {
  require_project
  # create SA only if missing
  if gcloud iam service-accounts describe "$(member | cut -d: -f2)" >/dev/null 2>&1; then
    echo "Service account $SA already exists, skipping create."
  else
    gcloud iam service-accounts create "$SA"
    echo "Created service account $SA."
  fi

  echo "Granting roles (lab section 2):"
  grant "roles/cloudbuild.builds.builder"
  grant "roles/container.clusterAdmin"
  grant "roles/container.admin"
  grant "roles/iam.serviceAccountUser"
  grant "roles/viewer"

  if [[ -f "$KEY_FILE" ]]; then
    echo "Key $KEY_FILE already exists, not overwriting. Delete it to regenerate."
  else
    gcloud iam service-accounts keys create "$KEY_FILE" \
      --iam-account="${SA}@${PROJECT}.iam.gserviceaccount.com"
    echo "Wrote $KEY_FILE. Upload this to Jenkins as the 'service_account' Secret file."
  fi

  echo
  echo "REMINDER (manual, lab sections 4-5):"
  echo "  - Enable the Cloud Build API in the console."
  echo "  - Grant 'Artifact Registry Writer' to the Compute Engine default SA"
  echo "    (PROJECT_NUMBER-compute@developer.gserviceaccount.com)."
}

do_jenkins() {
  require_project
  helm repo add jenkinsci https://charts.jenkins.io
  helm repo update
  if helm status "$RELEASE" >/dev/null 2>&1; then
    echo "Release $RELEASE already installed. To reinstall: helm uninstall $RELEASE"
  else
    helm install "$RELEASE" -f "$VALUES" jenkinsci/jenkins --wait
  fi
  echo "Jenkins services (wait for EXTERNAL-IP on the LoadBalancer):"
  kubectl get services
  echo
  echo "Admin password:"
  echo "  kubectl exec --namespace default -it svc/${RELEASE} -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password"
}

do_info() {
  require_project
  echo "project_id  -> $PROJECT"
  echo "repo_path   -> (Artifact Registry: copy the repository's full path, e.g. us-central1-docker.pkg.dev/${PROJECT}/<repo>)"
  echo "cluster_name/cluster_zone -> from: gcloud container clusters list"
  gcloud container clusters list 2>/dev/null || true
}

do_ip() {
  kubectl get service/binarycalculator-service \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null && echo || \
    echo "Service not found yet. Run the Jenkinsfile_v2 pipeline first."
}

case "${1:-}" in
  sa)      do_sa ;;
  jenkins) do_jenkins ;;
  info)    do_info ;;
  ip)      do_ip ;;
  all)     do_sa; do_jenkins ;;
  *) echo "usage: $0 {sa|jenkins|info|ip|all}" >&2; exit 1 ;;
esac
