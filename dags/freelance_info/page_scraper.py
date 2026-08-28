from bs4 import BeautifulSoup
import requests
import logging
from gcp_utils import bigquery_util
from gcp_utils import gcs_util
import sys
import json
import datetime
from datetime import timezone


logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.info)


def parse_job_details(condition="link=link"):
    """
    Extracts the main details of a list of jobs.
    """

    base_url = "https://www.freelance-informatique.fr/"
    rows = bigquery_util.BigQuery().query_table(
        "dev-env-368414",
        "freelance_info",
        "list_links",
        condition=condition,
    )
    logger.info("Looping over rows of table list_links")

    job_list = []

    for row in rows:
        url = base_url + row.link.lstrip("/")
        logger.info(f"Scrapping the url: {url}")

        try:
            html = requests.get(url)
        except Exception as e:
            logger.error(f"Error occured during HTTP call of {url}: {e}")
            sys.exit(1)

        description, profil, sector, job = "", "", "", ""
        soup = BeautifulSoup(html.content, "html.parser")

        if soup:
            if soup.find("div", class_="mission-description"):
                try:
                    description = soup.find("div", class_="mission-description").get_text()
                except Exception as e:
                    logger.error(f"error occured during description extraction: {e}")

            if soup.find("li", title="Profil"):
                try:
                    profil = soup.find("li", title="Profil").get_text()
                except Exception as e:
                    logger.error(f"error occured during title extraction: {e}")

            if soup.find("li", title="Secteur d'activité"):
                try:
                    sector = soup.find("li", title="Secteur d'activité").get_text()
                except Exception as e:
                    logger.error(f"error occured during sector extraction: {e}")

            if soup.find("h1", class_="title"):
                try:
                    job = soup.find("h1", class_="title").get_text()
                except Exception as e:
                    logger.error(f"error occured during job extraction: {e}")
                    job = ""

        job_dict = {
            "job": job,
            "profil": profil,
            "sector": sector,
            "description": description,
            "skills": row.skills,
            "publish_date": row.publish_date,
            "location": row.location,
            "start_date": row.start_date,
            "duration": row.duration,
            "insert_date": str(row.insert_date),
        }
        logger.info(f"Constructing of job dict {job_dict}")
        job_list.append(job_dict)

    file_name = f"/tmp/freelance_info_jobs_{datetime.datetime.now(timezone.utc):%Y%m%dT%H%M%SZ}.jsonl"

    with open(file_name, "w", encoding="utf-8") as file:
        for job in job_list:
            file.write(json.dumps(job, ensure_ascii=False) + "\n")

    blob_name = f"freelance_info/jobs/{file_name.split('/')[-1]}"
    logger.info(f"Uploading parsed jobs to gs://freelance_info_jobs/{blob_name}")
    gcs_util.Gcs().upload_file(
        bucket_name="freelance_info_bucket",
        local_file_path=file_name,
        destination_blob_name=blob_name,
        content_type="application/x-ndjson",
    )
    return blob_name
