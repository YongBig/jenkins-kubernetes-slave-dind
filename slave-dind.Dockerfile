FROM jenkins/jnlp-slave

USER root
# Install Docker client
ENV DOCKERVERSION=18.03.1-ce
RUN curl -fsSLO https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/static/stable/x86_64/docker-${DOCKERVERSION}.tgz \
  && tar xzvf docker-${DOCKERVERSION}.tgz --strip 1 \
                 -C /usr/local/bin docker/docker \
  && rm docker-${DOCKERVERSION}.tgz
RUN groupadd -g 995 docker
RUN usermod -aG docker jenkins
USER jenkins