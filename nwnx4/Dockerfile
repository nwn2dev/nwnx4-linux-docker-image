# Stable image
FROM debian:bullseye AS build

RUN echo "* soft stack unlimited" >> /etc/security/limits.conf \
    && echo "* hard stack unlimited" >> /etc/security/limits.conf

# Install requirements
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y gosu wget curl unzip cabextract xvfb openssl \
    && apt-get install -y gnupg2 software-properties-common \
    \
    && wget -qO- https://dl.winehq.org/wine-builds/winehq.key | apt-key add - \
    && apt-add-repository https://dl.winehq.org/wine-builds/debian/ \
    && apt-get update \
    && apt-get install -y --install-recommends winehq-staging \
    \
    && wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks -O /usr/local/bin/winetricks \
    && chmod +x /usr/local/bin/winetricks \
    \
    && apt-get clean \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

ENV NWNX4_USER_HOME="/home/nwnx4"

# Setup nwnx4 user
RUN useradd -u 1000 -d $NWNX4_USER_HOME --create-home -ms /bin/bash nwnx4 \
    && usermod -aG root nwnx4

# Set to nwnx4 user; allows wine to be configured correctly
USER nwnx4:nwnx4

# Setup Wine/Xvfb
ENV WINEPREFIX="$NWNX4_USER_HOME/.wine32"
ENV WINEARCH="win32"
ENV WINEDLLOVERRIDES="mshtml=;devenum,dxdiagn,dxgi=n"
ENV WINEDEBUG="-all"
ENV WINE_NO_AUDIO=1
ENV AUDIODRIVER="none"
ENV DISPLAY=":0"
ENV WINEDLLPATH="/usr/lib/wine"
ENV STAGING_SHARED_MEMORY=1

RUN wineboot --init \
    && xvfb-run -a winetricks -q corefonts vcrun2015

RUN rm -rf /tmp/*

USER root

RUN mkdir -p /tmp/.X11-unix \
    && chmod 1777 /tmp/.X11-unix \
    && chown root -R /tmp/.X11-unix

FROM build

# Setup NWN2 stage and registry overrides
COPY --chown=nwnx4:nwnx4 nwn2-stage /opt/nwn2
COPY --chown=nwnx4:nwnx4 nwn2.reg /opt/

# Fix to ALSA configuration
COPY --chown=nwnx4:nwnx4 .asoundrc $NWNX4_USER_HOME

# USER nwnx4:nwnx4

USER root

RUN mkdir -p /var/log/nwn2 "$WINEPREFIX/drive_c/users/nwnx4/AppData/Local/Temp" \
    && ln -s /var/log/nwn2 "$WINEPREFIX/drive_c/users/nwnx4/AppData/Local/Temp/NWN2" \
    && chown nwnx4:nwnx4 -R /var/log/nwn2 "$WINEPREFIX/drive_c/users/nwnx4/AppData/Local/Temp/NWN2"

VOLUME /var/log/nwn2

RUN mkdir -p /etc/nwnx4/plugins \
    && chown nwnx4:nwnx4 -R /etc/nwnx4/plugins

# Setup release
ARG VERSION=latest
ARG RELEASE_URL="https://github.com/nwn2dev/nwnx4/releases/latest/download/nwnx4.zip"
ENV NWNX4_VERSION=$VERSION

RUN if [ "$VERSION" != "latest" ]; then \
      RELEASE_URL="https://github.com/nwn2dev/nwnx4/releases/download/$VERSION/nwnx4.zip"; \
    fi \
    && wget "$RELEASE_URL" -O nwnx4.zip \
    && unzip nwnx4.zip -d /opt \
    && chown -R nwnx4:nwnx4 /opt/nwnx4

EXPOSE 5121/udp

COPY --chmod=+x docker-entrypoint.sh /

WORKDIR /srv/nwnx4-user
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["wine", "/opt/nwnx4/NWNX4_Controller.exe", "-interactive", "-verbose"]

ENV WINEDLLOVERRIDES="${WINEDLLOVERRIDES};granny2,mss32=n"
# ENV WINEDEBUG="+loaddll,+module"
