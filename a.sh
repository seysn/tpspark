# 172.28.100.31 node-master
# 172.28.100.28 node-1
# 172.28.100.91 node-2
# 172.28.100.19 node-3

sudo apt update && sudo apt install openjdk-8-jre-headless openjdk-8-jdk-headless
echo "JAVA_HOME=\"/usr/lib/jvm/java-1.8.0-openjdk-amd64\"" | sudo tee -a /etc/environment

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

wget http://apache.crihan.fr/dist/spark/spark-2.4.0/spark-2.4.0-bin-hadoop2.7.tgz
tar xvf spark-2.4.0-bin-hadoop2.7.tgz
mv spark-2.4.0-bin-hadoop2.7 spark
