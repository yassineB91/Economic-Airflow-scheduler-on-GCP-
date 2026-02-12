from airflow.decorators import dag, task
from datetime import datetime
from freelance_info import link_scraper, page_scraper
from airflow.operators.bash import BashOperator
from plugins.slack_webhook import task_success_slack_alert, task_failure_slack_alert


 

default_args = {
    'email_on_failure': True,
    'on_failure_callback': task_failure_slack_alert,
    'on_success_callback': task_success_slack_alert
}

@dag(start_date=datetime(2024,5,20),schedule='@daily', catchup=False, tags=["freelance_info"], default_args=default_args)

def freelance_info_job_scraper():

    @task(on_failure_callback=task_failure_slack_alert, on_success_callback=task_success_slack_alert)
    def get_page_number_task(ti=None):
        number_of_pages=link_scraper.get_page_number(initial_url="https://www.freelance-informatique.fr/offres-freelance")
        ti.xcom_push(key="number_of_pages",value=number_of_pages)
    
    @task(on_failure_callback=task_failure_slack_alert, on_success_callback=task_success_slack_alert)
    def link_scraper_task(ti=None):
        number_of_pages=ti.xcom_pull(task_ids="get_page_number_task",key="number_of_pages")
        link_scraper.get_job_links(number_of_pages,initial_url="https://www.freelance-informatique.fr/offres-freelance")

    @task(on_failure_callback=task_failure_slack_alert, on_success_callback=task_success_slack_alert)
    def page_scraper_task():
        filter="cast(cast(insert_date as timestamp) as date) = current_date()"
        page_scraper.parse_job_details(condition=f"{filter}")
    
    freelance_info_link_list_merge_task = BashOperator(task_id="freelance_info_link_list_merge_task",bash_command=f"cd /opt/airflow/dbt && \
                                  dbt run --profiles-dir . --target freelance_info --select freelance_info_link_list_merge",
                                  on_failure_callback=task_failure_slack_alert, on_success_callback=task_success_slack_alert)
    
    @task(on_failure_callback=task_failure_slack_alert, on_success_callback=task_success_slack_alert)
    def move_processed_files_task():
        link_scraper.move_processed_files()
  

    get_page_number_task() >> link_scraper_task() >> freelance_info_link_list_merge_task >> page_scraper_task() >> move_processed_files_task()

freelance_info_job_scraper()


