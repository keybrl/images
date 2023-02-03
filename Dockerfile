# base
FROM --platform=${TARGETPLATFORM} ubuntu:22.04 AS base

LABEL repo="https://github.com/keybrl/images.git"

ARG APT_MIRROR=http://mirrors.tencent.com/

WORKDIR /root

# 安装基础环境
RUN sed -i.bac -re "s|https?://[^/]+/|${APT_MIRROR}|g" /etc/apt/sources.list \
    && apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata \
    && apt-get clean autoclean autoremove -y \
    && rm -rf /var/lib/apt/lists/*

ENV LC_ALL=C.utf8

# kits
FROM --platform=${TARGETPLATFORM} base AS kits

ARG TARGETARCH

# 安装基础工具
# - jq, sshpass
# - iperf3
# - curl, wget, telnet, ssh, sshd
# - iptables, ip, route
# - ifconfig, dig, host, nslookup, ping
# - docker vim
RUN apt-get update -y \
    && echo "installing jq, sshpass ..." \
    && apt-get install -y jq sshpass \
    && echo "installing iperf3 ..." \
    && apt-get install -y iperf3 \
    && echo "installing curl, wget, telnet, ssh, sshd ..." \
    && apt-get install -y curl wget telnet ssh \
    && echo "installing iptables, ip, route ..." \
    && apt-get install -y iptables iproute2 \
    && echo "installing ifconfig, dig, host, nslookup, ping ..." \
    && apt-get install -y net-tools dnsutils iputils-ping \
    && echo "installing vim ..." \
    && apt-get install -y vim \
    && echo "installing docker ..." \
    && apt-get install -y ca-certificates gnupg lsb-release \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://mirrors.tencent.com/docker-ce/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg]" \
       "https://mirrors.tencent.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update -y \
    && apt-get install -y docker-ce-cli \
    && echo "cleaning up ..." \
    && apt-get clean autoclean autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# 安装 frp
ADD share/frp/frp_0.46.1_linux_${TARGETARCH}.tar.gz frp
RUN mv frp/frp_0.46.1_linux_${TARGETARCH}/frps /bin/frps \
    && mv frp/frp_0.46.1_linux_${TARGETARCH}/frpc /bin/frpc \
    && rm -rf frp \
    && chmod +x /bin/frps /bin/frpc

# 安装 gost
COPY share/gost/gost-linux-${TARGETARCH}-2.11.5.gz gost.gz
RUN gzip -d gost.gz \
    && mv gost /bin/gost \
    && chmod +x /bin/gost

# 安装 kubectl, helm, helm-diff(todo)
COPY share/kubectl/kubectl-v1.26.1-linux-${TARGETARCH} /bin/kubectl
ADD share/helm/helm-v3.11.0-linux-${TARGETARCH}.tar.gz helm/
RUN mv helm/linux-${TARGETARCH}/helm /bin/helm \
    && rm -rf helm \
    && chmod +x /bin/kubectl /bin/helm

CMD ["/bin/bash"]

# devkits
FROM --platform=${TARGETPLATFORM} kits AS devkits

# 安装开发工具
# git, git-lfs, git-crypt
# zsh, oh-my-zsh
# make
RUN apt-get update -y \
    && echo "installing git, git-lfs, git-crypt ..." \
    && apt-get install -y git git-lfs git-crypt \
    && echo "installing zsh, oh-my-zsh ..." \
    && apt-get install -y zsh \
    && chsh -s /bin/zsh \
    && curl -o install-zsh.sh -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh \
    && sh install-zsh.sh \
    && rm install-zsh.sh \
    && echo "installing make ..." \
    && apt-get install make \
    && echo "cleaning up ..." \
    && apt-get clean autoclean autoremove -y \
    && rm -rf /var/lib/apt/lists/*

CMD ["/bin/zsh"]

# TODO: devkits-gui
FROM --platform=${TARGETPLATFORM} devkits AS devkits-gui

# X11 VNC
# gnome
# gnome-mines
# gnome-terminal
