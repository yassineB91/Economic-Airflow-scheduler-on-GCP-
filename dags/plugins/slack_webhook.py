from airflow.hooks.base import BaseHook
from airflow.providers.slack.operators.slack_webhook import SlackWebhookOperator
import logging

SLACK_CONN_ID = 'slack_webhook'

def task_slack_alert(context, success=True):
    status = ":large_green_circle: Task Succeeded" if success else ":red_circle: Task Failed"
    slack_msg = f"""
    {status}
    *Task*: {context.get('task_instance').task_id}
    *Dag*: {context.get('task_instance').dag_id}
    *Execution Time*: {context.get('execution_date')}
    *Log Url*: {context.get('task_instance').log_url}
    """

    logging.info(f"Sending Slack message: {slack_msg}")

    alert = SlackWebhookOperator(
        task_id='slack_alert',
        slack_webhook_conn_id=SLACK_CONN_ID,
        message=slack_msg,
        username='airflow'
    )

    try:
        result = alert.execute(context=context)
        logging.info(f"Slack alert sent successfully. Response: {result}")
        return result
    except Exception as e:
        logging.error(f"Error sending Slack alert: {str(e)}")
        raise

def task_success_slack_alert(context):
    return task_slack_alert(context, success=True)

def task_failure_slack_alert(context):
    return task_slack_alert(context, success=False)