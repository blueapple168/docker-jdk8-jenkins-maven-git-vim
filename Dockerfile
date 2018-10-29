# Ubuntu 16.04 LTS
# OpenJDK 1.8.0 64 bit
# Maven 3.3.9
# Jenkins 2.138.2
# git latest
# curl
# Vim

FROM openjdk:8-jdk

MAINTAINER BlueApple <blueapple1120@qq.com>

RUN apt-get update && apt-get install -y git curl vim && rm -rf /var/lib/apt/lists/*

ENV JENKINS_HOME /var/jenkins_home
ENV JENKINS_SLAVE_AGENT_PORT 50000

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000

ENV MAVEN_NAME apache-maven-3.3.9
ENV MAVEN_HOME /opt/maven/

# get maven 3.3.9
RUN wget --no-verbose -O /tmp/$MAVEN_NAME.tar.gz http://archive.apache.org/dist/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz \
    # install maven
    && mkdir /opt/maven \
    && tar -zxf /tmp/$MAVEN_NAME.tar.gz -C /opt/maven --strip-components=1 \
    && ln -s /opt/maven/bin/mvn /usr/local/bin \
    && rm -f /tmp/$MAVEN_NAME.tar.gz

# Jenkins is run with user `jenkins`, uid = 1000
# If you bind mount a volume from the host or a data container,
# ensure you use the same uid
RUN groupadd -g ${gid} ${group} \
    && useradd -d "$JENKINS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user}

# Jenkins home directory is a volume, so configuration and build history
# can be persisted and survive image upgrades
VOLUME /var/jenkins_home

# `/usr/share/jenkins/ref/` contains all reference configuration we want
# to set on a fresh new installation. Use it to bundle additional plugins
# or config file with your custom jenkins Docker image.
RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d

ENV TINI_VERSION 0.9.0
ENV TINI_SHA fa23d1e20732501c3bb8eeeca423c89ac80ed452

# Use tini as subreaper in Docker container to adopt zombie processes
RUN curl -fsSL https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-static -o /bin/tini && chmod +x /bin/tini \
  && echo "$TINI_SHA  /bin/tini" | sha1sum -c -

COPY init.groovy /usr/share/jenkins/ref/init.groovy.d/tcp-slave-agent-port.groovy

# jenkins version being bundled in this docker image
ARG JENKINS_VERSION
ENV JENKINS_VERSION ${JENKINS_VERSION:-2.138.2}

# jenkins.war checksum, download will be validated using it
ARG JENKINS_SHA256=d8ed5a7033be57aa9a84a5342b355ef9f2ba6cdb490db042a6d03efb23ca1e83

# Can be used to customize where jenkins.war get downloaded/copied from
ARG JENKINS_URL=https://jenkins-updates.cloudbees.com/download/je/${JENKINS_VERSION}/jenkins.war

# Copy the jenkins war and check the SHA
ADD ${JENKINS_URL} /usr/share/jenkins/jenkins.war
RUN echo "${JENKINS_SHA} /usr/share/jenkins/jenkins.war" | sha1sum -c -

ENV JENKINS_UC https://updates.jenkins.io
RUN chown -R ${user} "$JENKINS_HOME" /usr/share/jenkins/ref

# for main web interface:
EXPOSE 8080

# will be used by attached slave agents:
EXPOSE 50000

ENV COPY_REFERENCE_FILE_LOG $JENKINS_HOME/copy_reference_file.log

USER ${user}

COPY referrer.txt /usr/share/jenkins/ref/.cloudbees-referrer.txt
COPY jenkins-support.sh /usr/local/bin/jenkins-support
COPY jenkins.sh /usr/local/bin/jenkins.sh
ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/jenkins.sh"]

# from a derived Dockerfile, can use `RUN plugins.sh active.txt` to setup /usr/share/jenkins/ref/plugins from a support bundle
COPY plugins.sh /usr/local/bin/plugins.sh
COPY install-plugins.sh /usr/local/bin/install-plugins.sh
