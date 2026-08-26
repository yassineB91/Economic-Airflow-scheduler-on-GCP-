from google.cloud import storage
from google.api_core.exceptions import NotFound
import logging

class Gcs:

    def __init__(self):
        self.client = storage.Client()
        self.logger = logging.getLogger(__name__)

################## list content of a bucket  ###############################################
    def list_bucket_content(self,bucket_name):
        try:
            return(self.client.list_blobs(bucket_name))
        except Exception:
            self.logger.exception(f"Error occured during blobs retrieval from {bucket_name}")
            raise
    
################## Delete a file in a bucket ###############################################
    def delete_bucket_object(self, bucket_name,object_name):
        bucket = self.client.bucket(bucket_name)
        self.logger.info(f'{object_name} is deleted from bucket {bucket_name}')
        try:
            bucket.delete_blob(object_name)
        except NotFound:
            self.logger.warning(
                "Object %s does not exist in bucket %s",
                object_name,
                bucket_name,
            )
        except Exception:
            self.logger.exception(f"Error occured during object {object_name} deletion from {bucket_name}")
            raise

#################  Rename bucket object ####################################################
    def mv_blob(self,bucket_name,blob_name,new_blob_name):
        bucket = self.client.bucket(bucket_name)
        blob = bucket.blob(blob_name)
        
        try:
            if not blob.exists():
                self.logger.warning(
                    "Object %s does not exist in bucket %s",
                    blob_name,
                    bucket_name,
                )
                return

            bucket.rename_blob(blob, new_blob_name)

            self.logger.info(
                "Object %s moved to %s",
                blob_name,
                new_blob_name,
            )

        except Exception:
            self.logger.exception(
                "Error while moving object %s to %s",
                blob_name,
                new_blob_name,
            )
            raise


