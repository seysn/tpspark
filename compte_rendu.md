<!-- https://gist.github.com/seysn/29ae52a98381e5e3f8d1bbba386048bd -->
<!--  https://github.com/seysn/tpspark/blob/master/tpspark.py -->
Seys Nicolas  
Malamelli Mehdi

# TP SPARK

Dans le cadre du cours de SID en M2 TIIR pour l'année 2018-2019, nous devons implémenter une architechture spark pouvant exécuter nos algorithmes. Le but est d'avoir un cluster de machines afin de pouvoir calculer ce que l'on veut.

## I) Jeu de données

Premièrement, nous devions savoir quoi calculer. Nous sommes donc allés écumer les données disponibles sur le site de la métropole Lilloise. Nous avons choisi un jeu de données recensant les [accidents dans la métropole Lilloise de 2006 à 2011](https://opendata.lillemetropole.fr/explore/dataset/accidents-corporels-de-la-circulation-en-france/table/?flg=fr&sort=-dep)  

Avec ses données, on a décidé de déterminer la gravité des accidents en fonction de l'éclairage sur le lieu.

Ce jeu de données fait uniquement 3 Mo. Plus tard pour les besoins de l'expérience, nous les avons gonflés artificiellement pour un total de 3Go.


## II) Environnement et logiciels

### 1) Choix de l'environnement

Ne disposant pas de ressources personnelles, nous avons décidé pour déployer notre cluster de déployer des VMs sur le [cloud de l'université](cloud.univ-lille.fr). Cependant il est disponible uniquement avec le VPN.

Nous avons donc déployé un total de 4 VMs. Deux sur le compte OpenStack de chacun.

Description des VMs :
* ubuntu 18.04 LTS
* 2 VCPUs
* 4 Go de RAM
* 20 Go disque dur

Nous avons choisi ubuntu car elle semblait être recommandée pour l'installation de Spark.

### 2) Choix des solutions

Sur chacune des machines, nous avons installé :
* java 8 -> Nécéssaire pour faire fonctionner Hadoop
* hadoop & hadoop file Système -> Framework pour distribuer les algortithmes. Avec son file system distribué.
* yarn -> Gestionnaire de cluster Hadoop
* Spark -> Logiciel permettant d'effectuer les calculs de map Reduce. On l'utilise plutôt qu'Hadoop Map/Reduce
* pyspark -> API, pour pouvoir écrire des algortithmes Map/Reduce qui seront exécutés par Spark.


### 3) Déploiement de la solution

Le déploiement de ces solutions est au final très laborieux. En effet il faut déjà installer un a un tous les logiciels. Puis entre chaque couche configurer le logiciel installé pour qu'il puisse être utilisé par celui qui en aura besoin (ex Spark aura besoin d'Hadoop bien installé et configuré).

Enfin il faudra configurer chaque machine pour définir son rôle, et qu'elle soit lié au cluster qu'on est en train de mettre en place.

Nous nous sommes aidé de ces tutoriaux :
* [Tuto Hadoop](https://www.linode.com/docs/databases/hadoop/how-to-install-and-set-up-hadoop-cluster/)
* [Tuto Spark](https://www.linode.com/docs/databases/hadoop/install-configure-run-spark-on-top-of-hadoop-yarn-cluster/)

#### a) Installation du cluster

Pour installer chaque machine, il fallait lancer une série de commandes. Nous avons tenté de les synthétiser à travers ce script :

```bash
# 172.28.100.31 node-master
# 172.28.100.28 node-1
# 172.28.100.91 node-2
# 172.28.100.19 node-3

# Installation de java
sudo apt update && sudo apt install openjdk-8-jre-headless openjdk-8-jdk-headless
echo "JAVA_HOME=\"/usr/lib/jvm/java-1.8.0-openjdk-amd64\"" | sudo tee -a /etc/environment

# Installation d'Hadoop et de Yarn
wget http://apache.mirrors.spacedump.net/hadoop/common/stable/hadoop-2.9.2.tar.gz
tar xvf hadoop-2.9.2.tar.gz
rm -f hadoop-2.9.2.tar.gz

export HADOOP_PREFIX="/home/ubuntu/hadoop-2.9.2"
export PATH="$HADOOP_PREFIX/bin:$HADOOP_PREFIX/sbin:$PATH"

# =================================================== CORE_SITE
cat <<EOF > $HADOOP_PREFIX/etc/hadoop/core-site.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://node-master:9000/</value>
        <description>NameNode URI</description>
        </property>
</configuration>
EOF
# =================================================== CORE_SITE

# =================================================== HDFS_SITE
cat <<EOF > $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
            <name>dfs.namenode.name.dir</name>
            <value>/home/ubuntu/data/nameNode</value>
    </property>
    <property>
            <name>dfs.datanode.data.dir</name>
            <value>/home/ubuntu/data/dataNode</value>
    </property>
    <property>
            <name>dfs.replication</name>
            <value>1</value>
    </property>
</configuration>
EOF
# =================================================== HDFS_SITE


# =================================================== MAPRED_SITE
cat <<EOF > $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
	<property>
		<name>yarn.app.mapreduce.am.resource.mb</name>
		<value>512</value>
	</property>
	<property>
		<name>mapreduce.map.memory.mb</name>
		<value>256</value>
	</property>
	<property>
		<name>mapreduce.reduce.memory.mb</name>
		<value>256</value>
	</property>
</configuration>
EOF
# =================================================== MAPRED_SITE

# =================================================== YARN_SITE
cat <<EOF > $HADOOP_PREFIX/etc/hadoop/yarn-site.xml
<?xml version="1.0"?>
<configuration>
    <property>
            <name>yarn.acl.enable</name>
            <value>0</value>
    </property>
    <property>
            <name>yarn.resourcemanager.hostname</name>
            <value>node-master</value>
    </property>
    <property>
            <name>yarn.nodemanager.aux-services</name>
            <value>mapreduce_shuffle</value>
    </property>
	<property>
		<name>yarn.nodemanager.resource.memory-mb</name>
		<value>1536</value>
	</property>
	<property>
		<name>yarn.scheduler.maximum-allocation-mb</name>
		<value>1536</value>
	</property>
	<property>
		<name>yarn.scheduler.minimum-allocation-mb</name>
		<value>128</value>
	</property>
	<property>
		<name>yarn.nodemanager.vmem-check-enabled</name>
		<value>false</value>
	</property>
</configuration>
EOF
# =================================================== YARN_SITE

# =================================================== SLAVES
cat <<EOF > $HADOOP_PREFIX/etc/hadoop/slaves
node1
node2
node3
EOF
# =================================================== SLAVES

# sudo vim /etc/hostname

sudo sh -c 'echo "172.28.100.31 node-master" >> /etc/hosts'
sudo sh -c 'echo "172.28.100.28 node1" >> /etc/hosts'
sudo sh -c 'echo "172.28.100.91 node2" >> /etc/hosts'
sudo sh -c 'echo "172.28.100.19 node3" >> /etc/hosts'


# Installation de spark
wget http://apache.crihan.fr/dist/spark/spark-2.4.0/spark-2.4.0-bin-hadoop2.7.tgz
tar xvf spark-2.4.0-bin-hadoop2.7.tgz
mv spark-2.4.0-bin-hadoop2.7 spark

```

Une fois ce script lancé sur toutes les machines, il faut uniquement pour le master lancer les commandes suivantes :
* `/home/ubuntu/hadoop-2.9.2/sbin/start-dfs.sh`
* `/home/ubuntu/hadoop-2.9.2/sbin/start-yarn.sh`

Celà démarre le file system hadoop, et Yarn.

#### b) Programme Python

Maintenant que l'on a un environnement de travail, on peut lancer un algorithme afin de le distribuer sur le cluster.  
Voici celui que l'on a mis en place :
```python
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

# Put the results on the folder output on the hdfs
res.saveAsTextFile("output")
```

#### c) Commandes pour lancer un algorithme distribué

Première étape, mettre le fichier à traiter sur le hdfs : `hdfs dfs -put <fichier> inputs`

Une fois que tout est installé, on peut lancer un algorithme grâce à spark soit en mode local (1 noeud, celui où on lance la commande), soit en mode cluster :
* Pour lancer en mode local : `spark-submit --master local  tpspark.py`  
* Pour lancer en mode cluster : `spark-submit tpspark.py` Le mode cluster est le mode par défaut.  

Si on a besoin de mettre des fichiers en input sur le cluster :
```bash
hdfs dfs -mkdir inputs   # Créé le dossier mkdir
hdfs dfs -put accidents-corporels-de-la-circulation-en-france.csv inputs #On pousse la source dans ce dossier
```

Entre chaque execution du script, ne pas oublier de supprimer le dossier output : `hdfs dfs -rm -r -f output`.

## III) Résultats

### 1) Protocoles

Afin d'avoir un comparatif quant à l'efficacité du calcul distribué, nous avons décidé de tester deux paramèttres :
* lancer sur le cluster ou en local
* faire varier la taille du fichier à traiter

Il faut tout d'abord mettre les données sur le hdfs, pour qu'elles puissent être utilisée par les différents noeud. Ensuite on lance l'algorithme et le map/reduce va se faire automatiquement. Les données seront ensuite placées dans le dossier output sur le hdfs.

Comme nous n'avions qu'un jeu de données de 3Mo, nous avons pris le CSV, et dupliqué les lignes jusqu'à avoir un fichier de 3Go. De cette façon nous avions un plus gros fichier à traiter, mais les mêmes résultats attendus, puisqu'il s'agissait d'une moyenne.

### 2) Résultats
<table>
<tr><td></td>         <td>local mode</td> <td>cluster mode</td></tr>
<tr><td>3 Mo</td>
  <td>

  ```
  real	0m9.206s
  user	0m12.254s
  sys 	0m1.466s
  ```
  </td>
  <td>

  ```
  real	0m43.027s
  user	0m19.825s
  sys	0m4.689s
  ```
  </td></tr>
<tr><td>3 Go</td>
  <td>

  ```
  real   2m0.927s
  user   0m54.504s
  sys    0m5.636s
  ```
  </td>
  <td>

  ```
  real    1m36.938s
  user    0m21.523s
  sys     0m4.627s
  ```
  </td></tr>
</table>

<!-- `0m3,275s # pc local pour le fun` -->

### 3) Interprétation

#### a) Temps de calcul

Aux premiers abords, on peut voir que le temps de calcul est beaucoup plus long, lorsqu'il s'agit de distribuer les tâches sur le cluster, que lorsqu'il faut exécuter l'algorithme en local, pour les petits jeux de données.

La raison à cela, est sûrement que l'initialisation des serveurs est la partie qui prend le plus de temps, afin qu'ils soient disposés à faire les calculs. Pour le petit jeu de données, ce coût fixe, est donc serait donc très important par rapport au temps de calcul.

Ensuite on peut imaginer que le temps de communication est assez long entre toutes les différentes machines. Il faut en effet distribuer toutes les données, et vu que le temps de calcul est assez rapide par rapport au présumé temps de communication, celà prendrait pas mal de temps.  

On peut donc conclure que pour les petits jeux de données, distribuer un algorithme n'a aucun intérêt et met beaucoup plus de temps. Et que pour des gros jeux de données, on a une économie de temps considérable (ici on va ~1.25 fois plus vite en mode cluster avec un jeu de données de 3 Go)

#### b) Résultats de l'expérience

Même si le but de l'exercice était de mettre en place la structure, il est quand même bon d'exploiter nos résultats à la fin. Voici ce que l'on obtient :

```
('Eclairage', 'Gravité de l'accident')
('Plein jour', 6.2439561306611875)
('Crépuscule ou aube', 6.760416666666656)
('Nuit sans éclairage public', 14.63612021857923)
('Nuit avec éclairage public allumé', 8.069274787535468)
('Nuit avec éclairage public non allumé', 10.308266666666672)
```

Le traitement prenait chaque luminosité et faisait une moyenne de la gravité des accidents pour chacune d'entre elle.  


On peut voir suite à ces résultats, que moins il y a de lumière, plus les accidents sont graves. Cela peut s'expliquer par le fait que les usagés ont moins d'informations. Mais on peut aussi imaginer que l'alcool soit aussi un facteur à prendre en compte.
L'ébouissement sur les routes de nuit sans éclairage serait possiblement un facteur déterminant.
