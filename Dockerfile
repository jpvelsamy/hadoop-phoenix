FROM sequenceiq/hadoop-docker:2.7.1
MAINTAINER SequenceIQ

USER root

# update libselinux. see https://github.com/sequenceiq/hadoop-docker/issues/14
RUN yum clean all \
    && rpm --rebuilddb \
    && yum install -y curl which tar sudo openssh-server openssh-clients rsync \
    && yum clean all \
    && yum update -y libselinux \
    && yum clean all




RUN rpm -e cracklib-dicts --nodeps
RUN yum install -y cracklib-dicts


#RUN yum -y update
#RUN yum groupinstall -y 'development tools'
#RUN yum install -y zlib-devel bzip2-devel openssl-devel xz-libs wget
RUN curl -OL http://www.python.org/ftp/python/2.7.8/Python-2.7.8.tar.xz
RUN tar xf Python-2.7.8.tar.xz
RUN cd Python-2.7.8;./configure --prefix=/usr/local;make;make altinstall

RUN sed  -i "/^[^#]*UsePAM/ s/.*/#&/"  /etc/ssh/sshd_config
RUN echo "UsePAM no" >> /etc/ssh/sshd_config
RUN echo "Port 22" >> /etc/ssh/sshd_config

# zookeeper
ENV ZOOKEEPER_VERSION 3.4.11
RUN curl -s http://mirror.csclub.uwaterloo.ca/apache/zookeeper/zookeeper-$ZOOKEEPER_VERSION/zookeeper-$ZOOKEEPER_VERSION.tar.gz | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s ./zookeeper-$ZOOKEEPER_VERSION zookeeper
ENV ZOO_HOME /usr/local/zookeeper
ENV PATH $PATH:$ZOO_HOME/bin
ADD zoo.cfg $ZOO_HOME/conf/zoo.cfg
RUN mkdir -p /root/docker-data/zookeeper

# hbase
ENV HBASE_MAJOR 1.3
ENV HBASE_MINOR 1
ENV HBASE_VERSION "${HBASE_MAJOR}.${HBASE_MINOR}"
RUN curl -s http://www-us.apache.org/dist/hbase/$HBASE_VERSION/hbase-$HBASE_VERSION-bin.tar.gz | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s ./hbase-$HBASE_VERSION hbase
ENV HBASE_HOME /usr/local/hbase
ENV PATH $PATH:$HBASE_HOME/bin
RUN rm $HBASE_HOME/conf/hbase-site.xml
ADD hbase-site.xml $HBASE_HOME/conf/hbase-site.xml

#hdfs - permanent data folder
ENV HDFS_HOME /usr/local/hadoop
RUN mv $HDFS_HOME/etc/hadoop/hdfs-site.xml $HDFS_HOME/etc/hadoop/hdfs-site.xml.bkup
ADD hdfs-site.xml $HDFS_HOME/etc/hadoop/hdfs-site.xml
RUN mkdir -p /root/docker-data/hdfs/name
RUN mkdir -p /root/docker-data/hdfs/data
RUN $HDFS_HOME/bin/hdfs namenode -format

# phoenix
ENV PHOENIX_VERSION 4.13.1
RUN curl -s http://redrockdigimark.com/apachemirror/phoenix/apache-phoenix-4.13.1-HBase-1.3/bin/apache-phoenix-4.13.1-HBase-1.3-bin.tar.gz | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s ./apache-phoenix-$PHOENIX_VERSION-HBase-$HBASE_MAJOR-bin phoenix
ENV PHOENIX_HOME /usr/local/phoenix
ENV PATH $PATH:$PHOENIX_HOME/bin
RUN cp $PHOENIX_HOME/phoenix-core-$PHOENIX_VERSION-HBase-$HBASE_MAJOR.jar $HBASE_HOME/lib/phoenix.jar
RUN cp $PHOENIX_HOME/phoenix-$PHOENIX_VERSION-HBase-$HBASE_MAJOR-server.jar $HBASE_HOME/lib/phoenix-server.jar

# bootstrap-phoenix
ADD bootstrap-phoenix.sh /etc/bootstrap-phoenix.sh
RUN chown root:root /etc/bootstrap-phoenix.sh
RUN chmod 700 /etc/bootstrap-phoenix.sh

#start ssh
RUN service sshd start

#User for running the apps
#RUN useradd --create-home --shell /bin/bash jpvel
#RUN echo 'jpvel:password' | chpasswd
#RUN adduser jpvel sudo
#USER jpvel
#WORKDIR /home/jpvel

CMD ["/etc/bootstrap-phoenix.sh", "-bash"]

# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090
# Mapred ports
EXPOSE 19888
#Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088
#Other ports
EXPOSE 49707 22
EXPOSE 8765 9000 2181
