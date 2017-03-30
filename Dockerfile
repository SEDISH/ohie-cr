#
# Ubuntu 14.04
#
# https://hub.docker.com/_/ubuntu/
#

# Pull base image.
FROM uwitech/ohie-base

USER root

# Install dependencies
RUN apt-get update && \
apt-get install -y git build-essential curl wget software-properties-common
RUN apt-get install -y postgresql-client

# Install Java.
RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer

#RUN apt-get install oracle-java8-set-default


# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

#install openempi
RUN mkdir sysnet
RUN cd sysnet
COPY openempi-3.3.0c /sysnet/openempi-3.3.0c
RUN export OPENEMPI_HOME=/sysnet/openempi-3.3.0c

# Install Tomcat
ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME
 
# see https://www.apache.org/dist/tomcat/tomcat-8/KEYS
ENV GPG_KEYS 05AB33110949707C93A279E3D3EFE6B686867BA6 07E48665A34DCAFAE522E5E6266191C37C037D42 47309207D818FFD8DCD3F83F1931D684307A10A5 541FBE7D8F78B25E055DDEE13C370389288584E7 61B832AC2F1C5A90F0F9B00A1C506407564C17A3 713DA88BE50911535FE716F5208B0AB1D63011C7 79F7026C690BAA50B92CD8B66A3AD3F4F22C4FED 9BA44C2621385CB966EBA586F72C284D731FABEE A27677289986DB50844682F8ACB77FC2E86E29AC A9C5DF4D22E99998D9875A5110C01C5A2F6059E7 DCFD35E0BF8CA7344752DE8B6FB21E8933C60243 F3A04C595DB5B6A5F1ECA43E3B7BBB100D811BBE F7DA48BB64BCB84ECBA7EE6935CD23C10D498E23
RUN set -ex; \
	for key in $GPG_KEYS; do \
		gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	done

ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.5.12
ENV TOMCAT_TGZ_URL https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz

RUN set -x \
    && curl -fSL "$TOMCAT_TGZ_URL" -o tomcat.tar.gz \
    && curl -fSL "$TOMCAT_TGZ_URL.asc" -o tomcat.tar.gz.asc \
    && gpg --verify tomcat.tar.gz.asc \
    && tar -xvf tomcat.tar.gz --strip-components=1 \
    && rm bin/*.bat \
    && rm tomcat.tar.gz*

ENV CATALINA_HOME /sysnet/openempi-3.3.0c
ENV PATH $CATALINA_HOME/bin:$PATH
ENV OPENEMPI_HOME /sysnet/openempi-3.3.0c
ENV PATH $OPENEMPI_HOME/bin:$PATH

EXPOSE 8080

COPY tomcat-users.xml $CATALINA_HOME/conf/
RUN chmod 777 $CATALINA_HOME/conf/tomcat-users.xml

# Launch Tomcat
WORKDIR /
COPY /script /script
RUN chmod +x /script

CMD /script

#CMD ./sysnet/openempi-3.3.0c/bin/catalina.sh jpda run
