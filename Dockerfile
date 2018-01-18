FROM alpine:3.7
MAINTAINER Disassembler <disassembler@dasm.cz>

RUN \
 # Install runtime dependencies
 apk --no-cache add \
    ffmpeg \
    imagemagick \
    imlib2 \
    libogg \
    libtheora \
    libvpx \
    libxml2 \
    libxslt \
    mkvtoolnix \
    nginx \
    poppler-utils \
    py3-psycopg2 \
    # py3-pillow \
    py3-numpy \
    py3-geoip \
    py3-lxml \
    python3 \
    s6 \
 && pip3 install \
    pyinotify \
    youtube-dl \
 && ln -s /usr/bin/python3 /usr/bin/python

RUN \
 # Install build dependencies
 apk --no-cache add --virtual .deps \
    autoconf \
    automake \
    build-base \
    flac-dev \
    git \
    imlib2-dev \
    libogg-dev \
    libtheora-dev \
    libtool \
    libvpx-dev \
    libvorbis-dev \
 # Compile liboggz
 && wget https://ftp.osuosl.org/pub/xiph/releases/liboggz/liboggz-1.1.1.tar.gz -O /tmp/liboggz.tgz \
 && tar xf /tmp/liboggz.tgz -C /tmp \
 && cd /tmp/liboggz-1.1.1 \
 && ./configure \
 && make -j $(nproc) \
 && make install \
 # Compile libfishsound
 && wget https://ftp.osuosl.org/pub/xiph/releases/libfishsound/libfishsound-1.0.0.tar.gz -O /tmp/libfishsound.tgz \
 && tar xf /tmp/libfishsound.tgz -C /tmp/ \
 && cd /tmp/libfishsound-1.0.0 \
 && ./configure \
 && make -j $(nproc) \
 && make install \
 # Compile liboggplay
 && git clone --depth 1 git://git.xiph.org/liboggplay.git /tmp/liboggplay \
 && cd /tmp/liboggplay \
 && ./autogen.sh \
 && ./configure \
 && make -j $(nproc) \
 && make install \
 # Compile oxframe (without man pages)
 && git clone --depth 1 https://code.0x2620.org/0x2620/oxframe /tmp/oxframe \
 && cd /tmp/oxframe \
 && sed -i '/man\/oxframe/d' Makefile \
 && make \
 && make install \
 && cd / \
 # Clone Pandora git repositories
 && git clone --depth 1 https://git.0x2620.org/pandora.git /srv/pandora \
 && git clone --depth 1 https://git.0x2620.org/oxjs.git /srv/pandora/static/oxjs \
 && git clone --depth 1 https://git.0x2620.org/python-ox.git /srv/pandora/src/python-ox \
 && git clone --depth 1 https://git.0x2620.org/oxtimelines.git /srv/pandora/src/oxtimelines \
 # Install python dependencies
 && pip3 install -e /srv/pandora/src/python-ox \
 && pip3 install -e /srv/pandora/src/oxtimelines \
 && pip3 install -r /srv/pandora/requirements.txt \
 # Clean build dependencies
 && apk del .deps \
 && find /srv/pandora -name '.git*' -exec rm -rf {} + \
 && rm -rf /tmp/lib* /tmp/oxframe \
 && rm -rf /root/.cache

# TODO: Remove whole following block once the item_icon.py gets fixed
# TODO: Otherwise, if pillow version gets listed in requirements.txt, incorporate following block to the blocks above
RUN \
 apk --no-cache add \
    freetype \
    libjpeg-turbo \
    zlib \
 && apk --no-cache add --virtual .deps \
    build-base \
    freetype-dev \
    libjpeg-turbo-dev \
    python3-dev \
    zlib-dev \
 && pip3 install "pillow<4.2.0" \
 && apk del .deps \
 && rm -rf /root/.cache

# TODO: Remove following block once the relative paths in extract.py get fixed
RUN \
 mkdir /srv/pandora/bin \
 && ln -s /usr/bin/oxtimelines /srv/pandora/bin/oxtimelines

RUN \
 # Enable default configuration
 cd /srv/pandora/pandora \
 && cp config.pandora.jsonc config.jsonc \
 && cp gunicorn_config.py.in gunicorn_config.py \
 # TODO: Remove following line once the get_version() is fixed
 && sed -i 's/version = get_version()/version = "unknown"/' /srv/pandora/static/oxjs/tools/build/build.py \
 # Compile pyc and static files
 && ./manage.py update_static \
 && ./manage.py compile_pyc -p /srv/pandora/pandora \
 && ./manage.py collectstatic -l --noinput

COPY docker/ /

VOLUME ["/srv/pandora/data"]
EXPOSE 80

CMD ["s6-svscan", "/etc/services.d"]
