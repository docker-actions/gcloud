ARG ROOTFS=/build/rootfs

FROM ubuntu:bionic as build

ARG REQUIRED_PACKAGES=""
ARG IMAGE_NAME=""
ARG ROOTFS

ENV BUILD_DEBS /build/debs
ENV DEBIAN_FRONTEND noninteractive
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE true

RUN : "${IMAGE_NAME:?Build argument needs to be set and non-empty.}"
RUN : "${ROOTFS:?Build argument needs to be set and non-empty.}"

SHELL ["bash", "-Eeuc"]

# Build pre-requisites
RUN mkdir -p ${BUILD_DEBS} ${ROOTFS}/{sbin,usr/local/bin}

# Fix permissions
RUN chown -Rv 100:root $BUILD_DEBS

# Install pre-requisites
RUN set -Eeuo pipefail; \
    apt-get update; \
    apt-get -y install apt-utils curl lsb-release gnupg; \
    export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"; \
    echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list; \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

# Unpack required packges to rootfs
RUN set -Eeuo pipefail; \
    apt-get update; \
    cd ${BUILD_DEBS}; \
    for pkg in $REQUIRED_PACKAGES; do \
      apt-get download $pkg; \
      apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances --no-pre-depends -i $pkg | grep '^[a-zA-Z0-9]' | xargs apt-get download ; \
    done; \
    if [ "x$(ls ${BUILD_DEBS}/)" = "x" ]; then \
      echo No required packages specified; \
    else \
      for pkg in ${BUILD_DEBS}/*.deb; do \
        echo Unpacking $pkg; \
        dpkg-deb -x $pkg ${ROOTFS}; \
      done; \
    fi

# Move /sbin out of the way
RUN set -Eeuo pipefail; \
    mv ${ROOTFS}/sbin ${ROOTFS}/sbin.orig; \
    mkdir -p ${ROOTFS}/sbin; \
    for b in ${ROOTFS}/sbin.orig/*; do \
      echo 'cmd=$(basename ${BASH_SOURCE[0]}); exec /sbin.orig/$cmd "$@"' > ${ROOTFS}/sbin/$(basename $b); \
      chmod +x ${ROOTFS}/sbin/$(basename $b); \
    done

RUN ln -s python2.7 ${ROOTFS}/usr/bin/python2

COPY ${IMAGE_NAME}.entrypoint.sh ${ROOTFS}/usr/local/bin/entrypoint.sh
RUN chmod +x ${ROOTFS}/usr/local/bin/entrypoint.sh

FROM actions/bash:4.4.18-8
LABEL maintainer = "ilja+docker@bobkevic.com"

ARG ROOTFS
RUN : "${ROOTFS:?Build argument needs to be set and non-empty.}"

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

COPY --from=build ${ROOTFS} /

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
