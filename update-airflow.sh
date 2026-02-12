#!/bin/bash

# Set strict mode
set -euo pipefail

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_message "Script started"

# Load environment variables
load_env_vars() {
    local env_file="/home/sa_111538238704422697419/deploy/env_vars.sh"
    if [[ -f "$env_file" ]]; then
        log_message "Loading environment variables from $env_file"
        # shellcheck disable=SC1090
        source "$env_file"
    else
        log_message "Warning: $env_file not found. Using existing environment variables."
    fi
}

load_env_vars

# Ensure required variables are set
: "${PROJECT_ID:?PROJECT_ID is not set}"
: "${IMAGE_TAG:?IMAGE_TAG is not set}"
: "${GCS_LOGGING_BUCKET:?GCS_LOGGING_BUCKET is not set}"

log_message "PROJECT_ID: $PROJECT_ID"
log_message "IMAGE_TAG: $IMAGE_TAG"
log_message "GCS_LOGGING_BUCKET: $GCS_LOGGING_BUCKET"

# Retrieve service account key from Secret Manager and store it temporarily
log_message "Retrieving service account key from Secret Manager"
SA_KEY_FILE=$(mktemp)
if gcloud secrets versions access latest --secret=airflow-vm-sa-key > "$SA_KEY_FILE"; then
    log_message "Service account key retrieved successfully"
else
    log_message "Error: Failed to retrieve service account key"
    exit 1
fi

# Activate service account
log_message "Activating service account"
if gcloud auth activate-service-account --key-file="$SA_KEY_FILE"; then
    log_message "Service account activated successfully"
else
    log_message "Error: Failed to activate service account"
    exit 1
fi

# Prepare Google Cloud credentials for Airflow
log_message "Preparing Google Cloud credentials for Airflow"
SA_KEY_JSON=$(cat "$SA_KEY_FILE" | jq -c .)
SA_KEY_ENCODED=$(echo "$SA_KEY_JSON" | base64 -w 0)

# Remove the temporary key file
log_message "Removing temporary key file"
rm "$SA_KEY_FILE"

# Configure Docker to use gcloud as a credential helper
log_message "Configuring Docker authentication"
if sudo gcloud auth configure-docker europe-west1-docker.pkg.dev --quiet; then
    log_message "Docker authentication configured successfully"
else
    log_message "Error: Failed to configure Docker authentication"
    exit 1
fi
log_message "checking if postgres image exists"
# Check if the PostgreSQL image exists, pull it if it doesn't
if sudo docker image ls | grep -q "postgres"; then
  echo "PostgreSQL image already exists, using existing image"
else
  echo "PostgreSQL image not found, pulling latest"
  sudo docker pull postgres:latest
fi
log_message "cleaning up docker images"
# More selective cleanup approach that preserves the postgres container and data
if sudo docker image prune -af --filter "label!=postgres" && \
   sudo docker container ls -a | grep -v "postgres" | grep -v "Up" | awk '{print $1}' | xargs -r sudo docker rm && \
   sudo docker network prune -f && \
   sudo docker builder prune -f ; then
  echo "Docker cleanup completed successfully"
else
  echo "Docker cleanup failed"
  exit 1
fi

# Pull the Docker image with the correct tag
log_message "Pulling Docker image: europe-west1-docker.pkg.dev/${PROJECT_ID}/airflow/airflow:${IMAGE_TAG}"
if sudo docker pull "europe-west1-docker.pkg.dev/${PROJECT_ID}/airflow/airflow:${IMAGE_TAG}"; then
    log_message "Docker image pulled successfully"
else
    log_message "Error: Failed to pull Docker image"
    exit 1
fi

# Create a temporary docker-compose file with substituted variables
log_message "Creating temporary docker-compose file"
TEMP_COMPOSE_FILE=$(mktemp)
if sed -e "s|\${PROJECT_ID}|$PROJECT_ID|g" \
       -e "s|\${IMAGE_TAG}|$IMAGE_TAG|g" \
       -e "s|\${GCS_LOGGING_BUCKET}|$GCS_LOGGING_BUCKET|g" \
       -e "s|\${GOOGLE_APPLICATION_CREDENTIALS_JSON}|$SA_KEY_JSON|g" \
       -e "s|\${AIRFLOW_CONN_GOOGLE_CLOUD_DEFAULT}|google-cloud-platform://?extra__google_cloud_platform__project=${PROJECT_ID}\&extra__google_cloud_platform__keyfile_dict=${SA_KEY_ENCODED}|g" \
       /home/sa_111538238704422697419/deploy/docker-compose.yml > "$TEMP_COMPOSE_FILE"; then
    log_message "Temporary docker-compose file created successfully"
else
    log_message "Error: Failed to create temporary docker-compose file"
    exit 1
fi

# Start the services with the temporary docker-compose file
log_message "Starting services with docker-compose"
if sudo -E docker-compose -f "$TEMP_COMPOSE_FILE" up -d; then
    log_message "Services started successfully"
else
    log_message "Error: Failed to start services"
    exit 1
fi

# Remove the temporary files
log_message "Removing temporary docker-compose file"
rm "$TEMP_COMPOSE_FILE"

# Clean up unused Docker images
log_message "Cleaning up unused Docker images"
sudo docker image prune -f

log_message "Script completed successfully"