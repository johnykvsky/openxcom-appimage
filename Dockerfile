FROM ubuntu:20.04 as base 

# Add package repositories
RUN set -e \
  && apt-get update \
  && apt-get install -y software-properties-common

# Install development tools and libraries
RUN set -e \
  && apt-get update \
  && apt-get install -y \
    nano \
    wget \
    curl \
    git \
    build-essential \
    doxygen \
    libsdl1.2-dev \
    libsdl-gfx1.2-dev \
    libsdl-image1.2-dev \
    libsdl-mixer1.2-dev \
    libyaml-cpp-dev \
    libboost-dev \
    libfuse2 \
    appstream \
    gnupg2 \
    file \
    ccache

# Install CMake
RUN set -e \
  && wget https://cmake.org/files/v3.28/cmake-3.28.1-linux-x86_64.sh \
  && sh cmake-3.28.1-linux-x86_64.sh --prefix=/usr/local --exclude-subdir \
  && rm -f cmake-3.28.1-linux-x86_64.sh

RUN set -e \
  && mkdir openxcom \
  && mkdir openxcom/scripts

ADD scripts /openxcom/scripts

# Install updated Transifex Client
RUN set -e \
  && wget https://github.com/transifex/cli/releases/download/v1.6.10/tx-linux-amd64.tar.gz \
  && tar -xvzf tx-linux-amd64.tar.gz tx \
  && rm tx-linux-amd64.tar.gz \
  && mv tx /usr/local/bin

# Prepend ccache into the PATH
ENV PATH="${PATH}:/usr/bin/ccache"
