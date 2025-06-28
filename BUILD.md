# NextUI Build Documentation

## Visão Geral

O NextUI é um Custom Firmware (CFW) baseado no MinUI para dispositivos de jogos portáteis retro, principalmente da família TrimUI (Brick/Smart Pro). Este documento detalha o processo completo de build do sistema.

## Arquitetura do Sistema de Build

### Estrutura de Diretórios
```
NextUI/
├── makefile                    # Makefile principal (host system)
├── makefile.native            # Build nativo (desktop)
├── makefile.toolchain         # Cross-compilation (Docker)
├── workspace/                 # Código fonte dos componentes
│   ├── all/                   # Componentes cross-platform
│   │   ├── nextui/           # UI principal (~2800 LOC)
│   │   ├── minarch/          # Engine de emulação (~7100 LOC)
│   │   ├── settings/         # Sistema de configuração (C++)
│   │   ├── common/           # APIs e bibliotecas compartilhadas
│   │   └── cores/            # Cores dos emuladores (libretro)
│   ├── desktop/              # Plataforma de desenvolvimento
│   └── tg5040/              # Hardware específico (TrimUI)
├── skeleton/                 # Template da estrutura final
├── build/                    # Output temporário do build
└── releases/                 # Arquivos finais (.zip)
```

## Plataformas Suportadas

- **tg5040**: TrimUI Brick/Smart Pro (ARM64)
- **desktop**: Desenvolvimento e testes (x86_64)

## Processo de Build

### 1. Configuração Inicial (`make setup`)

```bash
# Remove builds anteriores
rm -rf ./build

# Cria estrutura base a partir do skeleton
cp -R ./skeleton ./build

# Remove arquivos de desenvolvimento
find . -name '.keep' -delete
find . -name '*.meta' -delete

# Gera hash do commit atual
echo $(BUILD_HASH) > ./workspace/hash.txt

# Prepara READMEs para formatação
mkdir -p ./workspace/readmes
cp ./skeleton/BASE/README.txt ./workspace/readmes/BASE-in.txt
cp ./skeleton/EXTRAS/README.txt ./workspace/readmes/EXTRAS-in.txt
```

### 2. Build dos Componentes (`make build`)

#### Componentes Principais:
- **nextui.elf**: Interface principal do usuário
- **minarch.elf**: Engine de emulação
- **settings.elf**: Menu de configurações
- **libmsettings.so**: Biblioteca de configurações de hardware

#### Utilitários:
- **clock.elf**: Aplicativo de relógio
- **battery.elf**: Monitor de bateria
- **gametime.elf**: Rastreamento de tempo de jogo
- **ledcontrol.elf**: Controle de LEDs (TrimUI específico)

### 3. Build dos Cores (`make build-cores`)

#### Cores Essenciais (Estáveis):
```bash
# Nintendo/Famicom
make build-core PLATFORM=tg5040 CORE=fceumm

# Game Boy/Game Boy Color
make build-core PLATFORM=tg5040 CORE=gambatte

# Game Boy Advance
make build-core PLATFORM=tg5040 CORE=gpsp
make build-core PLATFORM=tg5040 CORE=mgba

# Sega Genesis/Master System
make build-core PLATFORM=tg5040 CORE=picodrive

# Super Nintendo
make build-core PLATFORM=tg5040 CORE=snes9x

# PlayStation 1
make build-core PLATFORM=tg5040 CORE=pcsx_rearmed
```

#### Cores Extras (Podem ter problemas):
- **fake-08**: PICO-8 (requer dependências específicas)
- **fbneo**: Arcade
- **vice_***: Commodore (C64, C128, VIC-20, etc.)
- **mednafen_***: Múltiplos sistemas

### 4. Instalação do Sistema (`make system`)

```bash
# Copia executáveis para SYSTEM/tg5040/bin/
cp nextui.elf minarch.elf settings.elf [...]

# Copia bibliotecas para SYSTEM/tg5040/lib/
cp libmsettings.so libbatmondb.so [...]

# Copia ferramentas para EXTRAS/Tools/
cp clock.elf battery.elf gametime.elf [...]
```

### 5. Instalação dos Cores (`make cores`)

```bash
# Cores principais (SYSTEM/tg5040/cores/)
cp fceumm_libretro.so
cp gambatte_libretro.so
cp gpsp_libretro.so
[...]

# Cores extras (EXTRAS/Emus/tg5040/)
cp mgba_libretro.so EXTRAS/Emus/tg5040/MGBA.pak/
cp fake08_libretro.so EXTRAS/Emus/tg5040/P8.pak/
[...]
```

### 6. Empacotamento (`make package`)

