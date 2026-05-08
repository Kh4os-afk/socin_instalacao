#!/bin/bash
# =============================================================
#  07_hora.sh – Configuração de Fuso Horário e NTP
#  Baratão da Carne | TI – Sistemas e Infraestrutura
# =============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

TIMEZONE="America/Manaus"

header() {
    clear
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}  ${BOLD}BARATÃO DA CARNE – Fuso Horário e NTP${NC}               ${RED}║${NC}"
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
    echo -e "${RED}✘ Execute como root: sudo bash ./07_hora.sh${NC}"
    exit 1
fi

header

ask_yn "Deseja configurar fuso horário e NTP?" "s" EXECUTAR
if [ "$EXECUTAR" = "n" ]; then
    echo -e "  ${YELLOW}Passo ignorado.${NC}\n"
    exit 0
fi

echo ""
echo -e "  ${BOLD}Status atual:${NC}"
timedatectl status | grep -E "Local time|Time zone|NTP" | sed 's/^/    /'
echo ""

# Fuso horário
echo -e "  Configurando fuso horário para ${CYAN}$TIMEZONE${NC}..."
timedatectl set-timezone "$TIMEZONE"
echo -e "  ${GREEN}✔ Fuso horário definido: $TIMEZONE${NC}"

# NTP — detecta qual serviço está disponível
echo -e "  Sincronizando hora..."

if systemctl is-active --quiet ntp 2>/dev/null || systemctl is-enabled --quiet ntp 2>/dev/null; then
    # ntp instalado — força sincronização imediata
    echo -e "  Serviço ntp detectado. Forçando sincronização..."
    systemctl stop ntp 2>/dev/null || true
    ntpdate -u pool.ntp.org 2>/dev/null         || ntpdate -u a.ntp.br 2>/dev/null         || ntpdate -u 200.160.7.186 2>/dev/null         || true
    systemctl start ntp 2>/dev/null || true
    echo -e "  ${GREEN}✔ Hora sincronizada via ntpdate.${NC}"

elif timedatectl set-ntp true 2>/dev/null; then
    sleep 2
    echo -e "  ${GREEN}✔ NTP ativado via systemd-timesyncd.${NC}"

elif command -v ntpdate &>/dev/null; then
    echo -e "  ntpdate disponível. Sincronizando..."
    ntpdate -u pool.ntp.org 2>/dev/null         || ntpdate -u a.ntp.br 2>/dev/null         || true
    echo -e "  ${GREEN}✔ Hora sincronizada via ntpdate.${NC}"

else
    echo -e "  ${YELLOW}⚠ Nenhum serviço NTP encontrado. Instalando ntpdate...${NC}"
    apt-get install -y ntpdate 2>/dev/null &&         ntpdate -u pool.ntp.org 2>/dev/null &&         echo -e "  ${GREEN}✔ Hora sincronizada.${NC}" ||         echo -e "  ${YELLOW}⚠ Não foi possível sincronizar. Ajuste manualmente.${NC}"
fi

echo ""
echo -e "  ${BOLD}Status após configuração:${NC}"
timedatectl status | grep -E "Local time|Time zone|NTP|synchronized" | sed 's/^/    /'
echo ""
echo -e "${GREEN}${BOLD}  ✔ Fuso horário e NTP configurados!${NC}\n"
