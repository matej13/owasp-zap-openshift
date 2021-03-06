# This dockerfile builds the zap stable release

FROM registry.access.redhat.com/rhel7

MAINTAINER Dan Hawker <dhawker@redhat.com>

RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
# Need to enable the RHEL extras subs
RUN yum-config-manager --enable rhel-7-server-rpms rhel-7-server-extras-rpms rhel-7-server-optional-rpms epel > /dev/null

RUN yum install --enablerepo=rhel-7-server-rpms --enablerepo=rhel-7-server-extras-rpms \
    --enablerepo=rhel-7-server-optional-rpms --enablerepo=epel \
    -y redhat-rpm-config \
    make automake autoconf gcc gcc-c++ \
    libstdc++ libstdc++-devel \
    java-1.8.0-openjdk wget curl \
    xmlstarlet git x11vnc gettext tar \
    xorg-x11-server-Xvfb openbox xterm \
    net-tools python-pip \
    firefox nss_wrapper java-1.8.0-openjdk-headless \
    java-1.8.0-openjdk-devel nss_wrapper git && \
    yum clean all

RUN pip install --upgrade pip
RUN pip install zapcli
# Install latest dev version of the python API
RUN pip install python-owasp-zap-v2.4

RUN mkdir -p /zap/wrk && mkdir -p /zap/.ZAP
ADD zap /zap/

#RUN mkdir -p /var/lib/jenkins/.vnc

# Copy the entrypoint
#COPY configuration/* /var/lib/jenkins/
#COPY configuration/run-jnlp-client /usr/local/bin/run-jnlp-client

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
ENV PATH $JAVA_HOME/bin:/zap:$PATH
ENV ZAP_PATH /zap/zap.sh
#ENV HOME /var/lib/jenkins

# Default port for use with zapcli
ENV ZAP_PORT 8080

#COPY policies /var/lib/jenkins/.ZAP/policies/
COPY policies /zap/.ZAP/policies/
#COPY .xinitrc /var/lib/jenkins/

WORKDIR /zap
# Download and expand the latest stable release
RUN curl -s https://raw.githubusercontent.com/zaproxy/zap-admin/master/ZapVersions-dev.xml | xmlstarlet sel -t -v //url |grep -i Linux | wget -q --content-disposition -i - -O - | tar zx --strip-components=1 && \
    curl -s -L https://bitbucket.org/meszarv/webswing/downloads/webswing-2.3-distribution.zip | jar -x && \
    touch AcceptedLicense
ADD webswing.config /zap/webswing-2.3/webswing.config

RUN chown root:root /zap -R && \
#    chown root:root -R /var/lib/jenkins && \
#    chmod 777 /var/lib/jenkins -R && \
    chmod 777 /zap -R

#WORKDIR /var/lib/jenkins
WORKDIR /zap
RUN pwd && ls -la

# Run the Jenkins JNLP client
#ENTRYPOINT ["/usr/local/bin/run-jnlp-client"]
ENTRYPOINT ["/zap/zap.sh", "-dir", "/zap/.ZAP", "-daemon", "-host", "0.0.0.0", "-port", "9090", "-config", "api.disablekey=true"]
#CMD ["-dir", "/zap/.ZAP", "-daemon", "-host", "0.0.0.0", "-port", "8080"]
