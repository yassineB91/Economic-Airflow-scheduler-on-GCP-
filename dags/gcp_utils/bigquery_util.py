from google.cloud import bigquery
from retrying import retry
import logging
import pandas as pd

class BigQuery:


    def __init__(self):     
        self.client= bigquery.Client()
        self.logger = logging.getLogger(__name__)

########################### Truncate table method ##############################################################
    def truncate(self,project,dataset,table):
        table_id=f'{project}.{dataset}.{table}'
        QUERY = (
            f'TRUNCATE TABLE {table_id}'
        )
        try:
            self.client.query(QUERY).result()
            self.logger.info(f'Truncated table {table_id}')
        except Exception :
            self.logger.exception(f"Failed to truncate {table_id}")
            raise


########################### Delete table method  #################################################################
    def delete(self,project,dataset,table):
        table_id=f'{project}.{dataset}.{table}'
        try:
            self.client.delete_table(table_id)
            self.logger.info(f'Deleted table {table_id}')
        except Exception:
            self.logger.exception(f"Failed to delete table {table_id}")
            raise
    
########################### Get table schema  method #####################################################
    def get_table_schema(self,project,dataset, table):
        table_id=f'{project}.{dataset}.{table}'
        try:
            return list(self.client.get_table(table_id).schema)
        except Exception :
            self.logger.exception(f"Failed to retrieve schema for {table_id} ")
            raise


    
########################### Load csv file from gcs into BigQuery table method #############################
    def load_file(self, project, dataset, table, gcs_uri, file_type,write_mode):
        table_id=f'{project}.{dataset}.{table}'
        schema= self.get_table_schema(project,dataset, table)

        source_formats = {
            "csv" : bigquery.SourceFormat.CSV,
            "json": bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
            "parquet": bigquery.SourceFormat.PARQUET,
        }

        write_dispositions = {
            "append": bigquery.WriteDisposition.WRITE_APPEND,
            "truncate": bigquery.WriteDisposition.WRITE_TRUNCATE,
            "empty": bigquery.WriteDisposition.WRITE_EMPTY,
        }

        try:
            source_format = source_formats[file_type.lower()]
        except KeyError:
            raise ValueError(
                f"Unsupported file type: {file_type}"
            ) from None

        try:
            write_disposition = write_dispositions[write_mode.lower()]
        except KeyError:
            raise ValueError(
                f"Unsupported write mode: {write_mode}"
            ) from None
        
        job_config = bigquery.LoadJobConfig(
            source_format = source_format,
            write_disposition = write_disposition,
        )

        try:
            load_job =self.client.load_table_from_uri(gcs_uri,table_id,job_config=job_config,)
            load_job.result()

            self.logger.info(
                "Loaded %s rows from %s into %s",
                load_job.output_rows,
                gcs_uri,
                table_id,
            )
            return load_job.output_rows
        except Exception:
            self.logger.exception(
                "Failed to load %s into %s",
                gcs_uri,
                table_id,
            )
            raise


####################### Insert rows method# #####################################################
    def insert_rows(self,input_list,project,dataset,table,write_mode="append",):
        table_id = f"{project}.{dataset}.{table}"

        if not input_list:
            return

        write_dispositions = {
            "append": bigquery.WriteDisposition.WRITE_APPEND,
            "truncate": bigquery.WriteDisposition.WRITE_TRUNCATE,
            "empty": bigquery.WriteDisposition.WRITE_EMPTY,
        }

        if write_mode not in write_dispositions:
            raise ValueError(
                f"Unsupported write mode: {write_mode}. "
                "Use 'append', 'truncate' or 'empty'."
            )

        job_config = bigquery.LoadJobConfig(
            write_disposition=write_dispositions[write_mode]
        )

        try:
            load_job = self.client.load_table_from_json(
                input_list,
                table_id,
                job_config=job_config,
            )

            load_job.result()

            self.logger.info(
                "%d rows inserted into %s using %s",
                len(input_list),
                table_id,
                write_mode,
            )

        except Exception:
            self.logger.exception(
                "Error inserting rows into %s",
                table_id,
            )
            raise

#################### read rows of a table ####################################################
    def query_table(self,project, dataset, table, condition='link=link'):
        table_id=f'{project}.{dataset}.{table}'
        QUERY = f"SELECT * FROM {table_id} WHERE {condition}"
        try:
            query_job= self.client.query(QUERY)
            rows= query_job.result()
            return rows
        except Exception as e:
            self.logger.error(f"error occured during during {table} reading: {e}")
            raise
            
    def table_to_dataframe(self,project, dataset, table, condition='link=link'):
        table_id=f'{project}.{dataset}.{table}'
        QUERY = f"SELECT * FROM {table_id} WHERE {condition}"
        try:
            df= self.client.query(QUERY).to_dataframe()
            return df
        except Exception as e:
            self.logger.error(f"error occured during during {table} reading: {e}")



