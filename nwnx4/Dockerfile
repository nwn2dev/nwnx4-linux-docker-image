# Stable image
FROM debian:bullseye AS build

# Install requirements
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y gosu wget rsync cabextract xvfb openssl \
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
    && apt-get install -y curl unzip \
    \
    && apt-get clean \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

ARG NWNX4_USER_HOME="/home/nwnx4"

# Setup nwnx4 user
RUN useradd -u 1000 -d $NWNX4_USER_HOME --create-home -ms /bin/bash nwnx4

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
    && xvfb-run -a winetricks -q vcrun2005 vcrun2015 \
    && xvfb-run -a winetricks -q --force dotnet48

RUN rm -rf /tmp/*

USER root

RUN mkdir -p /tmp/.X11-unix \
    && chmod 1777 /tmp/.X11-unix \
    && chown root -R /tmp/.X11-unix

FROM build

ARG NWNX4_USER_HOME="/home/nwnx4"

# Setup NWN2 stage and registry overrides
COPY --chown=nwnx4:nwnx4 nwn2-stage /opt/nwn2-stage
COPY --chown=nwnx4:nwnx4 nwn2.reg /opt/

# Fix to ALSA configuration
COPY --chown=nwnx4:nwnx4 .asoundrc $NWNX4_USER_HOME

USER nwnx4:nwnx4

RUN mkdir -p "$WINEPREFIX/drive_c/users/nwnx4/Temp/NWN2" \
    && ln -s /srv/nwn2-logs "$WINEPREFIX/drive_c/users/nwnx4/Temp/NWN2/LOGS.0"

VOLUME "/srv/nwn2-logs"

USER root

RUN mkdir -p /etc/nwnx4/plugins \
    && chown -R nwnx4:nwnx4 /etc/nwnx4

# Setup release
ARG RELEASE_URL="https://github.com/nwn2dev/nwnx4/releases/latest/download/nwnx4.zip"

RUN wget $RELEASE_URL -O nwnx4.zip \
    && unzip nwnx4.zip -d /opt \
    && chown -R nwnx4:nwnx4 /opt/nwnx4

EXPOSE 5121/udp

COPY --chmod=+x docker-entrypoint.sh /

WORKDIR /srv/nwnx4-user
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["wine", "/opt/nwnx4/NWNX4_Controller.exe", "-interactive", "-verbose"]

ENV WINEDLLOVERRIDES="${WINEDLLOVERRIDES};granny2,mss32=n"
