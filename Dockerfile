#
# Ubuntu 14.04
#
# https://hub.docker.com/_/ubuntu/
#

# Pull base image.
FROM uwitech/ohie-base

USER root

#install tools
RUN apt-get -y install software-properties-common python-software-properties
RUN add-apt-repository ppa:webupd8team/java
RUN apt-get update
RUN echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java7-installer && \
    apt-get clean
RUN DEBIAN_FRONTEND=noninteractive \
 apt-get update && \
 apt-get install -y openjdk-7-jre-headless tomcat7 tomcat7-user && \
 groupadd -g 9000 tcuser && \
 useradd -d /tomcat -r -s /bin/false -g 9000 -u 9000 tcuser && \ 
 tomcat7-instance-create /tomcat && \
 chown -R tcuser:tcuser /tomcat

# Add volumes for volatile directories that aren't usually shared with child images.
VOLUME ["/tomcat/logs", "/tomcat/temp", "/tomcat/work"]

# Workaround for https://bugs.launchpad.net/ubuntu/+source/tomcat7/+bug/1232258
RUN ln -s /var/lib/tomcat7/common/ /usr/share/tomcat7/common && \
 ln -s /var/lib/tomcat7/server/ /usr/share/tomcat7/server && \
 ln -s /var/lib/tomcat7/shared/ /usr/share/tomcat7/shared

#install openempi
RUN mkdir sysnet
RUN cd sysnet
COPY openempi-3.3.0c /sysnet/openempi-3.3.0c
RUN export OPENEMPI_HOME=/sysnet/openempi-3.3.0c

RUN cp /sysnet/openempi-3.3.0c/openempi-entity-3.3.0c/openempi-entity-webapp-web-3.3.0c.war /var/lib/tomcat7/webapps

# Use IPv4 by default and UTF-8 encoding. These are almost universally useful.
ENV JAVA_OPTS -Djava.net.preferIPv4Stack=true -Dfile.encoding=UTF-8

# All your base...
ENV CATALINA_BASE /tomcat

# Drop privileges and run Tomcat.
USER tcuser
CMD /usr/share/tomcat7/bin/catalina.sh run

# Expose HTTP only by default.
EXPOSE 8080
