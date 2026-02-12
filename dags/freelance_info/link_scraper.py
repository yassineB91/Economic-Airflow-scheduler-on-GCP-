from bs4 import BeautifulSoup
import requests
import logging
from datetime import datetime
import sys
import os
import pandas as pd
import gcsfs
from google.cloud import storage

current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
sys.path.insert(0, parent_dir)

from gcp_utils import gcs_util



client = storage.Client()
logger =  logging.getLogger(__name__)



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
        html= requests.get(initial_url)
    except requests.exceptions.RequestException as e:
        logger.error(f"the HTTP request to the url has failed with the error: {e}")
        sys.exit(1)    
    soup= BeautifulSoup(html.content,"html.parser")
    try:
        job_count_str = soup.find('div', class_="subtitle text-start mb-4").get_text(strip=True)
        number_jobs_int =  int(job_count_str.replace(" missions actives","").replace(" ",""))
        number_of_pages= round(number_jobs_int/50)
    except Exception as e:
        logger.error(f"Error occured during parsing of {initial_url}: {e}")
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
    job_list=[]
    for page_number in range(1,number_of_pages+1):  
        page_url=f"{initial_url}?page={page_number}"
        try:
            html= requests.get(page_url)
        except Exception as e:
            logger.error(f"error occured during http call {e}")
        soup= BeautifulSoup(html.content,"html.parser")
        if soup:
            job_div=soup.find_all("div", class_="col-md-10")

        for job in job_div:
            job_info = {}
            href=job.find("a",class_="stretched-link")
            if href:
                try:
                    job_info["title"]=href.get('href') if href.get('href') else ''
                    job_info["skills"]= [skill.get_text(strip=True) for skill in job.find_all("span",class_="obligatoire")] if job.find_all("span",class_="obligatoire") else ''
                    job_info["publish_date"]=job.find("i",class_="icon icon-clock").find_next_sibling(text=True).strip() if job.find("i",class_="icon icon-clock") else ""
                    job_info["location"]=job.find("i",class_="icon icon-map").find_next_sibling(text=True).strip() if job.find("i",class_="icon icon-map") else ""
                    job_info["start_date"]=job.find("i",class_="icon icon-calendar").find_next_sibling(text=True).strip() if job.find("i",class_="icon icon-calendar") else ""
                    job_info["duration"]=job.find("i",class_="icon icon-time").find_next_sibling(text=True).strip() if job.find("i",class_="icon icon-time") else ""
                    job_info["insert_date"]=str(datetime.now())
                except Exception as e:
                    logger.error(f"error occured during job details extraction :{e}")
                job_list.append(job_info)
            else:
                continue
    file_name=pd.DataFrame(job_list)
    file_name.to_csv(f'gs://freelance_info_bucket/to_be_processed/links_{str(datetime.now().date())}.csv')
    # bigquery_util.BigQuery(client).insert_row(job_list,"processing-452316","freelance_info","list_links")


def move_processed_files(bucket_name="freelance_info_bucket",blob_name=f'to_be_processed/links_{str(datetime.now().date())}.csv',new_blob_name=f'processed/links_{str(datetime.now())}.csv'):
    gcs_util.Gcs(client).mv_blob(bucket_name,blob_name,new_blob_name)
            