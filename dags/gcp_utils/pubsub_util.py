from google.cloud import pubsub_v1
import logging

class PubSub:
    publisher = pubsub_v1.PublisherClient()
    def __init__(self,publisher):
        self.publisher = publisher
        self.logger = logging.getLogger(__name__)
    def publish_payload(self,project_id,topic_id, payload):
        topic_path = self.publisher.topic_path(project_id,topic_id)
        try:
            self.publisher.publish(topic_path,payload)
        except Exception as e:
            self.logger.error(f"Error eccured during the publishing of {payload} in topic {topic_id} : {e}")
