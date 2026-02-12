from bs4 import BeautifulSoup
import requests
import logging
from google.cloud import bigquery
import sys
import os
import re

current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
sys.path.insert(0, parent_dir)

from gcp_utils import bigquery_util

client= bigquery.Client()
logger = logging.getLogger(__name__)


def parse_job_details(condition="link=link",base_url="https://www.danempeople.fr"):
    """
    Extracts the main details of a list of jobs
    """

    rows=bigquery_util.BigQuery(client).query_table("processing-452316","danem_people","danem_people_link_list_merge", condition=condition)
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
        location_country, location_region ,job_type ,salary_tjm, description, description1,description2,s,f,description3,sector="","","","","","","","","","",""
        soup= BeautifulSoup(html.content,"html.parser")
        if soup:
            if soup.find("div", class_="bl-listProductItem-pays"):
                try:
                    location_country=str(soup.find("div", class_="bl-listProductItem-pays")).split("span")[2].replace(">","").replace("</div","").strip()
                except Exception as e:
                    logging.error(f"error occured during description extraction: {e}")
            
            if soup.find("div", class_="bl-listProductItem-region"):
                try:
                    location_region=str(soup.find("div", class_="bl-listProductItem-region")).split("span")[2].replace(">","").replace("</div","").strip()
                except Exception as e:
                    logging.error(f"error occured during description extraction: {e}")

            if soup.find("div", class_="bl-listProductItem-secteur"):
                try:
                    sector=str(soup.find("div", class_="bl-listProductItem-secteur")).split("span")[2].replace(">","").replace("</div","").strip()
                except Exception as e:
                    logging.error(f"error occured during description extraction: {e}")

            if soup.find("div", class_="bl-listProductItem-type_de_contrat"):
                try:
                    job_type=str(soup.find("div", class_="bl-listProductItem-type_de_contrat")).split("span")[2].replace(">","").replace("</div","").strip()
                except Exception as e:
                    logging.error(f"error occured during description extraction: {e}")

            if soup.find("div", class_="bl-listProductItem-salaire"):
                try:
                    salary_tjm=str(soup.find("div", class_="bl-listProductItem-salaire")).split("span")[2].replace(">","").replace("</div","").strip()
                except Exception as e:
                    logging.error(f"error occured during description extraction: {e}")
            
            if soup.find("div", class_="bl-productItemElement-description"):
                try:
                    for l in soup.find("div", class_="bl-productItemElement-description").find_all("li"):
                        s=str(l).replace("<li>","").replace("</li>","")
                        description2+=s

                    for l in soup.find("div", class_="bl-productItemElement-description").find_all("p"):
                        f=str(re.findall(r'>(.*?)<', str(l))).replace("'","").replace("[","").replace("]","").replace("xa0","").replace(",","".strip().replace(" ",""))
                        description3+=f
                except Exception as e:
                    logging.error(f"error occured during description extraction: {e}")

            if soup.find("div", class_="bl-productItemElement-detail-shortdescription"):
                try:
                    description1=str(soup.find("div", class_="bl-productItemElement-detail-shortdescription")).replace("</div>","").replace('<div class="bl-productItemElement-detail-shortdescription">',"").strip()
                except Exception as e:
                    logging.error(f"error occured during description extraction: {e}")

            description=description1+description2+description3
        
        job_dict={"location_country":location_country,"location_region":location_region,"sector":sector,"description":description,"job_type":job_type,"salary_tjm":salary_tjm,"link":row.link,"insert_date":str(row.insert_date)}
        logger.info(f"Constructing of job dict {job_dict}")
        job_list.append(job_dict)
        logger.info(f"Inserting of job details {job_dict} into job_list table")
        bigquery_util.BigQuery(client).insert_row(job_list,"processing-452316","danem_people","job_list")
