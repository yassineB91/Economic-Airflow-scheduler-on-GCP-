from bs4 import BeautifulSoup
import requests
import logging
from datetime import datetime
from gcp_utils import bigquery_util
from google.cloud import bigquery
import sys


logging.basicConfig(level=logging.info)
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
        number_jobs_str= soup.find("strong",class_="font-semibold").get_text(strip=True)
        number_jobs_int =  int(number_jobs_str.replace("\u202f",""))
        number_of_pages= round(number_jobs_int/16)
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
    for page_number in range(1,number_of_pages+1):  
        page_url=f"{initial_url}{page_number}"
        try:
            logger.info(f"Getting html content of: {page_url}")
            html= requests.get(page_url)
        except requests.exceptions.RequestException as e:
            logger(f"Error occured during HTTP call: {e}")
            sys.exit(2)  
        try:
            logger.info(f"Parsing {page_url}")
            soup= BeautifulSoup(html.content,"html.parser")
            div=soup.find_all("a", class_="after:absolute after:inset-0")
        except Exception as e:
            logger.error(f"Error occured during parsing of page {page_url}: {e}")
            sys.exit(3)        
        jobs= []
        number = 0
        for element in div:
            number+=1
            logger.info(f"Getting link of job ")
            link=element.get("href")
            job_title=element.get_text(strip=True)
            job_page= {"job":job_title,"link":link,"insert_date":str(datetime.now())}
            jobs.append(job_page)

            logger.info(f"Inserting {jobs} into table list_links")
        bigquery_util.BigQuery().insert_rows(jobs,"dev-env-368414","freework","list_links",write_mode="truncate")

# def main():
#     """
#     Main function to initiate the scraping process.
#     """
#     url = "https://www.free-work.com/fr/tech-it/jobs?query="
#     number_of_pages = get_page_number(initial_url= url)
#     get_job_links(number_of_pages, initial_url= url)

# if __name__=="__main__":
#     main()