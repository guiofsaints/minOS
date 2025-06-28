#!/bin/bash
# NextUI Build Helper Script
# Este script facilita o build do NextUI usando Docker

set -e

# Configurações padrão
PLATFORM=${PLATFORM:-tg5040}
COMPILE_CORES=${COMPILE_CORES:-true}
TARGET=${TARGET:-all}
DOCKER_IMAGE="nextui-build"

# Função para mostrar ajuda
show_help() {
    echo "NextUI Build Helper"
    echo "Usage: $0 [OPTIONS] [TARGET]"
    echo ""
    echo "OPTIONS:"
    echo "  -p, --platform PLATFORM    Target platform (default: tg5040)"
    echo "  -c, --cores                 Compile cores (default: true)"
    echo "  -h, --help                  Show this help"
    echo ""
    echo "TARGETS:"
    echo "  all                         Build everything (default)"
    echo "  cores                       Build only cores"
    echo "  clean                       Clean build files"
    echo "  shell                       Open interactive shell"
    echo ""
    echo "SUPPORTED PLATFORMS:"
    echo "  tg5040                      TrimUI Smart Pro (default)"
    echo "  trimuismart                 TrimUI Smart (if toolchain available)"
    echo ""
    echo "EXAMPLES:"
    echo "  $0                          # Build everything for tg5040"
    echo "  $0 -p tg5040 cores          # Build only cores for tg5040"
    echo "  $0 shell                    # Open interactive shell"
    echo "  $0 clean                    # Clean build files"
}

# Parse argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        -c|--cores)
            COMPILE_CORES="true"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        shell|clean|all|cores)
            TARGET="$1"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Verificar se workspace existe
if [ ! -d "workspace" ]; then
    echo "Error: workspace directory not found. Please run this script from the NextUI root directory."
    exit 1
fi

echo "================================================"
echo "NextUI Build Helper"
echo "Platform: $PLATFORM"
echo "Compile Cores: $COMPILE_CORES"
echo "Target: $TARGET"
echo "================================================"

# Construir imagem Docker se não existir
if ! docker image inspect $DOCKER_IMAGE > /dev/null 2>&1; then
    echo "Building Docker image..."
    docker build -t $DOCKER_IMAGE .
fi

# Executar build
case $TARGET in
    shell)
        echo "Opening interactive shell..."
        docker run -it --rm \
            -v "$(pwd)/workspace:/root/workspace" \
            -e PLATFORM=$PLATFORM \
            -e COMPILE_CORES=$COMPILE_CORES \
            $DOCKER_IMAGE /bin/bash
        ;;
    *)
        echo "Starting build..."
        docker run --rm \
            -v "$(pwd)/workspace:/root/workspace" \
            -e PLATFORM=$PLATFORM \
            -e COMPILE_CORES=$COMPILE_CORES \
            -e TARGET=$TARGET \
            $DOCKER_IMAGE /root/build.sh
        ;;
esac

echo "Done!"
