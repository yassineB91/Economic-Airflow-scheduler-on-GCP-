from bs4 import BeautifulSoup
import requests
import logging
from google.cloud import bigquery
import sys
import os

current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
sys.path.insert(0, parent_dir)

from gcp_utils import bigquery_util

client= bigquery.Client()
logger = logging.getLogger(__name__)


def parse_job_details(condition="title=title"):
    """
    Extracts the main details of a list of jobs
    """
    base_url ="https://www.freelance-informatique.fr/"
    rows=bigquery_util.BigQuery(client).query_table("processing-452316","freelance_info","freelance_info_link_list_merge", condition=condition)
    logger.info(f"Looping over rows of table list_links ")
    for row in rows:
        job_list=[]
        url= base_url+row.title
        logger.info(f"Scrapping the url: {url}")
        try:
            html= requests.get(url)
        except Exception as e:
            logger.error(f"Error occured during HTTP call of {url}: {e}")
            sys.exit(1)
        description,profil,sector,job="","","",""
        soup= BeautifulSoup(html.content,"html.parser")
        if soup:
            if soup.find("div",class_="mission-description"):
                try:
                    description=soup.find("div",class_="mission-description").get_text()
                except Exception as e:
                    logging.error(f"error occured during description extraction: {e}")

            if soup.find("li",title="Profil"):
                try:
                    profil=soup.find("li",title="Profil").get_text()
                except Exception as e:
                    logging.error(f"error occured during title extraction: {e}")

            if soup.find("li",title="Secteur d'activité"):
                try:
                    sector=soup.find("li",title="Secteur d'activité").get_text()
                except Exception as e:
                    logging.error(f"error occured during sector extraction: {e}")
            if soup.find("h1",class_="title"):
                try:
                    job=soup.find("h1",class_="title").get_text()
                except Exception as e:
                    logging.error(f"error occured during job extraction: {e}")
                    job=""
        
        job_dict={"job":job,"profil":profil,"sector":sector,"description":description,"skills":row.skills,"publish_date":row.publish_date,"location":row.location,"start_date":row.start_date,"duration":row.duration,"insert_date":str(row.insert_date)}
        logger.info(f"Constructing of job dict {job_dict}")
        job_list.append(job_dict)
        logger.info(f"Inserting of job details {job_dict} into job_list table")
        bigquery_util.BigQuery(client).insert_row(job_list,"processing-452316","freelance_info","job_list")
