from bs4 import BeautifulSoup
import requests
import logging
from datetime import datetime
from gcp_utils import bigquery_util
import sys


logging.basicConfig(level=logging.info)
logger = logging.getLogger(__name__)


def get_page_number(initial_url):
    """
    Fetches the number of pages of job listings from the initial URL.
    Args:
        initial_url (str): The URL of the job listing site.
    Returns:
        int: The number of pages to be scraped.
    Raises:
        SystemExit: If the HTTP request fails or if there is an error in parsing the HTML content.
    """

    try:
        html = requests.get(initial_url)
    except requests.exceptions.RequestException as e:
        logger.error(f"the HTTP request to the url has failed with the error: {e}")
        sys.exit(1)

    soup = BeautifulSoup(html.content, "html.parser")

    try:
        job_count_str = soup.find("div", class_="subtitle text-start mb-4").get_text(strip=True)
        number_jobs_int = int(job_count_str.replace(" missions actives", "").replace(" ", ""))
        number_of_pages = round(number_jobs_int / 50)
    except Exception as e:
        logger.error(f"Error occured during parsing of {initial_url}: {e}")
        raise

    logger.info(f"Number of pages to be scrapped is {number_of_pages}")
    return number_of_pages


def get_job_links(number_of_pages, initial_url):
    """
    Scrapes job links from multiple pages and inserts them into a BigQuery table.
    Args:
        number_of_pages (int): The number of pages to scrape.
        initial_url (str): The base URL of the job listing site.
    Raises:
        SystemExit: If an HTTP request or HTML parsing fails.
    """

    jobs = []

    for page_number in range(1, number_of_pages + 1):
        page_url = f"{initial_url}?page={page_number}"

        try:
            logger.info(f"Getting html content of: {page_url}")
            html = requests.get(page_url)
        except requests.exceptions.RequestException as e:
            logger.error(f"Error occured during HTTP call: {e}")
            sys.exit(2)

        try:
            logger.info(f"Parsing {page_url}")
            soup = BeautifulSoup(html.content, "html.parser")
            job_div = soup.find_all("div", class_="col-md-10")
        except Exception as e:
            logger.error(f"Error occured during parsing of page {page_url}: {e}")
            sys.exit(3)

        for job in job_div:
            href = job.find("a", class_="stretched-link")
            if not href:
                continue

            try:
                link = href.get("href") or ""
                job_title = href.get_text(strip=True) or link
                skills = [skill.get_text(strip=True) for skill in job.find_all("span", class_="obligatoire")]
                publish_date = (
                    job.find("i", class_="icon icon-clock").find_next_sibling(text=True).strip()
                    if job.find("i", class_="icon icon-clock")
                    else ""
                )
                location = (
                    job.find("i", class_="icon icon-map").find_next_sibling(text=True).strip()
                    if job.find("i", class_="icon icon-map")
                    else ""
                )
                start_date = (
                    job.find("i", class_="icon icon-calendar").find_next_sibling(text=True).strip()
                    if job.find("i", class_="icon icon-calendar")
                    else ""
                )
                duration = (
                    job.find("i", class_="icon icon-time").find_next_sibling(text=True).strip()
                    if job.find("i", class_="icon icon-time")
                    else ""
                )
            except Exception as e:
                logger.error(f"error occured during job details extraction: {e}")
                continue

            jobs.append(
                {
                    "job": job_title,
                    "link": link,
                    "skills": str(skills),
                    "publish_date": publish_date,
                    "location": location,
                    "start_date": start_date,
                    "duration": duration,
                    "insert_date": str(datetime.now()),
                }
            )

    logger.info(f"Inserting {len(jobs)} jobs into table list_links")
    bigquery_util.BigQuery().insert_rows(
        jobs,
        "dev-env-368414",
        "freelance_info",
        "list_links",
        write_mode="truncate",
    )
