from google.cloud import storage
import logging

class Gcs:
    client = storage.Client()
    def __init__(self, client):
        self.client = client
        self.logger = logging.getLogger(__name__)
    # list content of a bucket method
    def list_bucket_content(self,bucket_name):
        try:
            blobs = self.client.list_blobs(bucket_name)
        except Exception as e:
            self.logger.error(f"Error occured during blobs retrieval from {bucket_name}: {e}")
        return blobs
    # Delete a file in a bucket method
    def delete_bucket_object(self, bucket_name,object_name):
        bucket = self.client.bucket(bucket_name)
        try:
            bucket.delete_blob(object_name)
        except Exception as e:
            self.logger.error(f"Error occured during object {object_name} deletion from {bucket_name}: {e} ")
            
    def mv_blob(self,bucket_name,blob_name,new_blob_name):
        bucket = self.client.bucket(bucket_name)
        blob = bucket.blob(blob_name)
        
        if blob.exists():
            try:
                new_blob = bucket.rename_blob(blob,new_blob_name)
                self.logger.info(f"successefully moved  {blob_name} to {new_blob_name} ")
            except Exception as e:
                self.logger.error(f"Error occurred during renaming object {blob_name} to {new_blob_name}: {e}")
                raise
           
        else:
            self.logger.info("No file to be moved")


