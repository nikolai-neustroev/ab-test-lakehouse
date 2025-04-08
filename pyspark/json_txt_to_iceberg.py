import argparse
from pyspark.sql import SparkSession
from pyspark.sql import functions as F

def main(base_path, json_bucket):
    spark = SparkSession.builder \
        .appName("JsonTxtToIcebergJob") \
        .config("spark.jars", f"{base_path}/binaries/iceberg-spark-runtime-3.5_2.12-1.8.1.jar") \
        .config("spark.sql.catalog.local", "org.apache.iceberg.spark.SparkCatalog") \
        .config("spark.sql.catalog.local.type", "hadoop") \
        .config("spark.sql.catalog.local.warehouse", f"{base_path}/spark-warehouse") \
        .getOrCreate()
    
    json_path = f"{json_bucket}/output/*.txt"
    df = spark.read.json(json_path)

    # Convert event_ts from STRING to TIMESTAMP
    df = df.withColumn("event_ts", F.to_timestamp(F.col("event_ts")))
    
    # Create a database in the "local" catalog if it doesn't already exist.
    spark.sql("CREATE DATABASE IF NOT EXISTS local_db")
    # Create an Iceberg table in the "local" catalog if it doesn't exist.
    spark.sql("""
        CREATE TABLE IF NOT EXISTS local.local_db.events (
            event_uuid       STRING,
            event_name       STRING,
            experiment_uuid  STRING,
            experiment_group STRING,
            user_uuid        STRING,
            event_ts         TIMESTAMP
        )
        USING iceberg
        PARTITIONED BY (experiment_uuid)
    """)
    
    df.writeTo("local.local_db.events").overwritePartitions()
    spark.stop()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="JsonTxtToIcebergJob")
    parser.add_argument(
        "--base_path",
        type=str,
        default="gs://test-pyspark-files",
        help="Base path for required files (jars, warehouse, etc.)"
    )
    parser.add_argument(
        "--json_bucket",
        type=str,
        default="gs://second-pyspark-files",
        help="Bucket containing .txt files with JSON records"
    )
    args = parser.parse_args()
    main(args.base_path, args.json_bucket)
