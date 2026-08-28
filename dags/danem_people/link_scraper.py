from bs4 import BeautifulSoup
import logging
from datetime import datetime
import requests
import sys

from gcp_utils import bigquery_util


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def get_page_number(initial_url="https://www.danempeople.fr/resultats-de-recherche.php"):
    """Fetch the number of pages of job listings."""
    try:
        html = requests.get(initial_url)
        html.raise_for_status()
    except requests.exceptions.RequestException as error:
        logger.error("The HTTP request to %s failed: %s", initial_url, error)
        sys.exit(1)

    soup = BeautifulSoup(html.content, "html.parser")
    try:
        job_count_str = soup.find("div", class_="bl-paginationCount").get_text(strip=True)
        number_of_jobs = int(job_count_str.split("sur")[1])
        number_of_pages = round(number_of_jobs / 16)
    except Exception as error:
        logger.error("Error parsing %s: %s", initial_url, error)
        raise

    logger.info("Number of pages to scrape: %s", number_of_pages)
    return number_of_pages


def get_job_links(number_of_pages, initial_url="https://www.danempeople.fr/resultats-de-recherche.php"):
    """Scrape job links and replace the current BigQuery link list."""
    jobs = []

    for page_number in range(1, number_of_pages + 1):
        page_url = f"{initial_url}?currentPagination={page_number}"
        try:
            logger.info("Getting HTML content from %s", page_url)
            html = requests.get(page_url)
            html.raise_for_status()
        except requests.exceptions.RequestException as error:
            logger.error("HTTP request to %s failed: %s", page_url, error)
            sys.exit(2)

        soup = BeautifulSoup(html.content, "html.parser")
        for job in soup.find_all("div", class_="bl-listProductItem-container"):
            href = job.find("a", itemprop="url")
            if not href or not href.get("href"):
                continue

            jobs.append(
                {
                    "link": href.get("href"),
                    "insert_date": str(datetime.now()),
                }
            )

    logger.info("Inserting %s jobs into table list_links", len(jobs))
    bigquery_util.BigQuery().insert_rows(
        jobs,
        "dev-env-368414",
        "danem_people",
        "list_links",
        write_mode="truncate",
    )
