# NextUI Build Environment Dockerfile
# Base para compilar o NextUI para diferentes plataformas

FROM debian:buster-slim
ENV DEBIAN_FRONTEND=noninteractive

# Configurar timezone
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Instalar dependências base
RUN apt-get -y update && apt-get -y install \
    bc \
    build-essential \
    bzip2 \
    bzr \
    cmake \
    cmake-curses-gui \
    cpio \
    curl \
    git \
    libncurses5-dev \
    libsamplerate0-dev \
    liblzma-dev \
    libzstd-dev \
    libbz2-dev \
    zlib1g-dev \
    locales \
    make \
    rsync \
    scons \
    tree \
    unzip \
    wget \
    python3 \
    python3-pip \
    pkg-config \
    autoconf \
    automake \
    libtool \
    patch \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Configurar locale
RUN sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

# Criar diretório de trabalho
RUN mkdir -p /root/workspace
WORKDIR /root

# Script para baixar e configurar toolchain automaticamente
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Detectar arquitetura\n\
ARCH=$(uname -m)\n\
PLATFORM=${PLATFORM:-tg5040}\n\
\n\
# Configurar toolchain baseado na plataforma\n\
case $PLATFORM in\n\
    tg5040)\n\
        TOOLCHAIN_NAME="aarch64-linux-gnu"\n\
        TOOLCHAIN_TAR="gcc-arm-8.3-2019.02-x86_64-aarch64-linux-gnu"\n\
        TOOLCHAIN_URL="https://developer.arm.com/-/media/Files/downloads/gnu-a/8.3-2019.02/$TOOLCHAIN_TAR.tar.xz"\n\
        SYSROOT_TAR="SDK_usr_tg5040_a133p"\n\
        SYSROOT_URL="https://github.com/trimui/toolchain_sdk_smartpro/releases/download/20231018/$SYSROOT_TAR.tgz"\n\
        ;;\n\
    trimuismart)\n\
        echo "TrimUI Smart toolchain setup"\n\
        # Aqui poderia ser adicionado suporte para TrimUI Smart se disponível\n\
        ;;\n\
    *)\n\
        echo "Platform $PLATFORM not supported"\n\
        exit 1\n\
        ;;\n\
esac\n\
\n\
# Baixar e instalar toolchain apenas se não estiver instalado\n\
if [ ! -d "/opt/$TOOLCHAIN_NAME" ] && [ "$ARCH" != "aarch64" ]; then\n\
    echo "Setting up cross-compilation toolchain for $PLATFORM..."\n\
    \n\
    # Baixar toolchain\n\
    if [ ! -f "$TOOLCHAIN_TAR.tar.xz" ]; then\n\
        wget -q "$TOOLCHAIN_URL" || { echo "Failed to download toolchain"; exit 1; }\n\
    fi\n\
    \n\
    # Extrair toolchain\n\
    tar xf "$TOOLCHAIN_TAR.tar.xz" -C /opt\n\
    mv "/opt/$TOOLCHAIN_TAR" "/opt/$TOOLCHAIN_NAME"\n\
    rm -f "$TOOLCHAIN_TAR.tar.xz"\n\
    \n\
    # Baixar e instalar sysroot\n\
    if [ -n "$SYSROOT_URL" ]; then\n\
        wget -q "$SYSROOT_URL" || { echo "Failed to download sysroot"; exit 1; }\n\
        tar xf "$SYSROOT_TAR.tgz"\n\
        rsync -a --ignore-existing ./usr/ "/opt/$TOOLCHAIN_NAME/$TOOLCHAIN_NAME/libc/usr/"\n\
        rm -rf ./usr "$SYSROOT_TAR.tgz"\n\
    fi\n\
    \n\
    echo "Toolchain setup completed"\n\
elif [ "$ARCH" = "aarch64" ]; then\n\
    echo "Native compilation on aarch64"\n\
    # Para compilação nativa, baixar apenas sysroot se necessário\n\
    if [ -n "$SYSROOT_URL" ]; then\n\
        wget -q "$SYSROOT_URL" || echo "Warning: Failed to download sysroot"\n\
        if [ -f "$SYSROOT_TAR.tgz" ]; then\n\
            tar xf "$SYSROOT_TAR.tgz"\n\
            rsync -a --ignore-existing ./usr/ /usr/\n\
            rm -rf ./usr "$SYSROOT_TAR.tgz"\n\
        fi\n\
    fi\n\
