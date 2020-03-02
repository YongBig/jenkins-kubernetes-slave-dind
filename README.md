---
title: Jenkins
tags: kubernetes
grammar_cjkRuby: true
---
[toc!?theme=red&depth=4]

## 镜像
1. ==[docker hub](https://hub.docker.com/r/jenkins/jenkins) #03A9F4==
2. ==[github](https://github.com/jenkinsci/docker/blob/master/README.md) #03A9F4==

## 构建镜像预装插件
==Dockerfile==
```dockerfile
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
```
### 预装插件 plugins.txt
```tex
ssh-slaves
mailer
email-ext
slack
htmlpublisher
greenballs
simple-theme-plugin
kubernetes
workflow-aggregator
git
blueocean
docker-build-publish
http_request
github:1.29.4
pipeline-githubnotify-step
sidebar-link
hashicorp-vault-plugin
role-strategy
audit-trail
basic-branch-build-strategies
permissive-script-security
sonar
jacoco
fireline
parameterized-trigger
checkstyle
warnings-ng
pipeline-utility-steps
github-oauth
```
### Jenkins Master Yaml
```yaml
apiVersion: v1
kind: Namespace
metadata:
  labels:
    app: jenkins
  name: jenkins
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins.pvc-disk
  namespace: jenkins
spec:
  accessModes:
    - ReadWriteOnce
    - ReadWriteMany
  storageClassName: nfs-ssd
  resources:
    requests:
      storage: 10Gi
---
apiVersion: v1
kind: Service
metadata:
  namespace: jenkins
  labels:
    app: jenkins
  name: jenkins
spec:
  ports:
    - name: http
      port: 8080
      protocol: TCP
      targetPort: 8080
    - name: agent
      port: 50000
      protocol: TCP
      targetPort: 50000
  selector:
    app: jenkins
  type: ClusterIP
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  labels:
    app: jenkins
  name: jenkins.ingress
  namespace: jenkins
  annotations:
    # "413 Request Entity Too Large" uploading plugins, increase client_max_body_size
    nginx.ingress.kubernetes.io/proxy-body-size: 50m
    nginx.ingress.kubernetes.io/proxy-request-buffering: "off"
    # For nginx-ingress controller < 0.9.0.beta-18
    ingress.kubernetes.io/ssl-redirect: "true"
    # "413 Request Entity Too Large" uploading plugins, increase client_max_body_size
    ingress.kubernetes.io/proxy-body-size: 50m
    ingress.kubernetes.io/proxy-request-buffering: "off"
spec:
  rules:
    - host: jenkins.dev-sh-001.oneitfarm.com
      http:
        paths:
          - backend:
              serviceName: jenkins
              servicePort: 8080
            path: /
    - host: jenkins-jnlp.dev-sh-001.oneitfarm.com
      http:
        paths:
          - backend:
              serviceName: jenkins
              servicePort: 50000
            path: /
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: jenkins
rules:
  - apiGroups: [""]
    resources: ["namespaces"]
    verbs: ["create", "delete", "get", "list", "watch", "patch", "update"]
  - apiGroups: [""]
    resources: ["deployments"]
    verbs: ["create", "delete", "get", "list", "watch", "patch", "update"]
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["create", "delete", "get", "list", "watch", "patch", "update"]
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["create","delete","get","list","patch","update","watch"]
  - apiGroups: [""]
    resources: ["pods/exec"]
    verbs: ["create","delete","get","list","patch","update","watch"]
  - apiGroups: [""]
    resources: ["pods/log"]
    verbs: ["get","list","watch"]
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get"]

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: jenkins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: jenkins
subjects:
  - kind: ServiceAccount
    name: jenkins
    namespace: jenkins
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: jenkins
  name: jenkins
  namespace: jenkins
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      serviceAccount: jenkins
      containers:
        - name: jenkins
          image: harbor.oneitfarm.com/jenkins/master:lts
          imagePullPolicy: Always
          resources:
            limits:
              cpu: "2"
              memory: 2Gi
            requests:
              cpu: "0.5"
              memory: 256Mi
          volumeMounts:
            - mountPath: /var/jenkins_home
              name: jenkins-pvc
          env:
            - name: LIMITS_MEMORY
              valueFrom:
                resourceFieldRef:
                  resource: limits.memory
                  divisor: 1Mi
            - name: SERVICE_NAMESPACE
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: metadata.namespace
            - name: JAVA_OPTS
              value: "-Dhudson.model.UpdateCenter.updateCenterUrl=https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/ -Djenkins.install.runSetupWizard=false -Xmx$(LIMITS_MEMORY)m -XshowSettings:vm -Dhudson.slaves.NodeProvisioner.initialDelay=0 -Dhudson.slaves.NodeProvisioner.MARGIN=50 -Dhudson.slaves.NodeProvisioner.MARGIN0=0.85"
          ports:
            - containerPort: 8080
              name: http
              protocol: TCP
            - containerPort: 50000
              name: agent
              protocol: TCP
      volumes:
        - name: jenkins-pvc
          persistentVolumeClaim:
            claimName: jenkins.pvc-disk

```
### 账号

|   账号  |密码     | 权限    |
| --- | --- | --- |
|    admin | ci123456     | manager    |
|    deploy | ci123456     | deploy    |

### jnlp-slave DockerFile
```dockerfile
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
```

### slave pod 模版
Pod Templates
		标签列表	 必填用于分配节点
		
```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins/kube-default: true
    app: jenkins
    component: agent
spec:
  containers:
    - name: jnlp
      image: harbor.oneitfarm.com/jenkins/slave-dind
      resources:
        limits:
          cpu: 1
          memory: 2Gi
        requests:
          cpu: 1
          memory: 256Mi
      imagePullPolicy: Always
      env:
      - name: POD_IP
        valueFrom:
          fieldRef:
            fieldPath: status.podIP
      - name: DOCKER_HOST
        value: tcp://localhost:2375
    - name: dind
      image: harbor.oneitfarm.com/jenkins/docker:18.03-dind
      securityContext:
	  # 必须需求特权 允许访问设备 
	  # 
        privileged: true
	 # 挂载目录后 所有容器共享
      volumeMounts:
        - name: dind-storage
          mountPath: /var/lib/docker
  volumes:
    - name: dind-storage
      emptyDir: {}
```
	
 	Yaml merge strategy : Merge
	
	
### 为什么需要特权

[hub.docker](https://hub.docker.com/_/docker/)
[docker](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities)

>	>   By default, Docker containers are “unprivileged” and cannot, for example, run a Docker daemon inside a Docker container. This is because by default a container is not allowed to access any devices, but a “privileged” container is given access to all devices (see the documentation on cgroups devices).
>
>  >    When the operator executes docker run --privileged, Docker will enable access to all devices on the host as well as set some configuration in AppArmor or SELinux to allow the container nearly all the same access to the host as processes running outside containers on the host. Additional information about running with --privileged is available on the Docker Blog.