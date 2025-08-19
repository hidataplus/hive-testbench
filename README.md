hive-testbench
==============

A testbench for experimenting with Apache Hive at any data scale.

Overview
========

The hive-testbench is a data generator and set of queries that lets you experiment with Apache Hive at scale. The testbench allows you to experience base Hive performance on large datasets, and gives an easy way to see the impact of Hive tuning parameters and advanced settings.

Prerequisites
=============

You will need:
* Hadoop 2.2 or later cluster or Sandbox.
* Apache Hive.
* Between 15 minutes and 2 days to generate data (depending on the Scale Factor you choose and available hardware).
* If you plan to generate 1TB or more of data, using Apache Hive 13+ to generate the data is STRONGLY suggested.

Install and Setup
=================

All of these steps should be carried out on your Hadoop cluster.

- Step 1: Prepare your environment.

  In addition to Hadoop and Hive, before you begin ensure ```gcc``` is installed and available on your system path. If you system does not have it, install it using yum or apt-get.

- Step 2: Decide which test suite(s) you want to use.

  hive-testbench comes with data generators and sample queries based on both the TPC-DS and TPC-H benchmarks. You can choose to use either or both of these benchmarks for experiementation. More information about these benchmarks can be found at the Transaction Processing Council homepage.

- Step 3: Compile and package the appropriate data generator.

  For TPC-DS, ```./tpcds-build.sh``` downloads, compiles and packages the TPC-DS data generator.
  For TPC-H, ```./tpch-build.sh``` downloads, compiles and packages the TPC-H data generator.

- Step 4: Decide how much data you want to generate.

  You need to decide on a "Scale Factor" which represents how much data you will generate. Scale Factor roughly translates to gigabytes, so a Scale Factor of 100 is about 100 gigabytes and one terabyte is Scale Factor 1000. Decide how much data you want and keep it in mind for the next step. If you have a cluster of 4-10 nodes or just want to experiment at a smaller scale, scale 1000 (1 TB) of data is a good starting point. If you have a large cluster, you may want to choose Scale 10000 (10 TB) or more. The notion of scale factor is similar between TPC-DS and TPC-H.

  If you want to generate a large amount of data, you should use Hive 13 or later. Hive 13 introduced an optimization that allows far more scalable data partitioning. Hive 12 and lower will likely crash if you generate more than a few hundred GB of data and tuning around the problem is difficult. You can generate text or RCFile data in Hive 13 and use it in multiple versions of Hive.

- Step 5: Generate and load the data.

  The scripts ```tpcds-setup.sh``` and ```tpch-setup.sh``` generate and load data for TPC-DS and TPC-H, respectively. General usage is ```tpcds-setup.sh scale_factor [directory]``` or ```tpch-setup.sh scale_factor [directory]```

  Some examples:

  Build 1 TB of TPC-DS data: ```./tpcds-setup.sh 1000```

  Build 1 TB of TPC-H data: ```./tpch-setup.sh 1000```

  Build 100 TB of TPC-DS data: ```./tpcds-setup.sh 100000```

  Build 30 TB of text formatted TPC-DS data: ```FORMAT=textfile ./tpcds-setup 30000```

  Build 30 TB of RCFile formatted TPC-DS data: ```FORMAT=rcfile ./tpcds-setup 30000```
  
  Also check other parameters in setup scripts important one is BUCKET_DATA.

- Step 6: Run queries.

  More than 50 sample TPC-DS queries and all TPC-H queries are included for you to try. You can use ```hive```, ```beeline``` or the SQL tool of your choice. The testbench also includes a set of suggested settings.

  This example assumes you have generated 1 TB of TPC-DS data during Step 5:

  	```
  	cd sample-queries-tpcds
  	hive -i testbench.settings
  	hive> use tpcds_bin_partitioned_orc_1000;
  	hive> source query55.sql;
  	```

  Note that the database is named based on the Data Scale chosen in step 3. At Data Scale 10000, your database will be named tpcds_bin_partitioned_orc_10000. At Data Scale 1000 it would be named tpch_flat_orc_1000. You can always ```show databases``` to get a list of available databases.

  Similarly, if you generated 1 TB of TPC-H data during Step 5:

  	```
  	cd sample-queries-tpch
  	hive -i testbench.settings
  	hive> use tpch_flat_orc_1000;
  	hive> source tpch_query1.sql;
  	```