else\n\
    echo "Toolchain already installed"\n\
fi\n\
' > /root/setup-toolchain.sh && chmod +x /root/setup-toolchain.sh

# Script para configurar ambiente
RUN echo '#!/bin/bash\n\
PLATFORM=${PLATFORM:-tg5040}\n\
ARCH=$(uname -m)\n\
\n\
case $PLATFORM in\n\
    tg5040)\n\
        if [ "$ARCH" != "aarch64" ]; then\n\
            export PATH="/opt/aarch64-linux-gnu/bin:$PATH"\n\
            export CROSS_COMPILE="aarch64-linux-gnu-"\n\
            export CC="aarch64-linux-gnu-gcc"\n\
            export CXX="aarch64-linux-gnu-g++"\n\
            export AR="aarch64-linux-gnu-ar"\n\
            export STRIP="aarch64-linux-gnu-strip"\n\
            export PKG_CONFIG_PATH="/opt/aarch64-linux-gnu/aarch64-linux-gnu/libc/usr/lib/pkgconfig"\n\
        else\n\
            export CROSS_COMPILE=""\n\
            export CC="gcc"\n\
            export CXX="g++"\n\
        fi\n\
        ;;\n\
esac\n\
\n\
export PLATFORM\n\
' > /root/setup-env.sh

# Adicionar ambiente ao bashrc
RUN echo 'source /root/setup-env.sh' >> /root/.bashrc

# Script de build personalizado com melhor tratamento de erros
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
PLATFORM=${PLATFORM:-tg5040}\n\
COMPILE_CORES=${COMPILE_CORES:-true}\n\
TARGET=${TARGET:-all}\n\
\n\
echo "================================================"\n\
echo "NextUI Build Script"\n\
echo "Platform: $PLATFORM"\n\
echo "Compile Cores: $COMPILE_CORES"\n\
echo "Target: $TARGET"\n\
echo "================================================"\n\
\n\
# Configurar toolchain\n\
/root/setup-toolchain.sh\n\
\n\
# Configurar ambiente\n\
source /root/setup-env.sh\n\
\n\
# Navegar para workspace\n\
cd /root/workspace\n\
\n\
# Verificar se makefile existe\n\
if [ ! -f "makefile" ]; then\n\
    echo "Error: makefile not found in workspace"\n\
    exit 1\n\
fi\n\
\n\
# Executar build\n\
echo "Starting build..."\n\
case $TARGET in\n\
    all)\n\
        make PLATFORM=$PLATFORM COMPILE_CORES=$COMPILE_CORES\n\
        ;;\n\
    cores)\n\
        make PLATFORM=$PLATFORM cores\n\
        ;;\n\
    clean)\n\
        make PLATFORM=$PLATFORM clean\n\
        ;;\n\
    *)\n\
        make PLATFORM=$PLATFORM $TARGET\n\
        ;;\n\
esac\n\
\n\
echo "Build completed successfully!"\n\
' > /root/build.sh && chmod +x /root/build.sh

# Configurar libzip mais recente (necessário para algumas funcionalidades)
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "Building libzip from source..."\n\
\n\
# Baixar libzip\n\
cd /tmp\n\
wget -q https://libzip.org/download/libzip-1.8.0.tar.xz\n\
tar xf libzip-1.8.0.tar.xz\n\
cd libzip-1.8.0\n\
\n\
# Configurar e compilar\n\
mkdir build\n\
cd build\n\
cmake -DCMAKE_INSTALL_PREFIX=/usr ..\n\
make -j$(nproc)\n\
make install\n\
\n\
# Limpeza\n\
cd /\n\
rm -rf /tmp/libzip-*\n\
\n\
echo "libzip build completed"\n\
' > /root/build-libzip.sh && chmod +x /root/build-libzip.sh

# Compilar libzip
RUN /root/build-libzip.sh

# Volume para o workspace
VOLUME /root/workspace
WORKDIR /root/workspace

# Comando padrão
CMD ["/bin/bash"]

# Labels para metadados
LABEL maintainer="NextUI Build Environment"
LABEL description="Container para compilar NextUI para diferentes plataformas"
LABEL version="1.0"

# Exemplo de uso:
# docker build -t nextui-build .
# docker run -it --rm -v $(pwd)/workspace:/root/workspace -e PLATFORM=tg5040 nextui-build /root/build.sh
