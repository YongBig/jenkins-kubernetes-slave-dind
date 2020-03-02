# This is a fully functional Jenkins server, based on the weekly and LTS releases .
FROM jenkins/jenkins:lts

# set timezone for Java runtime arguments #TODO: FIXME security vulnerability
ENV JAVA_OPTS='-Duser.timezone=Asia/Shanghai -Dpermissive-script-security.enabled=no_security'

ENV JENKINS_UC https://updates.jenkins-zh.cn

ENV JENKINS_UC_DOWNLOAD https://mirrors.tuna.tsinghua.edu.cn/jenkins

# set timezone for OS by root
USER root
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# Plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

# Local Plugins
# COPY hpi/* /usr/share/jenkins/ref/plugins/

# VOLUME
VOLUME /var/jenkins_home

USER jenkins