Feedback
========

If you have questions, comments or problems, visit the [Hortonworks Hive forum](http://hortonworks.com/community/forums/forum/hive/).

If you have improvements, pull requests are accepted.


TPC-DS步骤
========

本说明基于的环境说明：
1. 安装hiveserver2、kyuubiserver、mrsserver。(因为脚本里使用的是localhost，如果部署在一个机器上，需要自己更改相关脚本)
2. 使用Hive用户，避免出现一些权限问题。

- Step 1: 准备操作系统环境

```
yum -y install gcc gcc-c++ git
```

- Step 2: 配置maven

```
su - hive

wget https://mirrors.aliyun.com/apache/maven/maven-3/3.9.11/binaries/apache-maven-3.9.11-bin.tar.gz

tar zxvf apache-maven-3.9.11-bin.tar.gz

export MAVEN_HOME=/home/hive/apache-maven-3.9.11
export PATH=${MAVEN_HOME}/bin:$PATH


vi $MAVEN_HOME/conf/settings.xml
<mirror>
    <id>aliyun</id>
    <mirrorOf>central</mirrorOf>
    <name>Nexus aliyun</name>
    <url>http://maven.aliyun.com/nexus/content/groups/public</url>
</mirror>

mkdir -p ~/.m2/

cp $MAVEN_HOME/conf/settings.xml ~/.m2/
```	
	

- Step 3: 下载
```
su - hive

git clone https://github.com/hidataplus/hive-testbench
```

- Step 4: 编译
```
cd hive-testbench

./tpcds-build.sh
```

中间有个输入，输入Y

- Step 5: 生成数据

1) 声明数据规模变量

```
SF=10
```
SF就是数据规模，数字为几就代表几G
 

2) 检查Hive数据库是否存在。
```

hive -e "desc database tpcds_bin_partitioned_orc_$SF"
```

开始库是不存在的，如果想重新来过，可以清理已经存在的Hive数据库。
```
hive -e "drop database tpcds_bin_partitioned_orc_$SF cascade"
```
 
- Step 5: 生成并加载数据
```
./tpcds-setup.sh $SF
```
 
 中间可能会因为内存不足、脚本参数错误等中止，需要手工执行对应的sql，sql在
 
 tez container 至少1024M

