#!/bin/bash
# =============================================================
#  09_ambiente.sh – Resolução e Ambiente OPENBOX (PDV SOCIN)
#  Baratão da Carne | TI – Sistemas e Infraestrutura
# =============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

RESOLUCAO="1024x768"
AUTOSTART_DIR="/root/.config/autostart"
XRANDR_DESKTOP="/root/.config/autostart/set-resolution.desktop"
PANEL_AUTOSTART="/root/.config/autostart/xfce4-panel.desktop"
XFCE_AUTOSTART_DIR="/root/.config/xfce4/xfconf/xfce-perchannel-xml"

# =============================================================
#  FUNÇÕES
# =============================================================

header() {
    clear
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}  ${BOLD}BARATÃO DA CARNE – Ambiente e Resolução (PDV)${NC}       ${RED}║${NC}"
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

# =============================================================
#  1. RESOLUÇÃO – aplica agora + persiste no autostart
# =============================================================

configure_resolution() {
    echo -e "  ${BOLD}[1/2] Configurando resolução para ${RESOLUCAO}...${NC}"
    echo ""

    # Detecta monitor ativo
    MONITOR=$(xrandr --display :0 2>/dev/null \
        | grep " connected" | awk '{print $1}' | head -1)

    if [ -z "$MONITOR" ]; then
        echo -e "  ${YELLOW}⚠ Não foi possível detectar o monitor via xrandr.${NC}"
        echo -e "  ${YELLOW}  A resolução será configurada apenas no autostart.${NC}"
        MONITOR="DP-1"
    else
        echo -e "  ${GREEN}✔ Monitor detectado: ${CYAN}$MONITOR${NC}"

        # Aplica imediatamente
        DISPLAY=:0 xrandr --output "$MONITOR" --mode "$RESOLUCAO" 2>/dev/null && \
            echo -e "  ${GREEN}✔ Resolução aplicada agora: ${CYAN}$RESOLUCAO${NC}" || \
            echo -e "  ${YELLOW}⚠ Não aplicou agora (sem sessão ativa) — será aplicado no próximo boot.${NC}"
    fi

    # Persiste no autostart (executa a cada login)
    mkdir -p "$AUTOSTART_DIR"
    cat > "$XRANDR_DESKTOP" << EOF
[Desktop Entry]
Type=Application
Name=Set Resolution
Exec=xrandr --output $MONITOR --mode $RESOLUCAO
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

    echo -e "  ${GREEN}✔ Autostart de resolução criado em: ${CYAN}$XRANDR_DESKTOP${NC}"
    echo ""
}

# =============================================================
#  2. OPENBOX – desabilita painel, salva sessão limpa
# =============================================================

