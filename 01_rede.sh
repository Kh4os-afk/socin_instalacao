#!/bin/bash
# =============================================================
#  01_rede.sh – Configuração de Rede – PDV SOCIN
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
#  FUNÇÕES UTILITÁRIAS
# =============================================================

header() {
    clear
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}  ${BOLD}BARATÃO DA CARNE – Configuração de Rede (PDV)${NC}       ${RED}║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

ask() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    local value=""

    while true; do
        echo -ne "  ${CYAN}▸ ${BOLD}$prompt${NC}"
        [ -n "$default" ] && echo -ne " ${YELLOW}[padrão: $default]${NC}"
        echo -ne ": "
        read value
        [ -z "$value" ] && value="$default"
        if [ -n "$value" ]; then
            eval "$var_name='$value'"
            break
        else
            echo -e "  ${RED}✘ Campo obrigatório. Digite um valor.${NC}"
        fi
    done
}

ask_yn() {
    local prompt="$1"
    local default="$2"  # "s" ou "n"
    local var_name="$3"
    local value=""

    while true; do
        echo -ne "  ${YELLOW}▸ $prompt${NC}"
        if [ "$default" = "s" ]; then
            echo -ne " ${YELLOW}(s/n) [s]${NC}: "
        else
            echo -ne " ${YELLOW}(s/n) [n]${NC}: "
        fi
        read value
        [ -z "$value" ] && value="$default"
        case "$value" in
            s|S) eval "$var_name='s'"; return 0 ;;
            n|N) eval "$var_name='n'"; return 1 ;;
            *) echo -e "  ${RED}✘ Digite s ou n.${NC}" ;;
        esac
    done
}

# =============================================================
#  DETECÇÃO AUTOMÁTICA DA INTERFACE E CONEXÃO
# =============================================================

detect_network() {
    echo -e "  Detectando interface de rede ethernet..."

    IFACE=$(nmcli -g DEVICE,TYPE device status 2>/dev/null \
        | grep -i "ethernet" \
        | cut -d: -f1 \
        | head -1)

    if [ -n "$IFACE" ]; then
        CONN_NAME=$(nmcli -g NAME,DEVICE connection show 2>/dev/null \
            | grep ":${IFACE}$" \
            | cut -d: -f1 \
            | head -1)
    fi

    if [ -z "$CONN_NAME" ]; then
        CONN_NAME=$(nmcli -g NAME,TYPE connection show 2>/dev/null \
            | grep -i "ethernet" \
            | cut -d: -f1 \
            | head -1)
    fi

    if [ -z "$IFACE" ] || [ -z "$CONN_NAME" ]; then
        echo ""
        echo -e "  ${BOLD}── Diagnóstico ──${NC}"
        nmcli -g DEVICE,TYPE,STATE device status 2>/dev/null | sed 's/^/    /'
        echo -e "  ${BOLD}─────────────────${NC}"
        echo ""
        echo -e "  ${RED}✘ Nenhuma interface/conexão ethernet encontrada!${NC}"
        echo -e "  ${YELLOW}Tente: cp ./01_rede.sh /tmp/ && sudo bash /tmp/01_rede.sh${NC}"
        exit 1
    fi

    echo -e "  ${GREEN}✔ Interface detectada : ${CYAN}$IFACE${NC}"
    echo -e "  ${GREEN}✔ Conexão detectada   : ${CYAN}$CONN_NAME${NC}"
    echo ""
}

# =============================================================
#  CONFIRMAÇÃO ANTES DE APLICAR
# =============================================================

confirm() {
    echo ""
    echo -e "  ${BOLD}──────────────────────────────────────────────────────${NC}"
    echo -e "  ${BOLD}Resumo da configuração:${NC}"
    echo -e "  ${BOLD}──────────────────────────────────────────────────────${NC}"
    echo -e "  Conexão      : ${CYAN}$CONN_NAME${NC}"
    echo -e "  Interface    : ${CYAN}$IFACE${NC}"
    echo -e "  IP / Máscara : ${CYAN}$IP/$MASK${NC}"
    echo -e "  Gateway      : ${CYAN}$GW${NC}"
    echo -e "  DNS          : ${CYAN}$DNS${NC}"
    echo -e "  Rota TEF VM  : ${CYAN}$NET_TEF via $GW_TEF_VM  métrica 1${NC}"
    echo -e "  Rota TEF Ant.: ${CYAN}$NET_TEF via $GW_TEF_ANT  métrica 80${NC}"
    echo -e "  IPv6         : ${CYAN}desabilitado${NC}"
    echo -e "  ${BOLD}──────────────────────────────────────────────────────${NC}"
    echo ""
    ask_yn "Confirmar e aplicar?" "s" RESP || { echo -e "  ${RED}Operação cancelada.${NC}"; exit 1; }
}

