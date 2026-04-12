FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        latexmk \
        texlive-lang-japanese \
        texlive-latex-extra \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

CMD ["bash"]