```bash
# Cria estrutura de payload
mkdir -p ./build/PAYLOAD
mv ./build/SYSTEM ./build/PAYLOAD/.system
cp -R ./build/BOOT/.tmp_update ./build/PAYLOAD/
cp -R ./build/EXTRAS/Tools ./build/PAYLOAD/

# Compacta em MinUI.zip
cd ./build/PAYLOAD && zip -r MinUI.zip .system .tmp_update Tools

# Gera releases finais
zip $(RELEASE_NAME)-base.zip     # Sistema base
zip $(RELEASE_NAME)-extras.zip   # Emuladores e ferramentas extras  
zip $(RELEASE_NAME)-all.zip      # Pacote completo
```

## Comandos de Build

### Build Completo (Recomendado)
```bash
# Build completo com cores essenciais
make full-build PLATFORM=tg5040

# Ou passo a passo:
make setup
make build-all-safe PLATFORM=tg5040
make special
make package
make done
```

### Build Apenas do Sistema (Sem Cores)
```bash
make tg5040
```

### Build Específico de Cores
```bash
# Todos os cores (pode falhar em alguns)
make build-cores PLATFORM=tg5040

# Apenas cores estáveis
make build-essential-cores PLATFORM=tg5040

# Core individual
make build-core PLATFORM=tg5040 CORE=fceumm
```

### Build de Desenvolvimento
```bash
# Shell interativo no container Docker
make shell PLATFORM=tg5040

# Build nativo para desenvolvimento
make desktop
```

## Configurações de Build

### Variáveis de Ambiente
```makefile
BUILD_HASH    = $(git rev-parse --short HEAD)
BUILD_BRANCH  = $(git rev-parse --abbrev-ref HEAD)
RELEASE_TIME  = $(date +%Y%m%d)
PLATFORM      = tg5040 | desktop
COMPILE_CORES = true | false
```

### Flags de Compilação (tg5040)
```bash
CFLAGS = -march=armv8-a+simd -mtune=cortex-a53 -flto -O3 -Ofast
CFLAGS += -fomit-frame-pointer -ffast-math -funroll-loops
CFLAGS += -finline-functions -fno-strict-aliasing
CFLAGS += -DUSE_SDL2 -DUSE_GLES -DGL_GLEXT_PROTOTYPES
```

## Resolução de Problemas

### Erros Comuns

#### 1. Core fake-08 falha
```
Error: No rule to make target '../../libs/z8lua/eris.o'
```
**Solução**: Use `make build-essential-cores` ao invés de `make build-cores`

#### 2. Git ownership em Docker
```
fatal: detected dubious ownership in repository
```
**Solução**: Automaticamente resolvido com `git config --global --add safe.directory`

#### 3. Cores não encontrados
```
Warning: fceumm_libretro.so not found, skipping
```
**Solução**: Normal se cores não foram compilados. Use verificações condicionais.

### Debug e Logs

```bash
# Verbose build
make PLATFORM=tg5040 MAKEFLAGS=

# Verificar cores disponíveis
make cores-json PLATFORM=tg5040

# Status de um core específico
cd workspace/tg5040/cores && make status-fceumm
```

## Threading e Performance

### Arquitetura Multi-thread
- `main_ui_thread`: Interface principal
- `bg_load_thread`: Carregamento em background
- `anim_thread`: Worker de animações
- `audio_thread`: Processamento de áudio
- `cpu_monitor_thread`: Monitoramento de performance

### Otimizações
- **LTO (Link Time Optimization)**: `-flto`
- **CPU específico**: `-march=armv8-a+simd -mtune=cortex-a53`
- **Math otimizada**: `-ffast-math -funroll-loops`
- **Threading**: pthreads + SDL threads (6+ workers)

## Estrutura Final

### BASE/ (Sistema essencial)
```
BASE/
├── Bios/          # BIOS dos sistemas
├── Roms/          # ROMs organizadas por sistema
├── Saves/         # Save games
├── Shaders/       # Shaders de vídeo
├── trimui/        # Instalador específico do TrimUI
├── em_ui.sh       # Script de inicialização
├── MinUI.zip      # Payload principal
└── README.txt     # Instruções
```

### EXTRAS/ (Emuladores e ferramentas adicionais)
```
EXTRAS/
├── Emus/          # Cores extras por sistema
├── Tools/         # Ferramentas utilitárias
├── Overlays/      # Overlays gráficos
└── README.txt     # Instruções
```

## Dependências

### Sistema Host
- Docker (para cross-compilation)
- Git
- Make
- zip/zipmerge

### Container Docker
- GCC aarch64 cross-compiler
- SDL2, SDL2_image, SDL2_ttf
- OpenGL ES 2.0/3.0
- pkg-config
- libretro development headers

## Releases

### Versionamento
```
NextUI-YYYYMMDD[-branch]-increment
Exemplo: NextUI-20250628-main-1
```

### Tipos de Release
- **base.zip**: Sistema principal (mínimo funcional)
- **extras.zip**: Emuladores e ferramentas extras
- **all.zip**: Pacote completo (base + extras)
