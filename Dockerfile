FROM python:3.11.0a1-alpine3.14 as builder

# Building the necessary package for whoogle
RUN set -ex; \
    apk add --no-cache \
        build-base \
        openssl-dev \
        libxml2-dev \
        libxslt-dev \
        libffi-dev \
        git
RUN set -ex; \
    git clone https://github.com/benbusby/whoogle-search.git
WORKDIR whoogle-search
RUN set -ex; \
    pip install --prefix /install --no-warn-script-location --no-cache-dir -r requirements.txt

FROM python:3.11.0a1-alpine3.14

# Install requirements; supervisor is used to launch tor and whoogle
RUN set -ex; \
    apk add --no-cache \
        supervisor \
        curl-dev \
        tor \
        torsocks \
        bash \
        curl
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create whoogle user
ENV UID="1000"
ENV GID="1000"
ENV USERN="whoogle"
ENV HOMEN="/home/$USERN"

# Container will be run as $USERN user, we use gosu to do root job
# From gosu, https://github.com/tianon/gosu/blob/master/INSTALL.md
ENV GOSU_VERSION 1.14
RUN set -eux; \
    apk add --no-cache --virtual .gosu-deps \
        ca-certificates \
        dpkg \
        gnupg; \
        dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
        wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
        wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
    # verify the signature
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
    command -v gpgconf && gpgconf --kill all || :; \
    rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
    # clean up fetch dependencies
    apk del --no-network .gosu-deps; \
    chmod +x /usr/local/bin/gosu; \
    # verify that the binary works
    gosu --version; \
    gosu nobody true

# whoogle app environments 
ARG config_dir="${HOMEN}"/config
RUN mkdir -p "${config_dir}"
ENV CONFIG_VOLUME="${config_dir}"

ARG username=''
ENV WHOOGLE_USER="${username}"
ARG password=''
ENV WHOOGLE_PASS="${password}"

ARG proxyuser=''
ENV WHOOGLE_PROXY_USER="${proxyuser}"
ARG proxypass=''
ENV WHOOGLE_PROXY_PASS="${proxypass}"
ARG proxytype=''
ENV WHOOGLE_PROXY_TYPE="${proxytype}"
ARG proxyloc=''
ENV WHOOGLE_PROXY_LOC="${proxyloc}"

ARG whoogle_dotenv=''
ENV WHOOGLE_DOTENV="${whoogle_dotenv}"

ARG use_https=''
ENV HTTPS_ONLY="${use_https}"

ARG whoogle_port=5000
ENV EXPOSE_PORT="${whoogle_port}"

ARG twitter_alt='nitter.net'
ENV WHOOGLE_ALT_TW="${twitter_alt}"
ARG youtube_alt='invidious.snopyta.org'
ENV WHOOGLE_ALT_YT="${youtube_alt}"
ARG instagram_alt='bibliogram.art/u'
ENV WHOOGLE_ALT_IG="${instagram_alt}"
ARG reddit_alt='libredd.it'
ENV WHOOGLE_ALT_RD="${reddit_alt}"
ARG translate_alt='lingva.ml'
ENV WHOOGLE_ALT_TL="${translate_alt}"

# The built dependencies and the app itself
COPY --from=builder /install /usr/local
COPY --from=builder /whoogle-search "${HOMEN}"/whoogle

WORKDIR "${HOMEN}"/whoogle

RUN set -ex; \
    cp misc/tor/torrc /etc/tor/torrc

# Let's go!
COPY docker-entrypoint.sh /usr/bin
RUN chmod +x /usr/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
