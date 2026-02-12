# Economic Airflow Scheduler on GCP

Production-oriented Apache Airflow project for scraping job-market data, transforming it with dbt, and storing curated datasets in BigQuery.

![Ingestion Architecture](./Ingestion%20Architecture.png)

## What This Repository Does

This repository runs daily pipelines that:

1. Scrape job listings from multiple sources.
2. Persist raw/intermediate data in BigQuery and/or GCS.
3. Run dbt transformations (cleaning + modeling).
4. Expose transformed datasets in BigQuery.
5. Send Slack alerts on task success/failure.

## Data Sources

- `free-work.com`
- `freelance-informatique.fr`
- `danempeople.fr`

## Tech Stack

- Apache Airflow (`CeleryExecutor`)
- dbt Core + dbt BigQuery
- Google BigQuery
- Google Cloud Storage (GCS)
- Docker / Docker Compose
- Redis + Postgres (Airflow backend)
- Slack Webhook notifications
- Google Cloud Build + Artifact Registry + Compute Engine VM

## Repository Structure

- `dags/`: Airflow DAGs and scraping modules
- `dags/freework_scripts/`: Freework scraping logic
- `dags/freelance_info/`: Freelance Informatique scraping logic
- `dags/danem_people/`: Danem People scraping logic
- `dags/gcp_utils/`: BigQuery/GCS/PubSub helper utilities
- `dags/plugins/slack_webhook.py`: task callback notifications
- `dbt/`: dbt project (`processing`) and models
- `docker-compose.yml`: runtime stack (webserver, scheduler, worker, init, redis, postgres)
- `dockerfile`: Airflow custom image
- `cloudbuild.yaml`: CI/CD pipeline for image build + VM rollout
- `update-airflow.sh`: deployment script run on the GCE VM
- `tests/dags/`: DAG import/basic quality tests

## DAGs

### `freework_job_scraper` (`dags/freework_scraping_dag.py`)

Schedule: `@daily`

Flow:
- get number of pages
- scrape links into BigQuery (`freework.list_links`)
- scrape job details into `freework.job_list`
- run dbt cleaning models
- run dbt modeling models

### `freelance_info_job_scraper` (`dags/freelance_info_dag.py`)

Schedule: `@daily`

Flow:
- get number of pages
- scrape links to GCS (`gs://freelance_info_bucket/to_be_processed/...`)
- run dbt merge model (`freelance_info_link_list_merge`)
- scrape job details into BigQuery (`freelance_info.job_list`)
- move processed link file to `processed/`

### `danem_people_job_scraper` (`dags/danem_people_scraping_dag.py`)

Schedule: `@daily`

Flow:
- get number of pages
- scrape links to GCS (`gs://danem_people_bucket/to_be_processed/...`)
- run dbt merge model (`danem_people_link_list_merge`)
- scrape job details into BigQuery (`danem_people.job_list`)
- move processed link file to `processed/`
- run dbt cleaning + modeling

## Prerequisites

- Docker + Docker Compose
- GCP project with:
  - BigQuery datasets
  - GCS buckets used by pipelines
  - service account with required permissions
- Slack webhook (optional but configured in current stack)

## Required Environment Variables

`docker-compose.yml` expects these variables:

- `PROJECT_ID`
- `IMAGE_TAG`
- `GCS_LOGGING_BUCKET`
- `GOOGLE_APPLICATION_CREDENTIALS_JSON` (JSON content, not a file path)
- `AIRFLOW_CONN_GOOGLE_CLOUD_DEFAULT` (Airflow connection URI)

## Run Locally

1. Build image:

```bash
docker build -t europe-west1-docker.pkg.dev/${PROJECT_ID}/airflow/airflow:${IMAGE_TAG} -f dockerfile .
```

2. Export required env vars:

```bash
export PROJECT_ID="your-gcp-project"
export IMAGE_TAG="dev"
export GCS_LOGGING_BUCKET="your-log-bucket"
export GOOGLE_APPLICATION_CREDENTIALS_JSON="$(cat /path/to/sa.json)"
export AIRFLOW_CONN_GOOGLE_CLOUD_DEFAULT="google-cloud-platform://?extra__google_cloud_platform__project=your-gcp-project"
```

3. Start services:

```bash
docker compose up -d
```

4. Open Airflow UI:

- `http://localhost:8080`
- default credentials (from init script): `admin / admin`

5. Stop services:

```bash
docker compose down
```

## dbt Project

- dbt project name: `processing`
- dbt profiles file: `dbt/profiles.yml`
- configured outputs:
  - `freework`
  - `freelance_info`
  - `danem_people`
  - `villeideal`

Run an example model manually:

```bash
cd dbt
dbt run --profiles-dir . --target freework --select jobs_modeling_fact_jobs
```

## Tests

Run DAG tests:

```bash
pytest tests/dags/test_dag_example.py
```

## Deployment (Cloud Build -> GCE VM)

`cloudbuild.yaml` performs:

1. Docker build of Airflow image.
2. Push to Artifact Registry.
3. SSH-based deployment to GCE VM.
4. Execution of `update-airflow.sh` on VM to pull image and restart stack.

`update-airflow.sh` also:

- loads env vars from VM-side `env_vars.sh`
- pulls service account key from Secret Manager (`airflow-vm-sa-key`)
- configures Docker auth for Artifact Registry
- renders a temporary `docker-compose.yml` with substituted variables
- runs `docker-compose up -d`

## Notes and Operational Cautions

- This codebase currently includes hardcoded project/dataset/bucket names in several DAG modules. If you deploy to a different project, update those values or parameterize them.
- `docker-compose.yml` currently includes a literal Slack webhook environment variable; store secrets in a secret manager or `.env` instead of committing live webhook URLs.
- Airflow and providers should be version-pinned consistently between `dockerfile` base image and `requirements.txt` to reduce dependency drift.

## Useful Commands

```bash
# list running services
docker compose ps

# tail scheduler logs
docker compose logs -f airflow-scheduler

# open a shell in webserver container
docker compose exec airflow-webserver bash

# run dbt tests inside container
docker compose exec airflow-webserver bash -lc 'cd /opt/airflow/dbt && dbt test --profiles-dir .'
```
