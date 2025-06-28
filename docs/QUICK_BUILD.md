# NextUI - Guia Rápido de Build

## 🚀 Build Rápido (TL;DR)

```bash
# Build completo recomendado
make full-build PLATFORM=tg5040

# Ou se preferir passo a passo:
make setup
make build PLATFORM=tg5040
make build-essential-cores PLATFORM=tg5040  # Cores estáveis
make system PLATFORM=tg5040
make cores PLATFORM=tg5040
make special && make package && make done
```

## 📋 Comandos Essenciais

| Comando | Descrição |
|---------|-----------|
| `make full-build PLATFORM=tg5040` | Build completo automatizado |
| `make tg5040` | Build sistema sem cores |
| `make build-essential-cores PLATFORM=tg5040` | Cores estáveis apenas |
| `make build-core PLATFORM=tg5040 CORE=fceumm` | Core específico |
| `make shell PLATFORM=tg5040` | Shell interativo Docker |
| `make clean PLATFORM=tg5040` | Limpa build |

## 🎮 Cores Estáveis

✅ **Funcionam bem:**
- `fceumm` (Nintendo/Famicom)
- `gambatte` (Game Boy/GBC)
- `gpsp` (Game Boy Advance)
- `mgba` (Game Boy Advance)
- `picodrive` (Sega Genesis/MD)
- `snes9x` (Super Nintendo)
- `pcsx_rearmed` (PlayStation 1)

⚠️ **Podem dar problema:**
- `fake-08` (PICO-8)
- `fbneo` (Arcade)
- `vice_*` (Commodore)

## 🔧 Solução de Problemas

| Erro | Solução |
|------|---------|
| `fake-08` falha compilação | Use `build-essential-cores` |
| Git ownership error | Já corrigido automaticamente |
| Core não encontrado | Normal, use verificações condicionais |

## 📁 Estrutura de Output

```
releases/
├── NextUI-YYYYMMDD-X-base.zip    # Sistema mínimo
├── NextUI-YYYYMMDD-X-extras.zip  # Emuladores extras
└── NextUI-YYYYMMDD-X-all.zip     # Pacote completo
```

## 🐛 Debug

```bash
# Ver cores disponíveis
make cores-json PLATFORM=tg5040

# Status de core específico
cd workspace/tg5040/cores && make status-fceumm

# Build verbose
make PLATFORM=tg5040 MAKEFLAGS=
```
