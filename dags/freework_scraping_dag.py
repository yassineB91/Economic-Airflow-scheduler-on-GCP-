from airflow.decorators import dag, task
from datetime import datetime
from freework_scripts import link_scraper, page_scraper
from airflow.operators.bash import BashOperator
from plugins.slack_webhook import task_success_slack_alert, task_failure_slack_alert
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import GCSToBigQueryOperator
from airflow.providers.google.cloud.transfers.gcs_to_gcs import GCSToGCSOperator




 

default_args = {
    'email_on_failure': True,
    'on_failure_callback': task_failure_slack_alert,
    'on_success_callback': task_success_slack_alert
}

@dag(start_date=datetime(2024,5,20),schedule='@daily', catchup=False, tags=["freework"], default_args=default_args)

def freework_job_scraper():

    @task(on_failure_callback=task_failure_slack_alert, on_success_callback=task_success_slack_alert)
    def get_page_number_task(ti=None):
        number_of_pages=link_scraper.get_page_number(initial_url="https://www.free-work.com/fr/tech-it/jobs?freshness=less_than_24_hours&query=")
        ti.xcom_push(key="number_of_pages",value=number_of_pages)
    
    @task(on_failure_callback=task_failure_slack_alert, on_success_callback=task_success_slack_alert)
    def link_scraper_task(ti=None):
        number_of_pages=ti.xcom_pull(task_ids="get_page_number_task",key="number_of_pages")
        link_scraper.get_job_links(number_of_pages,initial_url="https://www.free-work.com/fr/tech-it/jobs?freshness=less_than_24_hours&query=")

    @task(on_failure_callback=task_failure_slack_alert, on_success_callback=task_success_slack_alert)
    def page_scraper_task():
        filter="cast(cast(insert_date as timestamp) as date) = current_date()"
        return page_scraper.parse_job_details(condition=f"{filter}")

    uploaded_file = page_scraper_task()

    load_json_into_bq = GCSToBigQueryOperator(
        task_id="load_jobs_to_bigquery",
        bucket="freework_jobs",
        source_objects=[uploaded_file],
        source_format="NEWLINE_DELIMITED_JSON",
        destination_project_dataset_table="dev-env-368414.freework.job_list",
        write_disposition="WRITE_APPEND",
        external_table=False,
        autodetect=True,
        deferrable=True,
    )

    move_loaded_file = GCSToGCSOperator(
    task_id="move_loaded_file",
    source_bucket="freework_jobs",
    source_object="{{ ti.xcom_pull(task_ids='page_scraper_task') }}",
    destination_bucket="freework_jobs",
    destination_object="freework/loaded/",
    move_object=True,
)
    
    variable = f"{str(datetime.now().date())}"
    freelance_cleaning_task = BashOperator(task_id="freelance_cleaning_task",bash_command=f"cd /opt/airflow/dbt && \
                                 dbt run --profiles-dir . --select jobs_cleaning_freelance",
        on_failure_callback=task_failure_slack_alert,
        on_success_callback=task_success_slack_alert)
    cdi_cleaning_task = BashOperator(task_id="cdi_cleaning_task",bash_command=f"cd /opt/airflow/dbt && \
                                 dbt run --profiles-dir . --select jobs_cleaning_cdi",
        on_failure_callback=task_failure_slack_alert,
        on_success_callback=task_success_slack_alert)
    cdi_freelance_cleaning_task = BashOperator(task_id="cdi_freelance_cleaning_task",bash_command=f"cd /opt/airflow/dbt && \
                                 dbt run --profiles-dir . --select jobs_cleaning_freelance_cdi",
        on_failure_callback=task_failure_slack_alert,
        on_success_callback=task_success_slack_alert)
    jobs_cleaning_aggregation = BashOperator(task_id="jobs_cleaning_aggregation",bash_command=f"cd /opt/airflow/dbt && \
                                 dbt run --profiles-dir . --select jobs_cleaning_aggregation",
        on_failure_callback=task_failure_slack_alert,
        on_success_callback=task_success_slack_alert)
    ##
    jobs_modeling_experience = BashOperator(task_id="jobs_modeling_experience",bash_command=f"cd /opt/airflow/dbt && \
                                 dbt run --profiles-dir . --select jobs_modeling_experience",
        on_failure_callback=task_failure_slack_alert,
        on_success_callback=task_success_slack_alert)
    jobs_modeling_type = BashOperator(task_id="jobs_modeling_type",bash_command=f"cd /opt/airflow/dbt && \
                                 dbt run --profiles-dir . --select jobs_modeling_type",
        on_failure_callback=task_failure_slack_alert,
        on_success_callback=task_success_slack_alert)
    jobs_modeling_location = BashOperator(task_id="jobs_modeling_location",bash_command=f"cd /opt/airflow/dbt && \
                                 dbt run --profiles-dir . --select jobs_modeling_location",
        on_failure_callback=task_failure_slack_alert,
        on_success_callback=task_success_slack_alert)
    jobs_modeling_skills = BashOperator(task_id="jobs_modeling_skills",bash_command=f"cd /opt/airflow/dbt && \
                                 dbt run --profiles-dir . --select jobs_modeling_skills",
        on_failure_callback=task_failure_slack_alert,
        on_success_callback=task_success_slack_alert)
    jobs_modeling_fact_jobs_initial = BashOperator(task_id="jobs_modeling_fact_jobs_initial",bash_command=f"cd /opt/airflow/dbt && \
                                 dbt run --profiles-dir . --select jobs_modeling_fact_jobs_initial",
        on_failure_callback=task_failure_slack_alert,
        on_success_callback=task_success_slack_alert)
    jobs_modeling_bridge_job_skill = BashOperator(task_id="jobs_modeling_bridge_job_skill",bash_command=f"cd /opt/airflow/dbt && \
                                 dbt run --profiles-dir . --select jobs_modeling_bridge_job_skill",
        on_failure_callback=task_failure_slack_alert,
        on_success_callback=task_success_slack_alert)
    jobs_modeling_ref_job_category = BashOperator(task_id="jobs_modeling_ref_job_category",bash_command=f"cd /opt/airflow/dbt && \
                                 dbt run --profiles-dir . --select jobs_modeling_ref_job_category",
        on_failure_callback=task_failure_slack_alert,
        on_success_callback=task_success_slack_alert)


    get_page_number_task() >> link_scraper_task() >> uploaded_file 
    uploaded_file >> load_json_into_bq >> move_loaded_file >> [freelance_cleaning_task,cdi_cleaning_task,cdi_freelance_cleaning_task] >> jobs_cleaning_aggregation >> [jobs_modeling_experience,jobs_modeling_type,jobs_modeling_location,jobs_modeling_skills] >> jobs_modeling_fact_jobs_initial >> jobs_modeling_bridge_job_skill >> jobs_modeling_ref_job_category 

freework_job_scraper()


