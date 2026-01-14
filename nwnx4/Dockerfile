# Stable image
FROM nwn2dev/nwnx4:v1.3.1-stable

ARG NWNX4_USER_HOME="/home/nwnx4"

# Setup NWN2 stage and registry overrides
COPY --chown=nwnx4:nwnx4 nwn2-stage /opt/nwn2-stage
COPY --chown=nwnx4:nwnx4 nwn2.reg /opt/

# Fix to ALSA configuration
COPY --chown=nwnx4:nwnx4 .asoundrc $NWNX4_USER_HOME

USER root

# Copy docker-entrypoint.sh
COPY --chmod=+x docker-entrypoint.sh /

# Setup release
ARG RELEASE_URL="https://github.com/nwn2dev/nwnx4/releases/latest/download/nwnx4.zip"

RUN rm -fr /opt/nwnx4 \
    && wget $RELEASE_URL -O nwnx4.zip \
    && unzip nwnx4.zip -d /opt \
    && chown -R nwnx4:nwnx4 /opt/nwnx4
