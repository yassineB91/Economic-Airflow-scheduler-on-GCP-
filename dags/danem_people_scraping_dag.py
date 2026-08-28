from airflow.decorators import dag, task
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import GCSToBigQueryOperator
from airflow.providers.google.cloud.transfers.gcs_to_gcs import GCSToGCSOperator
from datetime import datetime

from danem_people import link_scraper, page_scraper
from plugins.slack_webhook import task_failure_slack_alert, task_success_slack_alert


default_args = {
    "email_on_failure": True,
    "on_failure_callback": task_failure_slack_alert,
    "on_success_callback": task_success_slack_alert,
}


@dag(
    start_date=datetime(2024, 5, 20),
    schedule="@daily",
    catchup=False,
    tags=["danem_people"],
    default_args=default_args,
)
def danem_people_job_scraper():
    @task(on_failure_callback=task_failure_slack_alert, on_success_callback=task_success_slack_alert)
    def get_page_number_task(ti=None):
        number_of_pages = link_scraper.get_page_number()
        ti.xcom_push(key="number_of_pages", value=number_of_pages)

    @task(on_failure_callback=task_failure_slack_alert, on_success_callback=task_success_slack_alert)
    def link_scraper_task(ti=None):
        number_of_pages = ti.xcom_pull(task_ids="get_page_number_task", key="number_of_pages")
        link_scraper.get_job_links(number_of_pages)

    @task(on_failure_callback=task_failure_slack_alert, on_success_callback=task_success_slack_alert)
    def page_scraper_task():
        filter_condition = "cast(cast(insert_date as timestamp) as date) = current_date()"
        return page_scraper.parse_job_details(condition=filter_condition)

    uploaded_file = page_scraper_task()

    load_json_into_bq = GCSToBigQueryOperator(
        task_id="load_jobs_to_bigquery",
        bucket="danem_people_jobs",
        source_objects=[uploaded_file],
        source_format="NEWLINE_DELIMITED_JSON",
        destination_project_dataset_table="dev-env-368414.danem_people.job_list",
        write_disposition="WRITE_APPEND",
        external_table=False,
        autodetect=True,
        location="europe-west1",
        deferrable=True,
    )

    move_loaded_file = GCSToGCSOperator(
        task_id="move_loaded_file",
        source_bucket="danem_people_jobs",
        source_object="{{ ti.xcom_pull(task_ids='page_scraper_task') }}",
        destination_bucket="danem_people_jobs",
        destination_object="danem_people/loaded/",
        move_object=True,
    )

    get_page_number_task() >> link_scraper_task() >> uploaded_file
    uploaded_file >> load_json_into_bq >> move_loaded_file


danem_people_job_scraper()