# =============================================================
#  APLICAR VIA NMCLI
# =============================================================

apply() {
    echo ""
    echo -e "  ${BOLD}Aplicando configurações via nmcli...${NC}"
    echo ""

    nmcli connection modify "$CONN_NAME" \
        ipv4.method manual \
        ipv4.addresses "$IP/$MASK" \
        ipv4.gateway "$GW" \
        ipv4.dns "$DNS" \
        ipv4.routes "$NET_TEF $GW_TEF_VM 1, $NET_TEF $GW_TEF_ANT 80" \
        ipv6.method disabled \
        connection.autoconnect yes

    echo -e "  ${GREEN}✔ Configuração gravada pelo NetworkManager.${NC}"
    echo -e "  Reiniciando a conexão..."
    nmcli connection down "$CONN_NAME" 2>/dev/null || true
    sleep 1
    nmcli connection up "$CONN_NAME"
    echo -e "  ${GREEN}✔ Conexão reativada.${NC}"
}

# =============================================================
#  VERIFICAÇÃO FINAL
# =============================================================

verify() {
    echo ""
    echo -e "  ${BOLD}Verificação final:${NC}"
    echo ""

    IP_ATUAL=$(ip -4 addr show "$IFACE" | grep inet | awk '{print $2}' | head -1)
    if [ -n "$IP_ATUAL" ]; then
        echo -e "  ${GREEN}✔ IP ativo: $IP_ATUAL${NC}"
    else
        echo -e "  ${YELLOW}⚠ IP ainda não aparece na interface.${NC}"
    fi

    echo -ne "  Testando gateway $GW... "
    if ping -c 2 -W 2 "$GW" &>/dev/null; then
        echo -e "${GREEN}✔ alcançável${NC}"
    else
        echo -e "${YELLOW}⚠ não respondeu (pode ser normal dependendo da rede)${NC}"
    fi

    echo -ne "  Testando DNS $DNS... "
    if ping -c 2 -W 2 "$DNS" &>/dev/null; then
        echo -e "${GREEN}✔ alcançável${NC}"
    else
        echo -e "${YELLOW}⚠ não respondeu${NC}"
    fi

    echo ""
    echo -e "  ${BOLD}Rotas configuradas:${NC}"
    ip route show | sed 's/^/    /'
    echo ""
}

# =============================================================
#  EXECUÇÃO PRINCIPAL
# =============================================================

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✘ Execute como root: sudo bash ./01_rede.sh${NC}"
    exit 1
fi

header

ask_yn "Deseja configurar a rede?" "s" EXECUTAR
if [ "$EXECUTAR" = "n" ]; then
    echo -e "  ${YELLOW}Passo ignorado.${NC}"
    echo ""
    exit 0
fi

echo ""
detect_network

echo -e "  Informe os parâmetros de rede para este caixa."
echo -e "  Pressione ${BOLD}ENTER${NC} para aceitar o valor padrão."
echo ""

ask "IP do caixa (sem máscara)"               "172.22.9.4"    IP
ask "Máscara (ex: 16, 24)"                    "16"            MASK
ask "Gateway padrão"                          "172.22.0.1"    GW
ask "DNS"                                     "8.8.8.8"       DNS
echo ""
echo -e "  ${BOLD}Rotas TEF:${NC}"
ask "Rede de destino TEF (ex: 172.19.0.0/16)" "172.19.0.0/16" NET_TEF
ask "Gateway TEF VM     (métrica 1)"          "172.22.9.52"   GW_TEF_VM
ask "Gateway TEF Antena (métrica 80)"         "172.22.9.57"   GW_TEF_ANT

confirm
apply
verify

echo -e "${GREEN}${BOLD}  ✔ Configuração de rede concluída!${NC}"
echo ""
