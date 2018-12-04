#!/usr/bin/env python3
# https://opendata.lillemetropole.fr/explore/dataset/accidents-corporels-de-la-circulation-en-france/table/?sort=grav

from pyspark import *

def get_data():
    FILE = "/home/seysn/Documents/sid/accidents-corporels-de-la-circulation-en-france.csv"
    IDX_GRAVITE = 29
    IDX_LUMIERE = 1
    data = []
    with open(SparkFiles.get(FILE)) as f:
        a = f.readline().split(";") # skip first line
        # i = 0
        # for b in a:
        #     print(i, b)
        #     i += 1

        for line in f:
            t = line.split(";")
            data.append((t[IDX_LUMIERE], t[IDX_GRAVITE]))
        #print(data)
    return data

def to_list(a):
    return [a]

def append(a, b):
    a.append(b)
    return a

def extend(a, b):
    a.extend(b)
    return a

def avg(tab):
    res = {}
    for t in tab:
        average = 0
        for i in t[1]:
            average += float(i)
        average /= len(t[1])
        res[t[0]] = average
    return res

# import tpspark as s
# from importlib import reload
# reload(tpspark)

# tmp = sc.parallelize(s.get_data).combineByKey(s.to_list, s.append, s.extend).collect()
# s.avg(tmp)



# sc.parallelize(s.get_data).reduceByKeyLocally()
