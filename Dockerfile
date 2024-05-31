#

FROM golang:1.22.3-bookworm AS base
LABEL org.opencontainers.image.source https://github.com/sergelogvinov/devops-containers

ENV DEBIAN_FRONTEND=noninteractive TERM=xterm-color LC_ALL=C.UTF-8
RUN LC_ALL=C apt-get update -y && LC_ALL=C apt-get install -y locales less && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    LC_ALL=C locale-gen --no-purge en_US.UTF-8 && \
    apt-get update -y && \
    apt-get install -y zsh zsh-autosuggestions && \
    apt-get install -y sudo vim curl wget htop && \
    apt-get install -y git make zip jq && \
    apt-get install -y python3 python3-pip python3-boto python3-jmespath python3-poetry && \
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

# https://hub.docker.com/_/docker/tags
COPY --from=docker:25.0.5-cli /usr/local/libexec/docker/cli-plugins/docker-compose /usr/local/libexec/docker/cli-plugins/docker-compose
COPY --from=docker/buildx-bin:0.13.1 /buildx /usr/local/libexec/docker/cli-plugins/docker-buildx

COPY ["etc/","/etc/"]

RUN adduser --disabled-password --home /home/vscode --shell=/usr/bin/zsh --uid 1100 --gecos "VS Code" vscode && \
    echo "vscode ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    usermod -aG sudo vscode && \
    install -m 0750 -o vscode -g vscode -d /home/vscode/.ssh /home/vscode/.ansible /home/vscode/.docker /www

WORKDIR /www

#############################
#
FROM base AS kube

COPY --from=bitnami/kubectl:1.28.9 /opt/bitnami/kubectl/bin/kubectl /usr/local/bin/kubectl
COPY --from=alpine/helm:3.13.3 /usr/bin/helm /usr/bin/helm
COPY --from=ghcr.io/getsops/sops:v3.8.1-alpine /usr/local/bin/sops /usr/bin/sops
COPY --from=ghcr.io/sergelogvinov/vals:0.36.0 /usr/bin/vals /usr/bin/vals
COPY --from=ghcr.io/yannh/kubeconform:v0.6.4 /kubeconform /usr/bin/kubeconform
COPY --from=minio/mc:RELEASE.2024-01-16T16-06-34Z /usr/bin/mc /usr/bin/mc

COPY --from=hashicorp/terraform:1.5.7         /bin/terraform       /bin/terraform
COPY --from=wagoodman/dive:v0.11.0            /usr/local/bin/dive  /usr/local/bin/dive

COPY --from=ghcr.io/sergelogvinov/skopeo:1.14 /usr/bin/skopeo /usr/bin/skopeo
COPY --from=ghcr.io/sergelogvinov/skopeo:1.14 /etc/containers/ /etc/containers/
COPY --from=ghcr.io/aquasecurity/trivy:0.51.4 /usr/local/bin/trivy /usr/local/bin/trivy

ENV HELM_DATA_HOME=/usr/local/share/helm
RUN helm plugin install https://github.com/jkroepke/helm-secrets --version v4.5.1

USER vscode
RUN git config --global pull.rebase false

#############################
#
FROM kube AS dev

USER root
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
RUN git config --global pull.rebase false

#############################
#
FROM kube AS pytest

USER root
RUN apt-get update -y && \
    apt-get install -y  && \
    apt-get install -y libpcre3-dev \
        libssl-dev zlib1g-dev perl make build-essential && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update -y && apt-get install -y python3 python3-full python3-psycopg2 && \
    apt-get install -y gcc libxml2-dev libxslt1-dev libpq-dev && \
    apt-get install -y python3-redis python3-requests python3-dateutil python3-ipython && \
    apt-get install -y python3-cffi libcairo2 libpango-1.0-0 libpangocairo-1.0-0 \
        libgdk-pixbuf2.0-0 libffi-dev shared-mime-info musl-dev && \
    apt-get install -y --no-install-recommends postgresql-client poppler-utils python3-gdal xmlsec1 ghostscript  \
      build-essential libpoppler-cpp-dev pkg-config && \
    rm -rf /root/.cache && \
    apt-get autoremove -y && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER vscode
RUN git config --global pull.rebase false
