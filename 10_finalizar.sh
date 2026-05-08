#!/bin/bash
# =============================================================
#  10_finalizar.sh – Cópia Final e Encerramento
#  Baratão da Carne | TI – Sistemas e Infraestrutura
# =============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
DESKTOP="/root/Área de Trabalho"
GER_SO_SRC="$SCRIPTS_DIR/ger_so.jar"
STARTPDV_SRC="/usr/socin/econect/pdv/bin/startpdv.sh"

# =============================================================
#  FUNÇÕES
# =============================================================

header() {
    clear
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}  ${BOLD}BARATÃO DA CARNE – Finalização da Instalação${NC}        ${RED}║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

ask_yn() {
    local prompt="$1" default="$2" var_name="$3" value=""
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

ascii_final() {
    echo ""
    echo -e "${RED}"
    echo "  ██████╗  █████╗ ██████╗  █████╗ ████████╗ █████╗  ██████╗ "
    echo "  ██╔══██╗██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔═══██╗"
    echo "  ██████╔╝███████║██████╔╝███████║   ██║   ███████║██║   ██║"
    echo "  ██╔══██╗██╔══██║██╔══██╗██╔══██║   ██║   ██╔══██║██║   ██║"
    echo "  ██████╔╝██║  ██║██║  ██║██║  ██║   ██║   ██║  ██║╚██████╔╝"
    echo "  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝  ╚═╝   ╚═╝  ╚═╝ ╚═════╝ "
    echo -e "${NC}"
    echo -e "${BOLD}${RED}         ██████╗  █████╗      ██████╗ █████╗ ██████╗ ███╗  ██╗███████╗${NC}"
    echo -e "${BOLD}${RED}         ██╔══██╗██╔══██╗    ██╔════╝██╔══██╗██╔══██╗████╗ ██║██╔════╝${NC}"
    echo -e "${BOLD}${RED}         ██║  ██║███████║    ██║     ███████║██████╔╝██╔██╗██║█████╗  ${NC}"
    echo -e "${BOLD}${RED}         ██║  ██║██╔══██║    ██║     ██╔══██║██╔══██╗██║╚████║██╔══╝  ${NC}"
    echo -e "${BOLD}${RED}         ██████╔╝██║  ██║    ╚██████╗██║  ██║██║  ██║██║ ╚███║███████╗${NC}"
    echo -e "${BOLD}${RED}         ╚═════╝ ╚═╝  ╚═╝     ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚══╝╚══════╝${NC}"
    echo ""
    echo -e "${BOLD}                   ████████╗██╗"
    echo -e "                      ██╔════╝██║"
    echo -e "                      ██║     ██║"
    echo -e "                      ██║     ██║"
    echo -e "                      ██║     ██║"
    echo -e "                      ╚═╝     ╚═╝${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}        I N S T A L A Ç Ã O   F I N A L I Z A D A${NC}"
    echo ""
    echo -e "${BOLD}               Baratão da Carne – TI${NC}"
    echo ""
}

# =============================================================
#  EXECUÇÃO PRINCIPAL
# =============================================================

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✘ Execute como root: sudo bash ./10_finalizar.sh${NC}"
    exit 1
fi

header

ask_yn "Deseja finalizar a instalação e copiar os arquivos?" "s" EXECUTAR
if [ "$EXECUTAR" = "n" ]; then
    echo -e "  ${YELLOW}Passo ignorado.${NC}\n"
    exit 0
fi

echo ""

# Garante que a pasta Área de Trabalho existe
mkdir -p "$DESKTOP"

# ── Copia ger_so.jar ─────────────────────────────────────────
echo -e "  Copiando ger_so.jar para /root..."
if [ -f "$GER_SO_SRC" ]; then
    cp "$GER_SO_SRC" "/root/"
    chmod +x "/root/ger_so.jar"
    echo -e "  ${GREEN}✔ ger_so.jar copiado para: ${CYAN}/root${NC}"
else
    echo -e "  ${YELLOW}⚠ ger_so.jar não encontrado em: $GER_SO_SRC${NC}"
    echo -e "  ${YELLOW}  Copie manualmente para a Área de Trabalho.${NC}"
fi

# ── Copia startpdv.sh ─────────────────────────────────────────
echo -e "  Copiando startpdv.sh para a Área de Trabalho..."
if [ -f "$STARTPDV_SRC" ]; then
    cp "$STARTPDV_SRC" "$DESKTOP/"
    chmod +x "$DESKTOP/startpdv.sh"
    echo -e "  ${GREEN}✔ startpdv.sh copiado para: ${CYAN}$DESKTOP${NC}"
else
    echo -e "  ${YELLOW}⚠ startpdv.sh não encontrado em: $STARTPDV_SRC${NC}"
    echo -e "  ${YELLOW}  Verifique se o PDV eConect foi instalado corretamente.${NC}"
fi

echo ""
echo -e "  ${BOLD}Arquivos na Área de Trabalho:${NC}"
echo -e "  ${BOLD}ger_so.jar:${NC}"
    ls -lh "/root/ger_so.jar" 2>/dev/null | sed 's/^/    /'
    echo -e "  ${BOLD}startpdv.sh:${NC}"
    ls -lh "$DESKTOP/startpdv.sh" 2>/dev/null | sed 's/^/    /'
echo ""

# ── ASCII art final ───────────────────────────────────────────
ascii_final
