# NextUI Docker Build Environment

Este Dockerfile fornece um ambiente completo para compilar o NextUI para diferentes plataformas de dispositivos embarcados.

## Características

- **Multi-plataforma**: Suporte para tg5040 (TrimUI Smart Pro) e outras plataformas
- **Toolchain automático**: Download e configuração automática de cross-compilers
- **Dependências incluídas**: Todas as bibliotecas e ferramentas necessárias
- **Scripts auxiliares**: Simplificam o processo de build

## Uso Rápido

### 1. Build da imagem Docker
```bash
docker build -t nextui-build .
```

### 2. Build do NextUI
```bash
# Build completo para tg5040 (padrão)
docker run --rm -v $(pwd)/workspace:/root/workspace nextui-build /root/build.sh

# Build para plataforma específica
docker run --rm -v $(pwd)/workspace:/root/workspace -e PLATFORM=tg5040 nextui-build /root/build.sh

# Build apenas cores
docker run --rm -v $(pwd)/workspace:/root/workspace -e TARGET=cores nextui-build /root/build.sh
```

### 3. Shell interativo
```bash
docker run -it --rm -v $(pwd)/workspace:/root/workspace nextui-build
```

## Usando o Script Helper

O script `build.sh` simplifica o uso:

```bash
# Dar permissão de execução (Linux/macOS)
chmod +x build.sh

# Build completo
./build.sh

# Build para plataforma específica
./build.sh -p tg5040

# Build apenas cores
./build.sh cores

# Shell interativo
./build.sh shell

# Limpar build
./build.sh clean

# Ajuda
./build.sh --help
```

## Usando Docker Compose

```bash
# Build automático
docker-compose up nextui-auto-build

# Shell interativo
docker-compose run nextui-build

# Com variáveis de ambiente
PLATFORM=tg5040 COMPILE_CORES=true docker-compose up nextui-auto-build
```

## Plataformas Suportadas

- **tg5040**: TrimUI Smart Pro (padrão)
- **trimuismart**: TrimUI Smart (se toolchain disponível)

## Variáveis de Ambiente

- `PLATFORM`: Plataforma alvo (padrão: tg5040)
- `COMPILE_CORES`: Compilar cores (padrão: true)
- `TARGET`: Alvo do build (all, cores, clean)

## Estrutura do Container

```
/root/
├── workspace/          # Volume montado do projeto
├── setup-toolchain.sh  # Script para configurar toolchain
├── setup-env.sh        # Script para configurar ambiente
├── build.sh           # Script principal de build
└── build-libzip.sh    # Script para compilar libzip
```

## Troubleshooting

### Erro de toolchain não encontrado
O container baixa automaticamente o toolchain. Se houver erro:
```bash
# Execute manualmente dentro do container
docker run -it --rm nextui-build /root/setup-toolchain.sh
```

### Erro de permissões
No Linux/macOS, certifique-se que o diretório workspace tem as permissões corretas:
```bash
sudo chown -R $(id -u):$(id -g) workspace/
```

### Build falha
Verifique se todas as dependências estão no workspace:
```bash
# Liste conteúdo do workspace
docker run --rm -v $(pwd)/workspace:/root/workspace nextui-build ls -la /root/workspace
```

## Personalização

### Adicionar nova plataforma
1. Edite o script `/root/setup-toolchain.sh` no Dockerfile
2. Adicione a configuração da nova plataforma
3. Rebuild a imagem Docker

### Modificar dependências
1. Edite a seção de instalação de pacotes no Dockerfile
2. Rebuild a imagem Docker

## Notas

- O primeiro build baixa o toolchain (~500MB) e pode demorar mais
- Toolchains são cacheados entre builds
- Use volumes Docker para persistir toolchains se necessário
- Para builds em produção, considere criar uma imagem com toolchain pré-instalado
