#!/bin/bash
set -e

# Wait for the PostgreSQL database to be ready
/wait-for-it.sh postgres:5432 --timeout=60 --strict -- echo "PostgreSQL is up"

# Handle Google Cloud credentials
if [ -n "$GOOGLE_APPLICATION_CREDENTIALS_JSON" ]; then
    echo "$GOOGLE_APPLICATION_CREDENTIALS_JSON" > /opt/airflow/google_credentials.json
    chmod 600 /opt/airflow/google_credentials.json
    export GOOGLE_APPLICATION_CREDENTIALS=/opt/airflow/google_credentials.json
fi

# Initialize the Airflow database if it hasn't been initialized yet
if [[ ! -f /opt/airflow/.initialized ]]; then
    airflow db init
    AIRFLOW_ADMIN_USERNAME="${AIRFLOW_ADMIN_USERNAME:-admin}"
    AIRFLOW_ADMIN_FIRSTNAME="${AIRFLOW_ADMIN_FIRSTNAME:-Admin}"
    AIRFLOW_ADMIN_LASTNAME="${AIRFLOW_ADMIN_LASTNAME:-User}"
    AIRFLOW_ADMIN_EMAIL="${AIRFLOW_ADMIN_EMAIL:-admin@example.com}"
    AIRFLOW_ADMIN_PASSWORD="${AIRFLOW_ADMIN_PASSWORD:-change-me-airflow-admin-password}"
    airflow users create \
        --username "$AIRFLOW_ADMIN_USERNAME" \
        --firstname "$AIRFLOW_ADMIN_FIRSTNAME" \
        --lastname "$AIRFLOW_ADMIN_LASTNAME" \
        --role Admin \
        --email "$AIRFLOW_ADMIN_EMAIL" \
        --password "$AIRFLOW_ADMIN_PASSWORD"
    
    # Add Google Cloud connection
    if [ -n "$AIRFLOW_CONN_GOOGLE_CLOUD_DEFAULT" ]; then
        airflow connections add 'google_cloud_default' --conn-uri "$AIRFLOW_CONN_GOOGLE_CLOUD_DEFAULT"
    fi
    
    touch /opt/airflow/.initialized
fi

# Ensure GCS logging is enabled
if [ "$AIRFLOW__CORE__REMOTE_LOGGING" = "True" ]; then
    echo "Configuring GCS logging..."
    echo "AIRFLOW__LOGGING__REMOTE_LOGGING=${AIRFLOW__LOGGING__REMOTE_LOGGING}"
    echo "AIRFLOW__LOGGING__REMOTE_BASE_LOG_FOLDER=${AIRFLOW__LOGGING__REMOTE_BASE_LOG_FOLDER}"
    echo "AIRFLOW__LOGGING__REMOTE_LOG_CONN_ID=${AIRFLOW__LOGGING__REMOTE_LOG_CONN_ID}"
fi

# Execute the provided command
exec "$@"
