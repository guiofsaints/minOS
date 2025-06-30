# Save State Preview Fix - Folder Renaming Compatibility

## Problema

Quando as pastas de ROMs são renomeadas no minOS, os previews dos save states deixam de aparecer. Isso acontece porque o sistema usa o nome da pasta para determinar onde salvar e procurar os arquivos de preview.

## Solução Implementada

### 1. Mapeamento de Nomes Legados (Código)

Foi modificada a função `getEmuName()` em `workspace/all/common/utils.c` para incluir um sistema de mapeamento que converte nomes novos para nomes legados, mantendo compatibilidade com save states existentes.

**Mapeamentos implementados:**
- `NES` → `FC` (Nintendo Entertainment System)
- `SNES` → `SFC` (Super Nintendo Entertainment System)  
- `Genesis` → `MD` (Sega Genesis/Mega Drive)
- `Master System` → `MS` (Sega Master System)
- `Game Gear` → `GG` (Sega Game Gear)
- `TurboGrafx-16` → `PCE` (PC Engine/TurboGrafx-16)
- `Lynx` → `LYNX` (Atari Lynx)
- `Neo Geo Pocket` → `NGPC` (Neo Geo Pocket Color)
- `WonderSwan` → `WSC` (WonderSwan Color)

### 2. Script de Migração

O script `tools/migrate_savestate_dirs.sh` migra automaticamente os diretórios de save states existentes para os nomes legados.

## Como Usar

### Opção 1: Apenas Recompilar (Recomendado)

Se você ainda não renomeou as pastas:

1. Recompile o minOS com as modificações
2. Renomeie as pastas como desejar
3. Os save states continuarão funcionando automaticamente

### Opção 2: Migração Manual (Se já renomeou as pastas)

Se você já renomeou as pastas e perdeu os previews:

1. Recompile o minOS com as modificações
2. Copie o script para o dispositivo:
   ```bash
   scp tools/migrate_savestate_dirs.sh root@device_ip:/tmp/
   ```

3. Execute no dispositivo:
   ```bash
   ssh root@device_ip
   chmod +x /tmp/migrate_savestate_dirs.sh
   /tmp/migrate_savestate_dirs.sh
   ```

4. Reinicie o minOS

### Opção 3: Migração Manual (Terminal do Dispositivo)

Conecte via SSH ou acesse o terminal do dispositivo e execute:

```bash
cd /mnt/SDCARD/.userdata/shared/.minos

# Exemplo: se você renomeou FC para NES
if [ -d "NES" ] && [ ! -d "FC" ]; then
    mv "NES" "FC"
fi

# Exemplo: se você renomeou SFC para SNES  
if [ -d "SNES" ] && [ ! -d "SFC" ]; then
    mv "SNES" "SFC"
fi

# Repita para outros sistemas conforme necessário
```

## Estrutura dos Diretórios

Os save states e previews são armazenados em:
```
/mnt/SDCARD/.userdata/shared/.minos/
├── FC/           # Nintendo Entertainment System
│   ├── game1.nes.0.bmp
│   ├── game1.nes.txt
│   └── ...
├── SFC/          # Super Nintendo Entertainment System
├── MD/           # Sega Genesis/Mega Drive
├── GB/           # Game Boy
├── GBA/          # Game Boy Advance
└── ...
```

## Para Desenvolvedores

### Adicionando Novos Mapeamentos

Para adicionar suporte a novas renomeações, edite a função `mapLegacyEmuName()` em `utils.c`:

```c
static struct {
    const char* new_name;
    const char* legacy_name;
} name_mapping[] = {
    {"NovoNome", "ANTIGO"},
    // ... outros mapeamentos
    {NULL, NULL}  // Marcador de fim
};
```

### Testando

1. Compile a versão modificada
2. Crie alguns save states
3. Renomeie as pastas de ROMs
4. Verifique se os previews ainda aparecem
5. Crie novos save states para testar compatibilidade

## Notas Importantes

- **Backup**: O script cria backup automático antes da migração
- **Compatibilidade**: Funciona com save states existentes e novos
- **Performance**: Impacto mínimo na performance (apenas uma lookup table)
- **Manutenibilidade**: Fácil adicionar novos mapeamentos

## Troubleshooting

### Previews ainda não aparecem

1. Verifique se recompilou com as modificações
2. Verifique se executou o script de migração
3. Verifique os logs do minOS para erros
4. Verifique as permissões dos diretórios

### Script de migração falha

1. Verifique se tem permissões de escrita
2. Verifique se há espaço suficiente
3. Execute manualmente os comandos de migração

### Novos save states não funcionam

1. Verifique se a função `getEmuName()` está retornando o nome correto
2. Adicione logs para debug se necessário
3. Verifique se o mapeamento está correto

## Logs de Debug

Para ativar logs de debug, descomente as linhas `printf` na função `getEmuName()`:

```c
printf("--------\n  in_name: %s\n", in_name);
printf("    tmp1: %s\n", tmp);  
printf("    tmp2: %s\n", tmp);
printf(" out_name: %s\n", out_name);
```

Isso ajudará a identificar como os nomes estão sendo processados.
