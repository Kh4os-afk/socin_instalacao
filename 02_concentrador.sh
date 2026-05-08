#!/bin/bash
# =============================================================
#  02_concentrador.sh – Configuração do IP do Concentrador
#  Baratão da Carne | TI – Sistemas e Infraestrutura
# =============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PROPS_FILE="/usr/socin/econect/pdv/properties/Ips.properties"

header() {
    clear
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}  ${BOLD}BARATÃO DA CARNE – IP do Concentrador (PDV)${NC}         ${RED}║${NC}"
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

# =============================================================
#  LER OU INICIALIZAR VALORES
# =============================================================

read_current() {
    if [ ! -f "$PROPS_FILE" ]; then
        echo -e "  ${YELLOW}⚠ Arquivo $PROPS_FILE não encontrado.${NC}"
        echo -e "  Será criado com os valores informados."
        echo ""

        # Tenta detectar IP do caixa para pré-preencher IpPdv
        IFACE=$(nmcli -g DEVICE,TYPE device status 2>/dev/null \
            | grep -i "ethernet" | cut -d: -f1 | head -1)
        IP_PDV_ATUAL=$(ip -4 addr show "$IFACE" 2>/dev/null \
            | grep inet | awk '{print $2}' | head -1)

        IP_CONC_ATUAL=""
        DNS_ATUAL=""
        return
    fi

    IP_CONC_ATUAL=$(grep "^IpConc=" "$PROPS_FILE" 2>/dev/null | cut -d= -f2 | tr -d '[:space:]')
    DNS_ATUAL=$(grep "^Dns="    "$PROPS_FILE" 2>/dev/null | cut -d= -f2 | tr -d '[:space:]')
    IP_PDV_ATUAL=$(grep "^IpPdv=" "$PROPS_FILE" 2>/dev/null | cut -d= -f2 | tr -d '[:space:]')

    echo -e "  ${BOLD}Valores atuais em Ips.properties:${NC}"
    echo -e "  IpPdv  : ${CYAN}${IP_PDV_ATUAL:-não definido}${NC}"
    echo -e "  IpConc : ${CYAN}${IP_CONC_ATUAL:-não definido}${NC}"
    echo -e "  Dns    : ${CYAN}${DNS_ATUAL:-não definido}${NC}"
    echo ""
}

# =============================================================
#  APLICAR — ATUALIZA OU CRIA O ARQUIVO
# =============================================================

apply() {
    echo ""
    echo -e "  ${BOLD}Aplicando alterações...${NC}"
    echo ""

    # Cria o diretório se não existir
    mkdir -p "$(dirname "$PROPS_FILE")"

    if [ -f "$PROPS_FILE" ]; then
        # Arquivo existe: faz backup e atualiza com sed
        cp "$PROPS_FILE" "${PROPS_FILE}.bak"
        echo -e "  ${GREEN}✔ Backup salvo em: ${PROPS_FILE}.bak${NC}"
        sed -i "s|^IpConc=.*|IpConc=$IP_CONC|" "$PROPS_FILE"
        sed -i "s|^Dns=.*|Dns=$DNS_FINAL|"      "$PROPS_FILE"
        sed -i "s|^IpPdv=.*|IpPdv=$IP_PDV_FINAL|" "$PROPS_FILE"
    else
        # Arquivo não existe: cria do zero
        cat > "$PROPS_FILE" <<EOF
#Criado
#$(date)
IpPdv=$IP_PDV_FINAL
Dns=$DNS_FINAL
IpConc=$IP_CONC
EOF
        echo -e "  ${GREEN}✔ Arquivo criado em: ${CYAN}$PROPS_FILE${NC}"
    fi

    echo -e "  ${GREEN}✔ IpConc : $IP_CONC${NC}"
    echo -e "  ${GREEN}✔ Dns    : $DNS_FINAL${NC}"
    echo -e "  ${GREEN}✔ IpPdv  : $IP_PDV_FINAL${NC}"
}

# =============================================================
#  VERIFICAÇÃO FINAL
# =============================================================

verify() {
    echo ""
    echo -e "  ${BOLD}Conteúdo atual do arquivo:${NC}"
    echo ""
    grep -v "^#" "$PROPS_FILE" | grep -v "^$" | sed 's/^/    /'
    echo ""

    echo -ne "  Testando conectividade com o concentrador $IP_CONC... "
    if ping -c 2 -W 2 "$IP_CONC" &>/dev/null; then
        echo -e "${GREEN}✔ alcançável${NC}"
    else
        echo -e "${YELLOW}⚠ não respondeu (verifique a rede e o concentrador)${NC}"
    fi
    echo ""
}

# =============================================================
#  EXECUÇÃO PRINCIPAL
# =============================================================

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✘ Execute como root: sudo bash ./02_concentrador.sh${NC}"
    exit 1
fi

header

ask_yn "Deseja configurar o IP do concentrador?" "s" EXECUTAR
if [ "$EXECUTAR" = "n" ]; then
    echo -e "  ${YELLOW}Passo ignorado.${NC}\n"
    exit 0
fi

echo ""
read_current

ask "IP do Concentrador (IpConc)" "${IP_CONC_ATUAL:-172.22.9.140}" IP_CONC

# DNS: usa o do arquivo se existir, senão pede
if [ -n "$DNS_ATUAL" ]; then
    DNS_FINAL="$DNS_ATUAL"
    echo -e "  ${GREEN}✔ DNS lido do arquivo: ${CYAN}$DNS_FINAL${NC} (não será alterado)"
else
    ask "DNS" "8.8.8.8" DNS_FINAL
fi

# IpPdv: usa o do arquivo ou o detectado
if [ -n "$IP_PDV_ATUAL" ]; then
    IP_PDV_FINAL="$IP_PDV_ATUAL"
else
    ask "IP do PDV com máscara (IpPdv, ex: 172.22.9.4/16)" "${IP_PDV_ATUAL:-}" IP_PDV_FINAL
fi

echo ""
echo -e "  ${BOLD}──────────────────────────────────────────────────────${NC}"
echo -e "  ${BOLD}Resumo:${NC}"
echo -e "  ${BOLD}──────────────────────────────────────────────────────${NC}"
echo -e "  Arquivo  : ${CYAN}$PROPS_FILE${NC}"
echo -e "  IpPdv    : ${CYAN}$IP_PDV_FINAL${NC}"
echo -e "  IpConc   : ${CYAN}$IP_CONC${NC}"
echo -e "  Dns      : ${CYAN}$DNS_FINAL${NC}"
echo -e "  ${BOLD}──────────────────────────────────────────────────────${NC}"
echo ""

ask_yn "Confirmar e aplicar?" "s" RESP
if [ "$RESP" = "n" ]; then
    echo -e "  ${RED}Operação cancelada.${NC}"
    exit 1
fi

apply
verify

echo -e "${GREEN}${BOLD}  ✔ Configuração do concentrador concluída!${NC}\n"
