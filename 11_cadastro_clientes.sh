#!/bin/bash
# =============================================================
#  11_cadastro_clientes.sh – Cadastro de Clientes (Firefox Kiosk)
#  Baratão da Carne | TI – Sistemas e Infraestrutura
# =============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

URL="http://172.22.22.172/cliente"

header() {
    clear
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}  ${BOLD}BARATÃO DA CARNE – Cadastro de Clientes${NC}             ${RED}║${NC}"
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

disable_cadastro() {
    local DBUS_ADDR="unix:path=/run/user/0/bus"

    DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDR" \
        xfconf-query -c xfce4-keyboard-shortcuts \
        -p "/commands/custom/Next" --reset 2>/dev/null || true

    echo -e "  ${GREEN}✔ Atalho [Page Down] removido.${NC}"
}

enable_cadastro() {
    # Configura atalho tecla Pg Down (Next) via xfconf-query
    local DBUS_ADDR="unix:path=/run/user/0/bus"
    local shortcut_cmd="firefox --kiosk $URL"

    DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDR" \
        xfconf-query -c xfce4-keyboard-shortcuts \
        -p "/commands/custom/Next" --reset 2>/dev/null || true

    DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDR" \
        xfconf-query -c xfce4-keyboard-shortcuts \
        -p "/commands/custom/Next" \
        -n -t string \
        -s "$shortcut_cmd" && \
        echo -e "  ${GREEN}✔ Atalho [Page Down] configurado.${NC}" || \
        echo -e "  ${YELLOW}⚠ Não foi possível configurar o atalho agora (sessão gráfica inativa).${NC}"

}

# =============================================================
#  EXECUÇÃO PRINCIPAL
# =============================================================

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✘ Execute como root: sudo bash ./11_cadastro_clientes.sh${NC}"
    exit 1
fi

header

ask_yn "Deseja habilitar o cadastro de clientes?" "s" HABILITAR

echo ""

if [ "$HABILITAR" = "s" ]; then
    enable_cadastro
    echo ""
    echo -e "  ${YELLOW}ℹ Para desabilitar futuramente, rode este script novamente.${NC}"
else
    disable_cadastro
fi

echo ""
echo -e "${GREEN}${BOLD}  ✔ Configuração de cadastro de clientes concluída!${NC}"
echo ""
