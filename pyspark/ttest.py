import argparse
import math
from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from google.auth import default


def simpson(f, a, b, n=10000):
    """Approximate the integral of f from a to b using Simpson's rule with n subintervals."""
    if n % 2 == 1:
        n += 1
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        factor = 4 if i % 2 == 1 else 2
        s += factor * f(a + i * h)
    return s * h / 3


def t_pdf(x, nu):
    """t-distribution PDF using math.lgamma for numerical stability."""
    log_num = math.lgamma((nu + 1) / 2)
    log_den = 0.5 * math.log(nu * math.pi) + math.lgamma(nu / 2)
    coef = math.exp(log_num - log_den)
    return coef * (1 + (x * x) / nu) ** (-(nu + 1) / 2)


def t_cdf(x, nu):
    """Cumulative distribution function (CDF) for the t-distribution."""
    if x < 0:
        return 1 - t_cdf(-x, nu)
    return 0.5 + simpson(lambda u: t_pdf(u, nu), 0, x)


def two_tailed_p_value(t_stat, nu):
    """Compute the two-tailed p-value from t_stat and degrees of freedom."""
    c = t_cdf(abs(t_stat), nu)
    return 2 * (1 - c)


def compute_ratio(df, cr, group):
    """
    Computes the ratio for a given group.
    cr is a tuple/list where:
      cr[0] -> denominator column expression
      cr[1] -> numerator column expression
    """
    filtered = df.filter(F.col("experiment_group") == group)
    result = filtered.agg(
        F.sum(cr[1]).alias("num"),
        F.sum(cr[0]).alias("den")
    ).collect()[0]
    num, den = result["num"], result["den"]
    return num / den if den else None


def compute_welch_test(df, metric_col):
    """
    Computes Welch's t-test for the provided metric column.
    Returns a tuple (n1, n2, p_value) or None if one of the groups is missing.
    """
    df_filtered = df.filter(F.col(metric_col).isNotNull())
    agg = df_filtered.groupBy("experiment_group").agg(
        F.count(metric_col).alias("n"),
        F.avg(metric_col).alias("mean"),
        F.var_samp(metric_col).alias("var")
    ).collect()
    
    stats = {row["experiment_group"]: row for row in agg}
    if "A" not in stats or "B" not in stats:
        return None

    n1 = stats["A"]["n"]
    n2 = stats["B"]["n"]
    mean1 = stats["A"]["mean"]
    mean2 = stats["B"]["mean"]
    var1 = stats["A"]["var"]
    var2 = stats["B"]["var"]

    se = math.sqrt(var1 / n1 + var2 / n2)
    t_stat = (mean1 - mean2) / se
    # Welch–Satterthwaite degrees of freedom
    numerator = (var1 / n1 + var2 / n2) ** 2
    denominator = ((var1 / n1) ** 2 / (n1 - 1)) + ((var2 / n2) ** 2 / (n2 - 1))
    df_val = numerator / denominator
    p_val = two_tailed_p_value(t_stat, df_val)
    return n1, n2, p_val


def get_gcp_project_id():
    _, project_id = default()
    return project_id


def main(base_path):
    project_id = get_gcp_project_id()
    spark = SparkSession.builder \
        .appName("TTest") \
        .config("spark.jars", f"{base_path}/binaries/iceberg-spark-runtime-3.5_2.12-1.8.1.jar") \
        .config("spark.sql.catalog.local", "org.apache.iceberg.spark.SparkCatalog") \
        .config("spark.sql.catalog.local.type", "hadoop") \
        .config("spark.sql.catalog.local.warehouse", f"{base_path}/spark-warehouse") \
        .config("spark.sql.catalog.bigquery", "com.google.cloud.spark.bigquery.v2.BigQueryCatalog") \
        .config("spark.sql.catalog.bigquery.project", project_id) \
        .config("spark.sql.catalog.bigquery.dataset", "dataset") \
        .getOrCreate()
    
    df = spark.table("local.local_db.events")

    df = df.withColumn("event_ts", F.from_unixtime(F.col("event_ts").cast("bigint") / 1000))
    stats_df = df.groupBy('event_name', 'experiment_uuid', 'experiment_group', 'user_uuid').agg(
        F.countDistinct("event_uuid").alias("event_uuid_count"),
        )\
        .groupBy('experiment_uuid', 'experiment_group', 'user_uuid')\
        .pivot("event_name", [
            'homepage_viewed',
            'product_viewed',
            'product_added_to_cart',
            'order_placed',
            'review_written'
        ])\
        .sum("event_uuid_count")
    
    cr_list = [
        ['homepage_viewed', 'product_viewed', 'hv2pv'],
        ['product_viewed', 'product_added_to_cart', 'pv2pa'],
        ['product_added_to_cart', 'order_placed', 'pa2op'],
        ['order_placed', 'review_written', 'op2rw'],
    ]

    for cr in cr_list:
        kappa_df = stats_df.filter(F.col('experiment_group') == 'A')
        
        agg_results = kappa_df.agg(
            F.sum(cr[1]).alias("num"),
            F.sum(cr[0]).alias("den")
        ).collect()[0]
        
        num = agg_results["num"]
        den = agg_results["den"]
        kappa = num / den if den else None
    
        stats_df = stats_df.withColumn(
            f"{cr[2]}_lin",
            F.when(
                F.col(cr[0]).isNull() & F.col(cr[1]).isNull(), 
                None
            ).when(
                F.col(cr[1]).isNull(), 
                F.lit(0)
            ).otherwise(
                F.col(cr[1]) - F.lit(kappa) * F.col(cr[0])
            )
        )
    
    results_list = []

    experiment_uuids = [row["experiment_uuid"] for row in stats_df.select("experiment_uuid").distinct().collect()]

    for experiment_uuid in experiment_uuids:
        df_experiment = stats_df.filter(F.col("experiment_uuid") == experiment_uuid)
        
        for cr in cr_list:
            metric_name = cr[2]
            
            val_a = compute_ratio(df_experiment, cr, "A")
            val_b = compute_ratio(df_experiment, cr, "B")
            
            welch_results = compute_welch_test(df_experiment, f"{metric_name}_lin")
            if welch_results is None:
                print(f"Not enough groups for metric {metric_name} in experiment {experiment_uuid}.")
                continue
            
            n1, n2, p_val = welch_results
    
            results_list.append({
                "experiment_uuid": experiment_uuid,
                "metric_name": metric_name,
                "val_a": val_a,
                "val_b": val_b,
                "n_1": n1,
                "n_2": n2,
                "p_value": p_val
            })
    
    results_df = spark.createDataFrame(results_list)

    results_df.write \
        .format("bigquery") \
        .option("table", f"{project_id}.dataset.ab_table") \
        .option("temporaryGcsBucket", f"{base_path}/bq_temp") \
        .mode("overwrite") \
        .save()
    
    spark.stop()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="CsvToIcebergJob")
    parser.add_argument(
        "--base_path",
        type=str,
        default="gs://test-pyspark-files",
        help="Base path for the pyspark files (jars, warehouse, csvs, etc.)"
    )
    args = parser.parse_args()
    main(args.base_path)
