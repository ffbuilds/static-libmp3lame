
# bump: mp3lame /MP3LAME_VERSION=([\d.]+)/ svn:http://svn.code.sf.net/p/lame/svn|/^RELEASE__(.*)$/|/_/./|*
# bump: mp3lame after ./hashupdate Dockerfile MP3LAME $LATEST
# bump: mp3lame link "ChangeLog" http://svn.code.sf.net/p/lame/svn/trunk/lame/ChangeLog
ARG MP3LAME_VERSION=3.100
ARG MP3LAME_URL="https://sourceforge.net/projects/lame/files/lame/$MP3LAME_VERSION/lame-$MP3LAME_VERSION.tar.gz/download"
ARG MP3LAME_SHA256=ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e

# Must be specified
ARG ALPINE_VERSION

FROM alpine:${ALPINE_VERSION} AS base

FROM base AS download
ARG MP3LAME_URL
ARG MP3LAME_SHA256
ARG WGET_OPTS="--retry-on-host-error --retry-on-http-error=429,500,502,503 -nv"
WORKDIR /tmp
RUN \
  apk add --no-cache --virtual download \
    coreutils wget tar && \
  wget $WGET_OPTS -O lame.tar.gz "$MP3LAME_URL" && \
  echo "$MP3LAME_SHA256  lame.tar.gz" | sha256sum --status -c - && \
  mkdir lame && \
  tar xf lame.tar.gz -C lame --strip-components=1 && \
  rm lame.tar.gz && \
  apk del download

FROM base AS build
COPY --from=download /tmp/lame/ /tmp/lame/
WORKDIR /tmp/lame
RUN \
  apk add --no-cache --virtual build \
    build-base nasm && \
  ./configure --disable-shared --enable-static --enable-nasm --disable-gtktest --disable-cpml --disable-frontend && \
  make -j$(nproc) install && \
  # Sanity tests
  ar -t /usr/local/lib/libmp3lame.a && \
  readelf -h /usr/local/lib/libmp3lame.a && \
  # Cleanup
  apk del build

FROM scratch
ARG MP3LAME_VERSION
COPY --from=build /usr/local/lib/libmp3lame.a /usr/local/lib/libmp3lame.a
COPY --from=build /usr/local/include/lame/ /usr/local/include/lame/
