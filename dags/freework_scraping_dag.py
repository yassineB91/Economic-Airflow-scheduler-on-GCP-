from airflow.decorators import dag, task
from datetime import datetime
from freework_scripts import link_scraper, page_scraper
from airflow.operators.bash import BashOperator
from plugins.slack_webhook import task_success_slack_alert, task_failure_slack_alert


 

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
        page_scraper.parse_job_details(condition=f"{filter}")
    
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


    get_page_number_task() >> link_scraper_task() >> page_scraper_task() >> [freelance_cleaning_task,cdi_cleaning_task,cdi_freelance_cleaning_task] >> jobs_cleaning_aggregation >> [jobs_modeling_experience,jobs_modeling_type,jobs_modeling_location,jobs_modeling_skills] >> jobs_modeling_fact_jobs_initial >> jobs_modeling_bridge_job_skill >> jobs_modeling_ref_job_category 

freework_job_scraper()


