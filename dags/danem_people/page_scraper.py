from bs4 import BeautifulSoup
from datetime import timezone
import datetime
import json
import logging
import requests
import sys

from gcp_utils import bigquery_util, gcs_util


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def _get_listing_value(soup, class_name):
    element = soup.find("div", class_=class_name)
    return element.get_text(" ", strip=True) if element else ""


def parse_job_details(condition="link=link", base_url="https://www.danempeople.fr"):
    """Scrape job details, upload them as NDJSON, and return the GCS object name."""
    rows = bigquery_util.BigQuery().query_table(
        "dev-env-368414",
        "danem_people",
        "list_links",
        condition=condition,
    )
    logger.info("Looping over rows of table list_links")

    jobs = []
    for row in rows:
        url = base_url + row.link
        logger.info("Scraping %s", url)
        try:
            html = requests.get(url)
            html.raise_for_status()
        except requests.exceptions.RequestException as error:
            logger.error("HTTP request to %s failed: %s", url, error)
            sys.exit(1)

        soup = BeautifulSoup(html.content, "html.parser")
        description_parts = []
        description_container = soup.find("div", class_="bl-productItemElement-description")
        if description_container:
            description_parts.extend(item.get_text(" ", strip=True) for item in description_container.find_all("li"))
            description_parts.extend(item.get_text(" ", strip=True) for item in description_container.find_all("p"))

        short_description = soup.find("div", class_="bl-productItemElement-detail-shortdescription")
        if short_description:
            description_parts.insert(0, short_description.get_text(" ", strip=True))

        jobs.append(
            {
                "location_country": _get_listing_value(soup, "bl-listProductItem-pays"),
                "location_region": _get_listing_value(soup, "bl-listProductItem-region"),
                "sector": _get_listing_value(soup, "bl-listProductItem-secteur"),
                "description": " ".join(description_parts),
                "job_type": _get_listing_value(soup, "bl-listProductItem-type_de_contrat"),
                "salary_tjm": _get_listing_value(soup, "bl-listProductItem-salaire"),
                "link": row.link,
                "insert_date": str(row.insert_date),
            }
        )

    file_name = f"/tmp/danem_people_jobs_{datetime.datetime.now(timezone.utc):%Y%m%dT%H%M%SZ}.jsonl"
    with open(file_name, "w", encoding="utf-8") as file:
        for job in jobs:
            file.write(json.dumps(job, ensure_ascii=False) + "\n")

    blob_name = f"danem_people/jobs/{file_name.split('/')[-1]}"
    logger.info("Uploading parsed jobs to gs://danem_people_jobs/%s", blob_name)
    gcs_util.Gcs().upload_file(
        bucket_name="danem_people_jobs",
        local_file_path=file_name,
        destination_blob_name=blob_name,
        content_type="application/x-ndjson",
    )
    return blob_name
