FROM node:22-bookworm-slim AS base

# Install locales and necessary packages
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    locales curl jq apt-transport-https gnupg ca-certificates unzip \
    git neovim libicu-dev openssh-client \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set the locale to en_GB.UTF-8
RUN echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
ENV LANG=en_GB.UTF-8
ENV LANGUAGE=en_GB.UTF-8
ENV LC_ALL=en_GB.UTF-8

# install gcloud cli
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/cloud.google.gpg && \
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-get update && apt-get install -y google-cloud-cli

# oh-my-posh install
RUN curl -s https://ohmyposh.dev/install.sh | bash -s

COPY ./.bashrc ~/.bashrc