#参考日志
 ```
[hive@datanode01 hive-testbench]$ ./tpcds-setup.sh $SF
ls: '/tmp/tpcds-generate/2': No such file or directory
Generating data at scale factor 2.
25/08/04 06:49:13 INFO client.DefaultNoHARMFailoverProxyProvider: Connecting to ResourceManager at datanode01/192.168.2.1:8050
25/08/04 06:49:13 INFO client.AHSProxy: Connecting to Application History server at datanode01/192.168.2.1:10200
25/08/04 06:49:13 INFO mapreduce.JobResourceUploader: Disabling Erasure Coding for path: /user/hive/.staging/job_1754288359263_0002
25/08/04 06:49:13 INFO input.FileInputFormat: Total input files to process : 1
25/08/04 06:49:13 INFO mapreduce.JobSubmitter: number of splits:2
25/08/04 06:49:14 INFO mapreduce.JobSubmitter: Submitting tokens for job: job_1754288359263_0002
25/08/04 06:49:14 INFO mapreduce.JobSubmitter: Executing with tokens: []
25/08/04 06:49:14 INFO conf.Configuration: found resource resource-types.xml at file:/etc/hadoop/3.3.2.0-011/0/resource-types.xml
25/08/04 06:49:14 INFO impl.YarnClientImpl: Submitted application application_1754288359263_0002
25/08/04 06:49:14 INFO mapreduce.Job: The url to track the job: http://datanode01:8088/proxy/application_1754288359263_0002/
25/08/04 06:49:14 INFO mapreduce.Job: Running job: job_1754288359263_0002
25/08/04 06:49:19 INFO mapreduce.Job: Job job_1754288359263_0002 running in uber mode : false
25/08/04 06:49:19 INFO mapreduce.Job:  map 0% reduce 0%
25/08/04 06:49:38 INFO mapreduce.Job:  map 50% reduce 0%
25/08/04 06:51:02 INFO mapreduce.Job:  map 100% reduce 0%
25/08/04 06:51:02 INFO mapreduce.Job: Job job_1754288359263_0002 completed successfully
25/08/04 06:51:02 INFO mapreduce.Job: Counters: 33
        File System Counters
                FILE: Number of bytes read=0
                FILE: Number of bytes written=586468
                FILE: Number of read operations=0
                FILE: Number of large read operations=0
                FILE: Number of write operations=0
                HDFS: Number of bytes read=391
                HDFS: Number of bytes written=2281110714
                HDFS: Number of read operations=93
                HDFS: Number of large read operations=0
                HDFS: Number of write operations=79
                HDFS: Number of bytes read erasure-coded=0
        Job Counters 
                Launched map tasks=2
                Other local map tasks=2
                Total time spent by all maps in occupied slots (ms)=234448
                Total time spent by all reduces in occupied slots (ms)=0
                Total time spent by all map tasks (ms)=117224
                Total vcore-milliseconds taken by all map tasks=117224
                Total megabyte-milliseconds taken by all map tasks=60018688
        Map-Reduce Framework
                Map input records=2
                Map output records=0
                Input split bytes=216
                Spilled Records=0
                Failed Shuffles=0
                Merged Map outputs=0
                GC time elapsed (ms)=2343
                CPU time spent (ms)=50030
                Physical memory (bytes) snapshot=437194752
                Virtual memory (bytes) snapshot=4442087424
                Total committed heap usage (bytes)=215482368
                Peak Map Physical memory (bytes)=230854656
                Peak Map Virtual memory (bytes)=2239492096
        File Input Format Counters 
                Bytes Read=175
        File Output Format Counters 
                Bytes Written=0
TPC-DS text data generation complete.
Loading text data into external tables.
Optimizing table date_dim (1/24).
Optimizing table time_dim (2/24).
Optimizing table item (3/24).
Optimizing table customer (4/24).
Optimizing table customer_demographics (5/24).
Optimizing table household_demographics (6/24).
Optimizing table customer_address (7/24).
Optimizing table store (8/24).
Optimizing table promotion (9/24).
Optimizing table warehouse (10/24).
Optimizing table ship_mode (11/24).
Optimizing table reason (12/24).
Optimizing table income_band (13/24).
Optimizing table call_center (14/24).
Optimizing table web_page (15/24).
Optimizing table catalog_page (16/24).
Optimizing table web_site (17/24).
Optimizing table store_sales (18/24).
Optimizing table store_returns (19/24).
Optimizing table web_sales (20/24).
Optimizing table web_returns (21/24).
Optimizing table catalog_sales (22/24).
Optimizing table catalog_returns (23/24).
Optimizing table inventory (24/24).
Loading constraints
Data loaded into database tpcds_bin_partitioned_orc_2.
```
 
大致有以下几个过程：
1) 调用mapreduce程序生成TXT数据，默认在/tmp/tpcds-generate/$SF
2) 建立TXT表，建表语句在ddl-tpcds/
3) 建立ORC表，将数据从TXT表插入到ORC表。

- Step 6: 执行测试(Hive\Spark\Mr3)

