FROM apache/airflow:2.10.2-python3.11

# Switch to root user for system installations
USER root

# Install necessary packages (vim, postgresql-client)
RUN apt-get update && apt-get install -y --no-install-recommends \
    vim \
    postgresql-client \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install Google Cloud SDK
# This allows the container to use gcloud commands and authenticate with GCP
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
  && apt-get update && apt-get install -y google-cloud-cli \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Set up directories and permissions
RUN mkdir -p /opt/airflow/logs \
    && chown -R airflow:root /opt/airflow \
    && chmod -R 775 /opt/airflow

# Copy dbt folder and requirements to /opt/airflow
COPY --chown=airflow:root dbt /opt/airflow/dbt
COPY --chown=airflow:root requirements.txt /opt/airflow/requirements.txt

# Copy wait-for-it.sh and entrypoint.sh to root directory and make them executable
COPY --chown=root:root wait-for-it.sh /wait-for-it.sh
RUN chmod +x /wait-for-it.sh

COPY --chown=root:root entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy DAGs to /opt/airflow/dags
COPY --chown=airflow:root dags /opt/airflow/dags

# Switch back to airflow user
USER airflow


# Install required Python packages
RUN pip install --no-cache-dir -r /opt/airflow/requirements.txt \
    && pip install --no-cache-dir psycopg2-binary \
    && pip install --no-cache-dir apache-airflow[celery] redis \
    && pip install --no-cache-dir apache-airflow-providers-google \
    && pip install --no-cache-dir google-cloud-storage

# Expose the Airflow webserver port
EXPOSE 8080

# Entry point
ENTRYPOINT ["/entrypoint.sh"]
