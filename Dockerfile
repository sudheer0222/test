FROM openjdk:8-jdk

RUN apt-get update -y && apt-get install -y curl sudo

ENV KUBECTL_VERSION="v1.18.0"

RUN apt-get add --update ca-certificates bash gnupg jq py-pip \
  && apt-get add --update -t deps curl gettext \
  && pip install awscli \
  && apt-get --purge -v del py-pip \
  && rm -rf /var/cache/apk/* 

RUN curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
  & curl -L https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.3.0/heptio-authenticator-aws_0.3.0_linux_amd64 -o /usr/local/bin/aws-iam-authenticator \
  & wait \
  && chmod +x /usr/local/bin/kubectl \
  && chmod +x /usr/local/bin/aws-iam-authenticator
  
RUN mkdir -p kube
ADD . .
RUN chmod +x entrypoint.sh
ENV KUBECONFIG=/kube/config


ARG user=jenkins
ARG group=jenkins
ARG uid=10000
ARG gid=10000

ENV HOME /home/${user}
RUN groupadd -g ${gid} ${group}
RUN useradd -c "Jenkins user" -d $HOME -u ${uid} -g ${gid} -m ${user}
RUN usermod -aG sudo ${user}

ARG VERSION=3.20
ARG AGENT_WORKDIR=/home/${user}/agent

RUN curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/slave.jar
    
COPY jenkins-slave /usr/local/bin/jenkins-slave
RUN chmod 777 /usr/local/bin/jenkins-slave

RUN echo 'jenkins ALL=(ALL) NOPASSWD:ALL'| sudo EDITOR='tee -a' visudo

USER ${user}
ENV AGENT_WORKDIR=${AGENT_WORKDIR}
RUN mkdir /home/${user}/.jenkins && mkdir -p ${AGENT_WORKDIR}

VOLUME /home/${user}/.jenkins
VOLUME ${AGENT_WORKDIR}
WORKDIR /home/${user}

ENTRYPOINT ["/usr/local/bin/jenkins-slave"]
ENTRYPOINT [ "/entrypoint.sh" ]