1) (可选)重新生成统计信息
```
SF=10

beeline -u "jdbc:hive2://localhost:10000/tpcds_bin_partitioned_orc_$SF" -n hive -f ./ddl-tpcds/bin_partitioned/analyze.sql 
```
2) 单条语句测试
在正式测试前，最后随机挑选几个测试联通性。

例如hive:
```
cd sample-queries-tpcds
hive --database tpcds_bin_partitioned_orc_$SF
```

以下 tpcds_bin_partitioned_orc_10 中的“10”为SF，需要自己替换。
```
use tpcds_bin_partitioned_orc_10;

source query10.sql;

```

3) 99条sql测试


```
--切换到hive-testbench的目录
cd ~/hive-testbench
--生成每段sql执行必须执行的sql
echo "use tpcds_bin_partitioned_orc_$SF;" > sample-queries-tpcds/testbench.settings
```

spark3执行过程会遇到报错，可以考虑关掉spark.sql.autoBroadcastJoinThreshol

```
echo "use tpcds_bin_partitioned_orc_$SF; set spark.sql.autoBroadcastJoinThreshold=-1;" > sample-queries-tpcds/testbench.settings

```

执行测试：

hive
```
./runSuite.pl tpcds $SF

```
Spark3需要配置kyuubi
```
./runSuite_kyuubi_spark3.pl tpcds $SF

```
MR3
```
./runSuite_mr3.pl tpcds $SF

```

结果集解读：
```
filename,status,time,rows
query1.sql,success,8,0,3.229
query10.sql,success,8,13,3.789
query11.sql,success,17,100,12.593
```
第一列：sql名称
第二列：执行是否成功
第三列：执行整体时间
第四列：结果集行数
第五列：sql执行时间（beeline里的单条sql执行时间，不包含beeline连接等时间）

注意执行以上sql时，需要注意本文开头所说的环境说明。

- Step 7: 执行测试(Trino)

```
./runSuite_trino.pl tpcds $SF
```

结果集解读：
```
filename,status,time,rows
query1.sql,success,5,132K,4.25
query10.sql,success,4,1.52M,2.44
query11.sql,success,6,6.17M,4.55
```
第一列：sql名称
第二列：执行是否成功
第三列：执行整体时间
第四列：读取文件大小
第五列：sql执行时间（beeline里的单条sql执行时间，不包含beeline连接等时间）

缺点：目前脚本无法读取sql结果集的行数，列出了文件大小以供参考



- Step 8: 执行测试(Doris)

测试Doris读取Hive表的性能。


#hdp里创建mysql软链接
```
ln -s /usr/hdp/current/doris3-client/mysql-client/bin/mysql /usr/bin/mysql
```

连接数据库,测试单条
```
doris3 -uroot -P9030 -hdatanode01

-- 建立hive catalog 用于tpcds测试
CREATE CATALOG hive_catalog PROPERTIES (
    'type'='hms',
    'hive.metastore.uris' = 'thrift://datanode01:9083',
    'hadoop.username' = 'hive',
	'fs.defaultFS' = 'hdfs://datanode01:8020'
);

--切换catalog
switch hive_catalog;

--切换database; _2为SF，需要自己修改。
use tpcds_bin_partitioned_orc_2;

--显示表名
show tables;

--测试数据是否可读
select * from web_site limit 10;

```

执行测试脚本

```
#保持与Step6中一样的参数
export SF=10

# -s 1与SF意义相同，目前支持1 100 1000 10000，可以暂时使用1，不行再试其他
./bin/run-tpcds-queries.sh -s 1

```

结果集解读：
```
query1  3400    792     757     757
query2  2526    608     519     519
......
Total cold run time: 90105 ms
Total hot run time: 79001 ms
Finish tpcds queries.

```

第一列：sql名称
第二列：冷启动执行时间
第三列：热启动执行时间1
第四列：热启动执行时间2
第五列：两个热启动执行时间的最小值



- Step 9: 并行测试

TODO：部分计算引擎在单次执行时，明显优秀，但是在并发状态下，开始下降，需要一个更大的环境进行并发测试。


