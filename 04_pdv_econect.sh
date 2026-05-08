#!/bin/bash
# =============================================================
#  04_pdv_econect.sh – Instalação do PDV eConect (SOCIN)
#  Baratão da Carne | TI – Sistemas e Infraestrutura
# =============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# =============================================================
#  CONFIGURAÇÕES DO SERVIDOR DE ARQUIVOS
# =============================================================

SMB_HOST="172.22.0.120"
SMB_SHARE="ti\$"
SMB_USER="administrador"
SMB_PASS="@dmb4r4t40*"
SMB_INSTALL_DIR="socin/instalacao_socin"
MOUNT_POINT="/mnt/socin_install"

# =============================================================
#  FUNÇÕES
# =============================================================

header() {
    clear
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}  ${BOLD}BARATÃO DA CARNE – Instalação PDV eConect${NC}           ${RED}║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

ask_yn() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    local value=""

    while true; do
        echo -ne "  ${YELLOW}▸ $prompt${NC}"
        [ "$default" = "s" ] && echo -ne " ${YELLOW}(s/n) [s]${NC}: " || echo -ne " ${YELLOW}(s/n) [n]${NC}: "
        read value
        [ -z "$value" ] && value="$default"
        case "$value" in
            s|S) eval "$var_name='s'"; return 0 ;;
            n|N) eval "$var_name='n'"; return 1 ;;
            *) echo -e "  ${RED}✘ Digite s ou n.${NC}" ;;
        esac
    done
}

cleanup() {
    if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        echo ""
        echo -e "  Desmontando compartilhamento SMB..."
        umount "$MOUNT_POINT" 2>/dev/null || umount -l "$MOUNT_POINT" 2>/dev/null || true
        echo -e "  ${GREEN}✔ Compartilhamento desmontado.${NC}"
    fi
}

# Garante desmontagem mesmo em caso de erro ou Ctrl+C
trap cleanup EXIT

# =============================================================
#  VERIFICAR DEPENDÊNCIA: cifs-utils
# =============================================================

check_deps() {
    if ! command -v mount.cifs &>/dev/null; then
        echo -e "  ${YELLOW}⚠ cifs-utils não encontrado. Instalando...${NC}"
        apt-get install -y cifs-utils
        echo -e "  ${GREEN}✔ cifs-utils instalado.${NC}"
    fi
}

# =============================================================
#  MONTAR O COMPARTILHAMENTO SMB
# =============================================================

mount_smb() {
    echo -e "  Conectando ao servidor ${CYAN}//${SMB_HOST}/${SMB_SHARE}${NC}..."

    mkdir -p "$MOUNT_POINT"

    # Desmonta se já estiver montado de uma execução anterior
    mountpoint -q "$MOUNT_POINT" 2>/dev/null && umount "$MOUNT_POINT" 2>/dev/null || true

    mount -t cifs "//${SMB_HOST}/${SMB_SHARE}" "$MOUNT_POINT" \
        -o "username=${SMB_USER},password=${SMB_PASS},vers=2.0,uid=0,gid=0" 2>/dev/null \
    || mount -t cifs "//${SMB_HOST}/${SMB_SHARE}" "$MOUNT_POINT" \
        -o "username=${SMB_USER},password=${SMB_PASS},vers=3.0,uid=0,gid=0"

    echo -e "  ${GREEN}✔ Compartilhamento montado em: ${CYAN}$MOUNT_POINT${NC}"
}

# =============================================================
#  DETECTAR VERSÃO MAIS RECENTE DO INSTALADOR
# =============================================================

find_installer() {
    local install_path="$MOUNT_POINT/$SMB_INSTALL_DIR"

    if [ ! -d "$install_path" ]; then
        echo -e "  ${RED}✘ Diretório não encontrado: $install_path${NC}"
        echo -e "  Verifique o caminho no servidor SMB."
        exit 1
    fi

    echo -e "  Buscando instaladores disponíveis em ${CYAN}$SMB_INSTALL_DIR${NC}..."
    echo ""

    # Lista todos os JARs do PDV ordenados por data (mais recente primeiro)
    mapfile -t JARS < <(ls -t "$install_path"/installPdv-econect-*.jar 2>/dev/null)

    if [ ${#JARS[@]} -eq 0 ]; then
        echo -e "  ${RED}✘ Nenhum instalador installPdv-econect-*.jar encontrado.${NC}"
        exit 1
    fi

    # Exibe todos os encontrados
    echo -e "  Instaladores encontrados:"
    for i in "${!JARS[@]}"; do
        FNAME=$(basename "${JARS[$i]}")
        FDATE=$(stat -c '%y' "${JARS[$i]}" 2>/dev/null | cut -d'.' -f1)
        if [ $i -eq 0 ]; then
            echo -e "    ${GREEN}[MAIS RECENTE]${NC} ${CYAN}$FNAME${NC}  ${BOLD}← será usado${NC}  (${FDATE})"
        else
            echo -e "    ${BOLD}[$((i+1))]${NC} $FNAME  (${FDATE})"
        fi
    done

    JAR_PATH="${JARS[0]}"
    JAR_NAME=$(basename "$JAR_PATH")

    echo ""
    echo -e "  ${BOLD}Versão selecionada: ${CYAN}$JAR_NAME${NC}"
    echo ""

    # Permite trocar manualmente se necessário
    ask_yn "Usar esta versão?" "s" USA_VERSAO
    if [ "$USA_VERSAO" = "n" ]; then
        echo ""
        echo -e "  Versões disponíveis:"
        for i in "${!JARS[@]}"; do
            echo -e "    $((i+1))) $(basename "${JARS[$i]}")"
        done
        echo ""
        echo -ne "  ${CYAN}▸ ${BOLD}Número da versão desejada${NC}: "
        read ESCOLHA
        ESCOLHA=$((ESCOLHA - 1))
        if [ -z "${JARS[$ESCOLHA]}" ]; then
            echo -e "  ${RED}✘ Opção inválida.${NC}"
            exit 1
        fi
        JAR_PATH="${JARS[$ESCOLHA]}"
        JAR_NAME=$(basename "$JAR_PATH")
        echo -e "  ${GREEN}✔ Versão selecionada: ${CYAN}$JAR_NAME${NC}"
    fi
}

# =============================================================
#  EXECUTAR O INSTALADOR
# =============================================================

run_installer() {
    echo ""
    echo -e "  ${BOLD}Iniciando instalador...${NC}"
    echo -e "  ${YELLOW}⚠ Siga as instruções do assistente de instalação.${NC}"
    echo ""

    # Exporta DISPLAY para o caso do instalador ter interface gráfica
    export DISPLAY=:0

    java -jar "$JAR_PATH"
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo ""
        echo -e "  ${GREEN}✔ Instalador concluído com sucesso.${NC}"
    else
        echo ""
        echo -e "  ${YELLOW}⚠ Instalador encerrou com código $exit_code.${NC}"
        echo -e "  Verifique se a instalação foi concluída corretamente."
    fi
}

# =============================================================
#  EXECUÇÃO PRINCIPAL
# =============================================================

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✘ Execute como root: sudo bash ./04_pdv_econect.sh${NC}"
    exit 1
fi

header

ask_yn "Deseja instalar o PDV eConect?" "s" EXECUTAR
if [ "$EXECUTAR" = "n" ]; then
    echo -e "  ${YELLOW}Passo ignorado.${NC}"
    echo ""
    exit 0
fi

echo ""
check_deps
mount_smb
find_installer
run_installer

echo ""
echo -e "${GREEN}${BOLD}  ✔ Instalação do PDV eConect concluída!${NC}"
echo ""
