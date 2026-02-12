from google.cloud import bigquery
from retrying import retry
import logging
import pandas as pd

class BigQuery:
    # initialize BigQuery client
    client= bigquery.Client()

    def __init__(self,client):     
        self.client= client
        self.logger = logging.getLogger(__name__)

    # Truncate table method
    def truncate(self,project,dataset,table):
        QUERY = (
            f'TRUNCATE TABLE {project}.{dataset}.{table}'
        )
        try:
            self.client.query(QUERY)
        except Exception as e:
            self.logger.error(f"error occured during during {table} truncate: {e}")

    # Insert into table method
    @retry(stop_max_attempt_number=5, wait_fixed=2000)
    def insert_row(self,input_dict,project, dataset, table):
        table_id=f'{project}.{dataset}.{table}'
        try:
            errors = self.client.insert_rows_json(table_id, input_dict)
            if errors:
                self.logger.error(f"Encountered errors while inserting rows: {errors}")
            else:
                self.logger.info(f"Successfully inserted rows into {table_id}")
        except Exception as e:
            self.logger.error(f"Error occurred during row {input_dict} insertion in {table}: {e}")
            exit(1)

    # Delete table method
    def delete(self,project,dataset,table):
        table_id=f'{project}.{dataset}.{table}'
        try:
            self.client.delete_table(table_id)
        except Exception as e:
            self.logger.error(f"Error occured during table {table} delete: {e}")
    
    # Determine table schema list method
    def get_table_schema(self,project,dataset, table):
        schema_list=[]
        table_id=f'{project}.{dataset}.{table}'
        try:
            table_meta=self.client.get_table(table_id)
        except Exception as e:
            self.logger.error(f"Error occured during table {table} metadata retrieval: {e}")

        for field in table_meta.schema:
            schema_list.append(self.client.SchemaField(name=field.name,field_type=field.field_type, mode=field.mode))
        return schema_list
    # Load csv file from gcs into BigQuery table method
    def load_file(self, project, dataset, table, gcs_uri, file_type,write_mode):
        table_id=f'{project}.{dataset}.{table}'
        schema= self.get_table_schema(project,dataset, table)
        job_config=self.client.LoadJobConfig()
        job_config.schema=schema
        if file_type=="csv":
            job_config.source_format=self.client.SourceFormat.csv
        elif file_type=="json":
            job_config.source_format=self.client.SourceFormat.NEWLINE_DELIMITED_JSON
        else:
            self.logger.error(f"File format {format} not supported")
        if write_mode=="append":
            job_config.write_disposition=self.client.WriteDisposition.WRITE_APPEND
        elif write_mode=="truncate":
            job_config.write_disposition=self.client.WriteDisposition.WRITE_TRUNCATE
        else:
            self.logger.error(f"mode {write_mode} not supported")
        job_config.null_marker= ''
        loadjob=self.client.load_table_from_uri(gcs_uri,table_id,job_config=job_config)
        try:
            loadjob.result()
        except Exception as e:
            self.logger.error("Error occured during file {gcs_uri} loading in {table}: {e}")
    # read rows of a table
    def query_table(self,project, dataset, table, condition='link=link'):
        table_id=f'{project}.{dataset}.{table}'
        QUERY = f"SELECT * FROM {table_id} WHERE {condition}"
        try:
            query_job= self.client.query(QUERY)
            rows= query_job.result()
            return rows
        except Exception as e:
            self.logger.error(f"error occured during during {table} reading: {e}")
            
    def table_to_dataframe(self,project, dataset, table, condition='link=link'):
        table_id=f'{project}.{dataset}.{table}'
        QUERY = f"SELECT * FROM {table_id} WHERE {condition}"
        try:
            df= self.client.query(QUERY).to_dataframe()
            return df
        except Exception as e:
            self.logger.error(f"error occured during during {table} reading: {e}")



