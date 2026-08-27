from bs4 import BeautifulSoup
import requests
import logging
from gcp_utils import bigquery_util
from gcp_utils import gcs_util
from google.cloud import bigquery
import sys
import json
import datetime
from datetime import timezone

client= bigquery.Client()
logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.info)

def parse_job_details(condition="link=link"):
    """
    Extracts the main details of a list of jobs
    """
    base_url = "https://www.free-work.com"
    rows=bigquery_util.BigQuery().query_table("processing-452316","freework","list_links", condition=condition)
    logger.info(f"Looping over rows of table list_links ")
    for row in rows:
        job_list=[]
        url= base_url+row.link
        logger.info(f"Scrapping the url: {url}")
        try:
            html= requests.get(url)
        except Exception as e:
            logger.error(f"Error occured during HTTP call of {url}: {e}")
            sys.exit(1)
        duration,salary_tjm,remote,experience,start="","","","",""
        soup= BeautifulSoup(html.content,"html.parser")
        try:
            if soup:
                spans= soup.find_all("span",class_="w-full text-sm line-clamp-2")
                for span in spans:
                    element= span.get_text(strip=True)
                    if ("jours" in element or "mois" in element or "an" in element or "ans" in element) and "expérience" not in element and "," not in element and "€" not in element:
                        duration=element
                        logger.info(f"duration: {duration}")
                    elif "€" in element:
                        salary_tjm = element.replace("\xa0€⁄"," €/")
                        logger.info(f"salary_tjm: {salary_tjm}")
                    elif "Télétravail" in element:
                        remote = element
                        logger.info(f"remote: {remote}")
                    elif "expérience" in element:
                        experience = element
                        logger.info(f"experience: {experience}")
                    elif "que possible" in element or "/2024" in element:
                        start= element
                        logger.info(f"start: {start}")
        except Exception as e:
            logger.error(f"Error occured during the extraction of duration, salary, experience & Start date {url}: {e} ")
            sys.exit(2)
        description,location,title,key_skills="","","",""
        try:
            skills= soup.find_all('div', class_='truncate py-[2px]')
            key_skills = [x.get_text(strip=True) for x in skills if x]
            if soup.find("span",class_="hidden md:block"):
                title= soup.find("span",class_="hidden md:block").get_text(strip=True)
            logger.info(f"title: {title}")
            if spans[len(spans)-1]:
                location = spans[len(spans)-1].get_text(strip=True)
            logger.info(f"location: {location}")     
        except Exception as e:
            logger.error(f"Error occured during the extraction of job location & title {url}: {e}")    
        
        try:
            description_div = soup.find("div", class_="html-renderer prose-content")
            if description_div:
                description = " ".join([p.get_text(strip=True) for p in description_div.find_all("p")])
            else:
                description = ""
        except Exception as e:
            logger.error(f"Error occured during {e}")
            sys.exit(3)

        insert_date= str(row.insert_date)
        
        job={'title':title,'start':start,'duration':duration,'salary_tjm':salary_tjm,'experience':experience,'remote':remote,'location':location,'description':description,"key_skills":str(key_skills),"insert_date":insert_date}
        logger.info(f"Constructing of job dict {job}")
        job_list.append(job)

    file_name = f"/tmp/freework_jobs_{datetime.now(timezone.utc):%Y%m%dT%H%M%SZ}.jsonl"

    with open(file_name, "w", encoding="utf-8") as file:
        for job in job_list:
            file.write(json.dumps(job, ensure_ascii=False) + "\n")

    logger.info(f"Inserting of job details {job} into job_list bucket")
    gcs_util.Gcs().upload_file(
    bucket_name="freework_jobs",
    local_file_path=file_name,
    destination_blob_name=f"freework/jobs/{file_name.split('/')[-1]}",
    content_type="application/x-ndjson",
)

    