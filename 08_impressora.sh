#!/bin/bash
# =============================================================
#  08_impressora.sh – Desabilitar Notificação da Impressora
#  Baratão da Carne | TI – Sistemas e Infraestrutura
# =============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

APPLET="/usr/share/system-config-printer/applet.py"

header() {
    clear
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}  ${BOLD}BARATÃO DA CARNE – Notificação de Impressora${NC}        ${RED}║${NC}"
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

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✘ Execute como root: sudo bash ./08_impressora.sh${NC}"
    exit 1
fi

header

ask_yn "Deseja desabilitar a notificação da impressora?" "s" EXECUTAR
if [ "$EXECUTAR" = "n" ]; then
    echo -e "  ${YELLOW}Passo ignorado.${NC}\n"
    exit 0
fi

echo ""

if [ ! -f "$APPLET" ]; then
    echo -e "  ${YELLOW}⚠ Arquivo não encontrado: $APPLET${NC}"
    echo -e "  O applet pode já não estar instalado neste sistema."
    echo -e "  ${GREEN}✔ Nenhuma ação necessária.${NC}\n"
    exit 0
fi

STATUS_ATUAL=$([ -x "$APPLET" ] && echo "habilitado" || echo "já desabilitado")
echo -e "  Status atual do applet: ${CYAN}$STATUS_ATUAL${NC}"
echo ""

if [ "$STATUS_ATUAL" = "já desabilitado" ]; then
    echo -e "  ${GREEN}✔ Applet já está desabilitado. Nenhuma alteração necessária.${NC}\n"
    exit 0
fi

chmod -x "$APPLET"
echo -e "  ${GREEN}✔ Notificação de impressora desabilitada.${NC}"
echo ""
echo -e "  ${CYAN}Para reverter:${NC} sudo chmod +x $APPLET"
echo ""
echo -e "${GREEN}${BOLD}  ✔ Configuração da impressora concluída!${NC}\n"
