FROM ubuntu:latest

ENV GBP_USER ${GBP_USER:-ubuntu}
ENV GBP_USER_ID ${GBP_USER_ID:-1000}

WORKDIR /app

USER root

RUN apt-get update && apt-get install -y --no-install-recommends curl wget gnupg2 ca-certificates supervisor

# Install xcfb
RUN apt-get install -y --no-install-recommends xvfb xauth pulseaudio

# Install locales
RUN apt-get install -y --no-install-recommends language-pack-en tzdata locales && \
    locale-gen en_US.UTF-8

# Install fluxbox
RUN apt-get install -y --no-install-recommends fluxbox eterm hsetroot feh

# Install Edge
RUN wget -q -O - https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg >/dev/null \
    && echo "deb https://packages.microsoft.com/repos/edge stable main" >> /etc/apt/sources.list.d/microsoft-edge.list \
    && apt-get update -qqy \
    && wget https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/microsoft-edge-stable_116.0.1938.81-1_amd64.deb -O /tmp/microsoft-edge-stable_amd64.deb \
    && apt-get install -qqy --no-install-recommends /tmp/microsoft-edge-stable_amd64.deb \
    && rm /tmp/microsoft-edge-stable_amd64.deb
COPY wrap_edge_binary /opt/bin/wrap_edge_binary
RUN /opt/bin/wrap_edge_binary

RUN curl -L https://github.com/Harry-zklcdc/go-bingai-pass/releases/latest/download/go-bingai-pass-linux-amd64.tar.gz -o go-bingai-pass-linux-amd64.tar.gz && \
    tar -zxvf go-bingai-pass-linux-amd64.tar.gz && \
    chmod +x go-bingai-pass

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm go-bingai-pass-linux-amd64.tar.gz

COPY start-xvfb.sh /opt/bin/start-xvfb.sh
COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf

# RUN groupadd -g $GBP_USER_ID $GBP_USER
# RUN useradd -rm -G sudo -u $GBP_USER_ID -g $GBP_USER_ID $GBP_USER

RUN mkdir -p /tmp/edge /var/run/supervisor /var/log/supervisor
RUN chown "${GBP_USER_ID}:${GBP_USER_ID}" /var/run/supervisor /var/log/supervisor
RUN chown -R "${GBP_USER_ID}:${GBP_USER_ID}" /app /tmp/edge
RUN chmod 777 /tmp

USER $GBP_USER

ENV SCREEN_WIDTH=1360
ENV SCREEN_HEIGHT=1020
ENV SCREEN_DEPTH=24
ENV SCREEN_DPI=96
ENV SE_START_XVFB=true
ENV DISPLAY=:99.0
ENV DISPLAY_NUM=99

ENV PORT=7860
ENV HEADLESS=false
ENV BROWSER_BINARY=/usr/bin/microsoft-edge
# ENV PASS_TIMEOUT=10
# ENV CHROME_PATH=/opt/google/chrome
ENV XDG_CONFIG_HOME=/tmp/edge
ENV XDG_CACHE_HOME=/tmp/edge

EXPOSE 7860

CMD /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisor.conf