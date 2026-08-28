# Overlay image: official apache/tika "-full" + Chinese OCR packs.
#
# We deliberately do NOT rebuild Tika from scratch. The upstream images carry
# the correct entrypoint, user (TIKA-3912 uid/gid), and packaging for each Tika
# generation (3.x fat jar vs 4.x thin jar + lib/ + plugins/) - inheriting them
# avoids re-implementing that per release. This layer only adds:
#   - tesseract-ocr-chi-sim / tesseract-ocr-chi-tra (Debian use hyphenated
#     suffixes; Tesseract codes stay chi_sim / chi_tra)
#   - fonts-noto-cjk so CJK pages rasterise without tofu blocks before OCR
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

# Same non-root uid/gid as the upstream images
USER 35002:35002

LABEL org.opencontainers.image.title="Apache Tika Server (full + Chinese OCR)" \
      org.opencontainers.image.description="apache/tika -full image with Tesseract chi_sim/chi_tra and Noto CJK fonts" \
      org.opencontainers.image.base.name="docker.io/apache/tika"
