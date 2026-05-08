#!/bin/bash
# =============================================================
#  05_chama_caixa.sh – Configuração do Chama Caixa (XFCE)
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
    echo -e "${RED}║${NC}  ${BOLD}BARATÃO DA CARNE – Configuração Chama Caixa${NC}         ${RED}║${NC}"
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

# =============================================================
#  DETECTAR IP DO CAIXA E DERIVAR PAINEL + CX
# =============================================================

detect_values() {
    echo -e "  Detectando IP do caixa..."

    # Pega interface ethernet
    IFACE=$(nmcli -g DEVICE,TYPE device status 2>/dev/null \
        | grep -i "ethernet" | cut -d: -f1 | head -1)

    # Lê IP atual da interface
    IP_CAIXA=$(ip -4 addr show "$IFACE" 2>/dev/null \
        | grep inet | awk '{print $2}' | cut -d/ -f1 | head -1)

    if [ -z "$IP_CAIXA" ]; then
        echo -e "  ${YELLOW}⚠ Não foi possível detectar o IP da interface $IFACE.${NC}"
        echo -e "  Informe manualmente:"
        ask "IP do caixa (ex: 172.22.9.4)" "" IP_CAIXA
    else
        echo -e "  ${GREEN}✔ IP detectado: ${CYAN}$IP_CAIXA${NC}"
    fi

    # Deriva os 3 primeiros octetos
    SUBNET=$(echo "$IP_CAIXA" | cut -d. -f1-3)

    # Último octeto = número do caixa
    CX=$(echo "$IP_CAIXA" | cut -d. -f4)

    # IP do painel = subnet + .70
    IP_PAINEL="${SUBNET}.70"

    echo -e "  ${GREEN}✔ Painel derivado  : ${CYAN}$IP_PAINEL${NC}"
    echo -e "  ${GREEN}✔ Número do caixa  : ${CYAN}$CX${NC}"
    echo ""
}

# =============================================================
#  DETECTAR USUÁRIO DO XFCE (não root)
# =============================================================

detect_xfce_user() {
    # Tenta pegar o usuário logado na sessão gráfica
    XFCE_USER=$(who | grep -v root | awk '{print $1}' | head -1)

    if [ -z "$XFCE_USER" ]; then
        # Fallback: primeiro usuário com home em /home
        XFCE_USER=$(ls /home | head -1)
    fi

    if [ -z "$XFCE_USER" ]; then
        echo -e "  ${RED}✘ Não foi possível detectar o usuário XFCE.${NC}"
        ask "Usuário do sistema (ex: caixa, pdv)" "" XFCE_USER
    fi

    XFCE_UID=$(id -u "$XFCE_USER" 2>/dev/null)
    DBUS_ADDR="unix:path=/run/user/${XFCE_UID}/bus"

    echo -e "  ${GREEN}✔ Usuário XFCE detectado: ${CYAN}$XFCE_USER${NC}"
}

# =============================================================
#  CONFIGURAR ATALHO VIA XFCONF-QUERY (D-Bus sessão root)
# =============================================================

configure_shortcut() {
    local key="$1"
    local DBUS_ADDR="unix:path=/run/user/0/bus"
    local cmd="bash -c 'curl -s \"http://${IP_PAINEL}/chamcaixa/?cx=${CX}\" >/dev/null'"

    echo ""
    echo -e "  Configurando atalho ${CYAN}[$key]${NC} para:"
    echo -e "  ${CYAN}$cmd${NC}"
    echo ""

    # Remove entrada antiga se existir
    DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDR" \
        xfconf-query -c xfce4-keyboard-shortcuts \
        -p "/commands/custom/$key" --reset 2>/dev/null || true

    # Cria o novo atalho via D-Bus — aplica imediatamente sem reiniciar
    DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDR" \
        xfconf-query -c xfce4-keyboard-shortcuts \
        -p "/commands/custom/$key" \
        -n -t string \
        -s "$cmd"

    local ret=$?
    if [ $ret -eq 0 ]; then
        echo -e "  ${GREEN}✔ Atalho [$key] configurado e ativo imediatamente.${NC}"
    else
        echo -e "  ${RED}✘ Erro ao configurar atalho (código $ret).${NC}"
        echo -e "  ${YELLOW}Verifique se a sessão gráfica está ativa.${NC}"
        exit 1
    fi

    echo ""
    echo -e "  ${YELLOW}Verificação:${NC}"
    DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDR" \
        xfconf-query -c xfce4-keyboard-shortcuts \
        -p "/commands/custom/$key" 2>/dev/null | sed 's/^/    /'
    echo ""
}
# =============================================================
#  VERIFICAÇÃO – TESTA O CURL
# =============================================================

verify() {
    echo ""
    echo -e "  ${BOLD}Testando chamada ao painel...${NC}"
    echo -ne "  Enviando requisição para ${CYAN}http://${IP_PAINEL}/chamcaixa/?cx=${CX}${NC}... "

    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout 3 \
        "http://${IP_PAINEL}/chamcaixa/?cx=${CX}" 2>/dev/null || echo "000")

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "204" ]; then
        echo -e "${GREEN}✔ Painel respondeu (HTTP $HTTP_CODE)${NC}"
    elif [ "$HTTP_CODE" = "000" ]; then
        echo -e "${YELLOW}⚠ Painel não respondeu (verifique se está ligado e acessível)${NC}"
    else
        echo -e "${YELLOW}⚠ Painel respondeu com HTTP $HTTP_CODE${NC}"
    fi
    echo ""
}

# =============================================================
#  EXECUÇÃO PRINCIPAL
# =============================================================

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✘ Execute como root: sudo bash ./05_chama_caixa.sh${NC}"
    exit 1
fi

header

ask_yn "Deseja configurar o Chama Caixa?" "s" EXECUTAR
if [ "$EXECUTAR" = "n" ]; then
    echo -e "  ${YELLOW}Passo ignorado.${NC}"
    echo ""
    exit 0
fi

echo ""
detect_values
detect_xfce_user

# Permite ajuste manual dos valores derivados
echo -e "  ${BOLD}Confirme ou ajuste os valores detectados:${NC}"
echo ""
ask "IP do Painel"        "$IP_PAINEL"  IP_PAINEL
ask "Número do caixa (cx)" "$CX"        CX
TECLA="Home"

echo ""
echo -e "  ${BOLD}──────────────────────────────────────────────────────${NC}"
echo -e "  ${BOLD}Resumo:${NC}"
echo -e "  ${BOLD}──────────────────────────────────────────────────────${NC}"
echo -e "  Usuário XFCE  : ${CYAN}$XFCE_USER${NC}"
echo -e "  Tecla de atalho: ${CYAN}$TECLA${NC}"
echo -e "  IP do Painel  : ${CYAN}$IP_PAINEL${NC}"
echo -e "  Número do cx  : ${CYAN}$CX${NC}"
echo -e "  Comando       : ${CYAN}bash -c 'curl -s \"http://$IP_PAINEL/chamcaixa/?cx=$CX\" >/dev/null'${NC}"
echo -e "  ${BOLD}──────────────────────────────────────────────────────${NC}"
echo ""

ask_yn "Confirmar e aplicar?" "s" RESP
if [ "$RESP" = "n" ]; then
    echo -e "  ${RED}Operação cancelada.${NC}"
    exit 1
fi

configure_shortcut "$TECLA"
verify

echo -e "${GREEN}${BOLD}  ✔ Chama Caixa configurado!${NC}"
echo ""
