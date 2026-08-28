# Overlay image: official apache/tika "-full" + Chinese OCR packs.
#
# We deliberately do NOT rebuild Tika from scratch. The upstream images carry
# the correct entrypoint, user (TIKA-3912 uid/gid), and packaging for each Tika
# generation (3.x fat jar vs 4.x thin jar + lib/ + plugins/) - inheriting them
# avoids re-implementing that per release. This layer only adds:
#   - tesseract-ocr-chi-sim / tesseract-ocr-chi-tra (Debian use hyphenated
#     suffixes; Tesseract codes stay chi_sim / chi_tra)
#   - fonts-noto-cjk so CJK pages rasterise without tofu blocks before OCR
#   - a default OCR config baked to match the BASE_IMAGE major version and
#     wired in via CMD (see the COPY/RUN/CMD lines below).
#
# Build:
#   docker build --build-arg BASE_IMAGE=apache/tika:3.3.0.0-full -t tika-ocr-zh:3.3.0.0 .
#   docker build --build-arg BASE_IMAGE=apache/tika:4.0.0.0-full -t tika-ocr-zh:4.0.0.0 .

ARG BASE_IMAGE=docker.io/apache/tika:4.0.0.0-full

FROM ${BASE_IMAGE}

USER root

RUN set -eux \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
        tesseract-ocr-chi-sim \
        tesseract-ocr-chi-tra \
        fonts-noto-cjk \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Bake the generation-appropriate default config. 3.x expects XML tika-config
# (JSON config support only landed in 4.x, TIKA-4544), and 4.x in turn stopped
# loading classpath TesseractOCRConfig.properties (TIKA-4842). Both parsers
# detect the format from the *content*, not the filename, so whichever
# generation's config we select is always written to the fixed path
# /tika-config.json and the static CMD below stays valid for both.
# TIKA_VERSION is an ENV baked into the upstream images, so it is readable
# here without passing any build-arg.
COPY config/tika-config-4.json /tmp/tika-config-4.json
COPY config/tika-config-3.xml /tmp/tika-config-3.xml
RUN set -eux \
    && upstream_major="$(echo "${TIKA_VERSION}" | cut -d. -f1)" \
    && if [ "${upstream_major}" = "4" ]; then \
           cp /tmp/tika-config-4.json /tika-config.json; \
       else \
           cp /tmp/tika-config-3.xml /tika-config.json; \
       fi \
    && rm -f /tmp/tika-config-4.json /tmp/tika-config-3.xml \
    && chown 35002:35002 /tika-config.json

# Default args appended to the upstream ENTRYPOINT. Overridden entirely when
# the user passes their own command (e.g. -c /my-config.json).
CMD ["-c", "/tika-config.json"]

# Same non-root uid/gid as the upstream images
USER 35002:35002

LABEL org.opencontainers.image.title="Apache Tika Server (full + Chinese OCR)" \
      org.opencontainers.image.description="apache/tika -full image with Tesseract chi_sim/chi_tra and Noto CJK fonts" \
      org.opencontainers.image.base.name="docker.io/apache/tika"
