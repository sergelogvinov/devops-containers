#
FROM ubuntu:groovy AS base

ENV DEBIAN_FRONTEND=noninteractive TERM=xterm-color LC_ALL=en_US.UTF-8
RUN LC_ALL=C apt-get update -y && LC_ALL=C apt-get install -y locales && \
    LC_ALL=C locale-gen --no-purge en_US.UTF-8 && \
    apt-get update -y && \
    apt-get install -y openssh-server sudo vim curl wget && \
    apt-get install -y git make zip jq && \
    apt-get install -y golang && \
    apt-get install -y python3 python3-pip python3-boto python3-jmespath && \
    apt-get autoremove -y && \
    apt-get clean && \
    mkdir -p /var/run/sshd && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update -y && \
    apt-get install -y ansible ansible-lint yamllint && \
    apt-get install -y docker.ce && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --home /home/vscode --shell=/bin/bash --uid 1100 --gecos "VS Code" vscode && \
    echo "vscode ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    usermod -aG sudo vscode && \
    install -m 0750 -o vscode -g vscode -d /home/vscode/.ssh /home/vscode/.ansible /home/vscode/.docker /www

COPY ["etc/","/etc/"]
WORKDIR /www

#############################
#
FROM base AS kube

RUN wget https://dl.k8s.io/v1.19.4/kubernetes-client-linux-amd64.tar.gz -O /tmp/kubernetes-client-linux-amd64.tar.gz && \
    cd /tmp && tar -xzf /tmp/kubernetes-client-linux-amd64.tar.gz && mv kubernetes/client/bin/kubectl /usr/bin/kubectl && \
    wget https://get.helm.sh/helm-v3.4.1-linux-amd64.tar.gz -O /tmp/helm.tar.gz && \
    cd /tmp && tar -xzf /tmp/helm.tar.gz && mv linux-amd64/helm /usr/bin/helm && rm -rf /tmp/*

#############################
#
FROM kube AS dev

RUN apt-get update -y && \
    apt-get install -y  && \
    apt-get install -y libpcre3-dev \
        libssl-dev zlib1g-dev perl make build-essential && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN wget https://openresty.org/download/openresty-1.19.3.1.tar.gz -O openresty-1.19.3.1.tar.gz && \
    tar xzf openresty-1.19.3.1.tar.gz && \
    cd openresty-1.19.3.1 && ./configure -j2 --with-http_realip_module --with-pcre-jit --with-ipv6 --conf-path=/etc/nginx/nginx.conf && \
    make -j2 && make install && cd .. && \
    rm -rf openresty-1.19.3.1 openresty-1.19.3.1.tar.gz

USER vscode