configure_openbox() {
    echo -e "  ${BOLD}[2/2] Configurando ambiente OPENBOX (sem painel XFCE)...${NC}"
    echo ""

    mkdir -p "$AUTOSTART_DIR"

    # Mata o painel agora se estiver rodando
    if pgrep -x xfce4-panel &>/dev/null; then
        DISPLAY=:0 killall xfce4-panel 2>/dev/null || true
        echo -e "  ${GREEN}✔ xfce4-panel encerrado.${NC}"
    fi

    # Desabilita xfce4-panel no autostart
    cat > "$PANEL_AUTOSTART" <<AEOF
[Desktop Entry]
Type=Application
Name=xfce4-panel
Exec=xfce4-panel
Hidden=true
X-GNOME-Autostart-enabled=false
AEOF
    echo -e "  ${GREEN}✔ xfce4-panel desabilitado no autostart.${NC}"

    # Configura xfce4-session para NÃO salvar sessão ao sair
    # Sem isso o XFCE restaura o painel no próximo boot
    mkdir -p "$XFCE_AUTOSTART_DIR"
    SESSION_XML="$XFCE_AUTOSTART_DIR/xfce4-session.xml"

    cat > "$SESSION_XML" <<SEOF
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-session" version="1.0">
  <property name="general" type="empty">
    <property name="SaveOnExit" type="bool" value="false"/>
  </property>
  <property name="startup" type="empty">
    <property name="screensaver-enabled" type="bool" value="false"/>
  </property>
</channel>
SEOF
    echo -e "  ${GREEN}✔ SaveOnExit=false configurado (sessão não será salva ao sair).${NC}"

    # Detecta o hostname para nomear o arquivo de sessão corretamente
    HOSTNAME_CURTO=$(hostname)
    SESSION_DIR="/root/.cache/sessions"
    SESSION_FILE="$SESSION_DIR/xfce4-session-${HOSTNAME_CURTO}:0"

    mkdir -p "$SESSION_DIR"

    # Remove sessões antigas (podem conter xfce4-panel)
    rm -f "$SESSION_DIR"/xfce4-session*
    echo -e "  ${GREEN}✔ Sessões antigas removidas.${NC}"

    # Escreve sessão limpa sem xfce4-panel
    # XFCE vai restaurar exatamente esses processos no próximo boot
    cat > "$SESSION_FILE" <<SESSEOF
[Session: Default]
Client0_ClientId=2effd39c7-0000-0000-0000-000000000001
Client0_Hostname=local/${HOSTNAME_CURTO}
Client0_CloneCommand=xfwm4
Client0_RestartCommand=xfwm4,--display,:0.0,--sm-client-id,2effd39c7-0000-0000-0000-000000000001
Client0_CurrentDirectory=/root
Client0_Program=xfwm4
Client0_UserId=root
Client0_Priority=15
Client0_RestartStyleHint=2
Client1_ClientId=28af8a822-0000-0000-0000-000000000002
Client1_Hostname=local/${HOSTNAME_CURTO}
Client1_CloneCommand=xfsettingsd
Client1_RestartCommand=xfsettingsd,--display,:0.0,--sm-client-id,28af8a822-0000-0000-0000-000000000002
Client1_CurrentDirectory=/root
Client1_DesktopFile=/etc/xdg/autostart/xfsettingsd.desktop
Client1_Program=xfsettingsd
Client1_UserId=root
Client1_Priority=20
Client1_RestartStyleHint=2
Client2_ClientId=2c5c6ae5f-0000-0000-0000-000000000003
Client2_Hostname=local/${HOSTNAME_CURTO}
Client2_CloneCommand=xfdesktop
Client2_RestartCommand=xfdesktop,--display,:0.0,--sm-client-id,2c5c6ae5f-0000-0000-0000-000000000003
Client2_CurrentDirectory=/root
Client2_Program=xfdesktop
Client2_UserId=root
Client2_Priority=35
Client2_RestartStyleHint=2
Count=3
Screen0_ActiveWorkspace=0
LastAccess=$(date +%s)
SESSEOF

    echo -e "  ${GREEN}✔ Sessão OPENBOX gravada em: ${CYAN}$SESSION_FILE${NC}"
    echo -e "  ${GREEN}  (xfwm4 + xfsettingsd + xfdesktop — sem xfce4-panel)${NC}"

    echo ""
}

# =============================================================
#  VERIFICAÇÃO FINAL
# =============================================================

verify() {
    echo -e "  ${BOLD}Status final:${NC}"
    echo ""

    # Resolução atual
    RES_ATUAL=$(DISPLAY=:0 xrandr 2>/dev/null \
        | grep "^\s*[0-9]" | grep "\*" | awk '{print $1}' | head -1)
    if [ -n "$RES_ATUAL" ]; then
        echo -e "  ${GREEN}✔ Resolução ativa: ${CYAN}$RES_ATUAL${NC}"
    else
        echo -e "  ${YELLOW}⚠ Resolução não detectada agora — verificar após reboot.${NC}"
    fi

    # Painel
    if pgrep -x xfce4-panel &>/dev/null; then
        echo -e "  ${YELLOW}⚠ xfce4-panel ainda está rodando (será removido no próximo boot).${NC}"
    else
        echo -e "  ${GREEN}✔ xfce4-panel não está ativo.${NC}"
    fi

    echo ""
    echo -e "  ${YELLOW}ℹ Reinicie a sessão gráfica para aplicar todas as mudanças:${NC}"
    echo -e "  ${CYAN}    systemctl restart lightdm${NC}"
    echo ""
}

# =============================================================
#  EXECUÇÃO PRINCIPAL
# =============================================================

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✘ Execute como root: sudo bash ./09_ambiente.sh${NC}"
    exit 1
fi

header

ask_yn "Deseja configurar resolução e ambiente OPENBOX?" "s" EXECUTAR
if [ "$EXECUTAR" = "n" ]; then
    echo -e "  ${YELLOW}Passo ignorado.${NC}\n"
    exit 0
fi

echo ""
configure_resolution
configure_openbox
verify

echo -e "${GREEN}${BOLD}  ✔ Ambiente configurado!${NC}\n"
