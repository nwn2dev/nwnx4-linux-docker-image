FROM debian:trixie

# Add temp. folder for X11
RUN mkdir -p /tmp/.X11-unix \
    && chmod 1777 /tmp/.X11-unix

# Install requirements
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y gosu wget unzip cabextract xvfb openssl gnupg2 ca-certificates \
    \
    && mkdir -pm755 /etc/apt/keyrings \
    && wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key \
    && wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/trixie/winehq-trixie.sources \
    && apt-get update \
    && apt-get install -y --install-recommends winehq-stable \
    \
    && wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks -O /usr/local/bin/winetricks \
    && chmod +x /usr/local/bin/winetricks \
    \
    && apt-get install -y curl unzip \
    \
    && apt-get clean \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

ARG NWNX4_USER_HOME="/home/nwnx4"

# Setup nwnx4 user
RUN useradd -u 1000 -d $NWNX4_USER_HOME --create-home -ms /bin/bash nwnx4

# Give access to NWNX4 etc folder to nwnx4 user
RUN mkdir -p /etc/nwnx4/plugins \
    && chown nwnx4:nwnx4 -R /etc/nwnx4

# Set to nwnx4 user; allows wine to be configured correctly
USER nwnx4:nwnx4

# Setup Wine/Xvfb
ENV WINEARCH="win32"
ENV WINEPREFIX="$NWNX4_USER_HOME/.wine32"
ENV WINE_NO_AUDIO=1
ENV AUDIODRIVER="none"
ENV DISPLAY=":0"

RUN ln -s /srv/nwn2-home "$NWNX4_USER_HOME/Neverwinter Nights 2" \
    && mkdir -p "$WINEPREFIX/drive_c/users/nwnx4/Temp/NWN2" \
    && ln -s /srv/nwn2-logs "$WINEPREFIX/drive_c/users/nwnx4/Temp/NWN2/LOGS.0"

VOLUME ["/srv/nwn2-logs"]

RUN wineboot --init \
    && winecfg \
    && xvfb-run winetricks -q vcrun2005 vcrun2015 dotnet48 \
    && rm -rf /tmp/wine*

# Setup NWN2 stage and registry overrides
COPY --chown=nwnx4:nwnx4 nwn2-stage /opt/nwn2-stage
COPY --chown=nwnx4:nwnx4 nwn2.reg /opt/

# Fix to ALSA configuration
COPY --chown=nwnx4:nwnx4 .asoundrc $NWNX4_USER_HOME

# Expose UDP port 5121 for port access to NWN2 server
EXPOSE 5121/udp

# Setup entrypoint and command
USER root

ARG RELEASE_URL="https://github.com/nwn2dev/nwnx4/releases/latest/download/nwnx4.zip"

# Setup release
RUN wget $RELEASE_URL -O nwnx4.zip \
    && unzip nwnx4.zip -d /opt \
    && chown -R nwnx4:nwnx4 /opt/nwnx4

ENV WINEDEBUG="-all"

WORKDIR /srv/nwnx4-user
COPY --chmod=+x docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["wine", "/opt/nwnx4/NWNX4_Controller.exe", "-interactive", "-verbose"]
