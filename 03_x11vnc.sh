#!/bin/bash
# =============================================================
#  03_x11vnc.sh – Configuração do Serviço X11VNC
#  Baratão da Carne | TI – Sistemas e Infraestrutura
# =============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SERVICE_FILE="/etc/systemd/system/x11vnc.service"
PASS_FILE="/etc/x11vnc.pass"

# =============================================================
#  FUNÇÕES
# =============================================================

header() {
    clear
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}  ${BOLD}BARATÃO DA CARNE – Configuração X11VNC (PDV)${NC}        ${RED}║${NC}"
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

# =============================================================
#  EXECUÇÃO PRINCIPAL
# =============================================================

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✘ Execute como root: sudo bash ./03_x11vnc.sh${NC}"
    exit 1
fi

header

ask_yn "Deseja configurar o serviço X11VNC?" "s" EXECUTAR
if [ "$EXECUTAR" = "n" ]; then
    echo -e "  ${YELLOW}Passo ignorado.${NC}"
    echo ""
    exit 0
fi

echo ""

# Verifica arquivo de senha
if [ ! -f "$PASS_FILE" ]; then
    echo -e "  ${YELLOW}⚠ Arquivo $PASS_FILE não encontrado.${NC}"
    echo -e "  O x11vnc não iniciará sem ele."
    echo -e "  Crie com: ${CYAN}x11vnc -storepasswd /etc/x11vnc.pass${NC}"
    echo ""
    ask_yn "Deseja continuar mesmo assim?" "n" CONTINUAR
    if [ "$CONTINUAR" = "n" ]; then
        echo -e "  ${RED}Operação cancelada.${NC}"
        exit 1
    fi
fi

# Cria o arquivo de serviço
echo -e "  Criando $SERVICE_FILE ..."

tee "$SERVICE_FILE" > /dev/null <<'EOF'
[Unit]
Description=Start x11vnc at startup
After=display-manager.service

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -forever -shared -display :0 -auth guess -rfbauth /etc/x11vnc.pass
ExecStop=/bin/kill -s TERM $MAINPID
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo -e "  ${GREEN}✔ Arquivo de serviço criado.${NC}"

# Ativa e inicia
echo -e "  Recarregando daemon e ativando serviço..."
systemctl daemon-reload
systemctl enable x11vnc.service
systemctl restart x11vnc.service

echo -e "  ${GREEN}✔ Serviço ativado e iniciado.${NC}"

# Verificação
echo ""
echo -e "  ${BOLD}Verificação final:${NC}"
echo ""

STATUS=$(systemctl is-active x11vnc.service 2>/dev/null)
if [ "$STATUS" = "active" ]; then
    echo -e "  ${GREEN}✔ x11vnc está ATIVO e rodando.${NC}"
else
    echo -e "  ${YELLOW}⚠ Status do serviço: $STATUS${NC}"
    echo -e "  Verifique com: ${CYAN}systemctl status x11vnc.service${NC}"
fi

echo ""
echo -e "${GREEN}${BOLD}  ✔ Configuração do X11VNC concluída!${NC}"
echo ""
