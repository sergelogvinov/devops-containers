#
FROM ubuntu:hirsute AS base

ENV DEBIAN_FRONTEND=noninteractive TERM=xterm-color LC_ALL=en_US.UTF-8
RUN LC_ALL=C apt-get update -y && LC_ALL=C apt-get install -y locales && \
    LC_ALL=C locale-gen --no-purge en_US.UTF-8 && \
    apt-get update -y && \
    apt-get install -y zsh zsh-autosuggestions && \
    apt-get install -y sudo vim curl wget && \
    apt-get install -y git make zip jq && \
    apt-get install -y golang && \
    apt-get install -y python3 python3-pip python3-boto python3-jmespath && \
    apt-get autoremove -y && \
    apt-get clean && \
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /oh-my-zsh && \
    mkdir -p /var/run/sshd && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update -y && apt-get install -y openssh-server && apt-get clean

RUN apt-get update -y && \
    apt-get install -y ansible ansible-lint yamllint && \
    apt-get install -y docker.io && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY ["etc/","/etc/"]

RUN adduser --disabled-password --home /home/vscode --shell=/usr/bin/zsh --uid 1100 --gecos "VS Code" vscode && \
    echo "vscode ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    usermod -aG sudo vscode && \
    install -m 0750 -o vscode -g vscode -d /home/vscode/.ssh /home/vscode/.ansible /home/vscode/.docker /www

WORKDIR /www

#############################
#
FROM base AS kube

RUN wget https://dl.k8s.io/v1.20.1/kubernetes-client-linux-amd64.tar.gz -O /tmp/kubernetes-client-linux-amd64.tar.gz && \
    cd /tmp && tar -xzf /tmp/kubernetes-client-linux-amd64.tar.gz && mv kubernetes/client/bin/kubectl /usr/bin/kubectl && \
    wget https://get.helm.sh/helm-v3.4.2-linux-amd64.tar.gz -O /tmp/helm.tar.gz && \
    cd /tmp && tar -xzf /tmp/helm.tar.gz && mv linux-amd64/helm /usr/bin/helm && rm -rf /tmp/* && \
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add - && \
    echo "deb [arch=amd64] https://apt.releases.hashicorp.com groovy main" > /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && apt-get install terraform && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

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
    make -j2 && make install && cd .. && ln -s /usr/local/openresty/bin/openresty /usr/sbin/nginx && \
    rm -rf openresty-1.19.3.1 openresty-1.19.3.1.tar.gz && \
    install -m 0775 -g vscode -d /usr/local/openresty/nginx/client_body_temp /usr/local/openresty/nginx/proxy_temp && \
    install -m 0775 -g vscode -d /usr/local/openresty/nginx/fastcgi_temp /usr/local/openresty/nginx/uwsgi_temp && \
    install -m 0775 -g vscode -d /usr/local/openresty/nginx/scgi_temp /usr/local/openresty/nginx/logs

RUN cpan Test::Nginx

ENV TEST_NGINX_BINARY=/usr/sbin/nginx

USER vscode

#############################
#
FROM kube AS pytest

RUN apt-get update -y && \
    apt-get install -y  && \
    apt-get install -y libpcre3-dev \
        libssl-dev zlib1g-dev perl make build-essential && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update -y && apt-get install -y python3 python3-venv python3-dev python3-pip && \
    pip3 install pipenv && \
    pip3 install --ignore-installed psycopg2-binary && \
    apt-get install -y gcc libxml2-dev libxslt1-dev libpq-dev && \
    apt-get install -y python3-redis python3-requests python3-dateutil python3-ipython && \
    apt-get install -y python3-cffi libcairo2 libpango-1.0-0 libpangocairo-1.0-0 \
        libgdk-pixbuf2.0-0 libffi-dev shared-mime-info musl-dev && \
    rm -rf /root/.cache && \
    apt-get autoremove -y && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER vscode
