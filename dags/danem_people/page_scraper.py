from bs4 import BeautifulSoup
from datetime import timezone
import datetime
import json
import logging
import re
import requests
import sys

from gcp_utils import bigquery_util, gcs_util


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


REQUEST_TIMEOUT_SECONDS = 30


def _normalize_text(value):
    if not value:
        return ""
    return " ".join(str(value).split())


def _first_non_empty(*values):
    for value in values:
        normalized_value = _normalize_text(value)
        if normalized_value and normalized_value != "/":
            return normalized_value
    return ""


def _get_text_from_div(container, class_name):
    if not container:
        return ""

    element = container.find("div", class_=class_name)
    return _normalize_text(element.get_text(" ", strip=True)) if element else ""


def _html_to_text(html_fragment):
    if not html_fragment:
        return ""
    return _normalize_text(BeautifulSoup(html_fragment, "html.parser").get_text(" ", strip=True))


def _extract_product_data(page_html):
    match = re.search(
        r"initDetailProduct\(\s*'[^']+'\s*,\s*(\{.*?\})\s*,\s*defaultParams\);",
        page_html,
        re.DOTALL,
    )
    if not match:
        return {}

    try:
        return json.loads(match.group(1))
    except json.JSONDecodeError as error:
        logger.warning("Unable to parse product payload from Danem People detail page: %s", error)
        return {}


def _extract_feature_values(soup, product_data):
    feature_values = {}

    product_features = product_data.get("arrayFeature") or {}
    for feature_key, feature in product_features.items():
        feature_values[feature_key] = _normalize_text(feature.get("value"))

    for row in soup.select(".bl-productItemElement--features tr"):
        classes = row.get("class", [])
        key = classes[0] if classes else ""
        cells = row.find_all("td")
        if key and len(cells) >= 2:
            cell_value = _normalize_text(cells[1].get_text(" ", strip=True))
            if not feature_values.get(key):
                feature_values[key] = cell_value

    return feature_values


def _extract_description(soup, product_data):
    short_description = _first_non_empty(
        product_data.get("description"),
        _get_text_from_div(soup, "bl-productItemElement-detail-shortdescription"),
    )
    long_description = _first_non_empty(
        _html_to_text(product_data.get("longDescription")),
        _html_to_text(
            str(soup.find("div", class_="bl-productItemElement-description-longDescription") or "")
        ),
    )

    return _normalize_text(" ".join(part for part in [short_description, long_description] if part))


def _extract_sector(soup, feature_values):
    return _first_non_empty(
        _get_text_from_div(soup, "bl-listProductItem-secteur"),
        feature_values.get("metiers_it_digital"),
        feature_values.get("metiers_ingenierie"),
        feature_values.get("secteur_activite"),
    )


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
            response = requests.get(url, timeout=REQUEST_TIMEOUT_SECONDS)
            response.raise_for_status()
        except requests.exceptions.RequestException as error:
            logger.error("HTTP request to %s failed: %s", url, error)
            sys.exit(1)

        soup = BeautifulSoup(response.content, "html.parser")
        product_data = _extract_product_data(response.text)
        feature_values = _extract_feature_values(soup, product_data)
        description = _extract_description(soup, product_data)

        jobs.append(
            {
                "location_country": _first_non_empty(
                    _get_text_from_div(soup, "bl-listProductItem-pays"),
                    feature_values.get("pays"),
                ),
                "location_region": _first_non_empty(
                    _get_text_from_div(soup, "bl-listProductItem-region"),
                    feature_values.get("region"),
                ),
                "sector": _extract_sector(soup, feature_values),
                "description": description,
                "job_type": _first_non_empty(
                    _get_text_from_div(soup, "bl-listProductItem-type_de_contrat"),
                    feature_values.get("type_de_contrat"),
                ),
                "salary_tjm": _first_non_empty(
                    _get_text_from_div(soup, "bl-listProductItem-salaire"),
                    feature_values.get("salaire_annuel"),
                ),
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
