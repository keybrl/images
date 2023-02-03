ARG TARGETPLATFORM=linux/amd64

FROM --platform=${TARGETPLATFORM} ubuntu:22.04

ARG TARGETARCH=amd64
ARG APT_MIRROR=http://mirrors.tencent.com/

LABEL repo="https://github.com/keybrl/images.git"

WORKDIR /root

# 安装基础工具
# - jq, sshpass
# - iperf3
# - curl, wget, telnet, ssh, sshd
# - iptables, ip, route
# - ifconfig, dig, host, nslookup, ping
RUN sed -i.bac -re "s|https?://[^/]+/|${APT_MIRROR}|g" /etc/apt/sources.list \
    && apt-get update -y \
    && apt-get install -y jq iptables dnsutils iputils-ping net-tools telnet iproute2 curl ssh sshpass iperf3 \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata \
    && apt-get clean autoclean autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# 安装 frp
ADD share/frp/frp_0.46.1_linux_${TARGETARCH}.tar.gz frp
RUN mv frp/frp_0.46.1_linux_${TARGETARCH}/frps /bin/frps && \
    mv frp/frp_0.46.1_linux_${TARGETARCH}/frpc /bin/frpc && \
    rm -rf frp && \
    chmod +x /bin/frps /bin/frpc

# 安装 gost
COPY share/gost/gost-linux-${TARGETARCH}-2.11.5.gz gost.gz
RUN gzip -d gost.gz && \
    mv gost /bin/gost && \
    chmod +x /bin/gost

# 安装 kubectl, helm
COPY share/kubectl/kubectl-v1.26.1-linux-${TARGETARCH} /bin/kubectl
ADD share/helm/helm-v3.11.0-linux-${TARGETARCH}.tar.gz helm/
RUN mv helm/linux-${TARGETARCH}/helm /bin/helm && \
    rm -rf helm && \
    chmod +x /bin/kubectl /bin/helm

ENTRYPOINT ["/bin/bash"]
