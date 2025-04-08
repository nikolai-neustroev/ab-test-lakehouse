CREATE EXTERNAL TABLE `project.dataset.events`
  OPTIONS (
         format = 'ICEBERG',
         uris = ["gs://dataproc-bucket/spark-warehouse/local_db/events/metadata/v1.metadata.json"]
   )
