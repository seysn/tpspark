#!/usr/bin/env python3
# https://opendata.lillemetropole.fr/explore/dataset/accidents-corporels-de-la-circulation-en-france/table/?sort=grav

# hdfs dfs -mkdir inputs
# hdfs dfs -put accidents-corporels-de-la-circulation-en-france.csv inputs
# spark-submit --deploy-mode cluster tpspark.py

from pyspark import *
from itertools import islice

INPUT_FOLDER = "inputs"
FILE = "accidents-corporels-de-la-circulation-en-france.csv"
IDX_GRAVITE = 29
IDX_LUMIERE = 1

sc = SparkContext()
tf = sc.textFile(INPUT_FOLDER + '/' + FILE)

# Remove first line (header)
res = tf.mapPartitionsWithIndex(lambda idx, it: islice(it, 1, None) if idx == 0 else it)

# Modify the line so we can return a proper tuple with searched informations
def map_func(line):
    line = line.split(";")
    return (line[IDX_LUMIERE], (float(line[IDX_GRAVITE]), 1))
res = res.map(map_func)

# Reduce values per key to the tuple (sum of all values, number of values)
def reduce_func(x, y):
    return (x[0] + y[0], x[1] + y[1])
res = res.reduceByKey(reduce_func)

# Divide the sum with the number of values to get the final average
def avg(x):
    return x[0] / x[1]
res = res.mapValues(avg)

res.saveAsTextFile("output")
