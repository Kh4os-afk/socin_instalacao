#!/bin/bash
# =============================================================
#  install.sh – Orquestrador de Instalação – PDV SOCIN
#  Baratão da Carne | TI – Sistemas e Infraestrutura
# =============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="/var/log/instalacao_pdv_socin.log"
TOTAL_STEPS=11  # atualizar conforme novos scripts forem adicionados

# =============================================================
#  FUNÇÕES UTILITÁRIAS
# =============================================================

header() {
    clear
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}       ${BOLD}BARATÃO DA CARNE – Instalação PDV SOCIN${NC}           ${RED}║${NC}"
    echo -e "${RED}║${NC}       ${DIM}TI – Sistemas e Infraestrutura${NC}                    ${RED}║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

step_header() {
    local step="$1"
    local title="$2"
    echo ""
    echo -e "${RED}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${RED}│${NC}  ${BOLD}[$step/$TOTAL_STEPS] $title${NC}"
    echo -e "${RED}└──────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

log() {
    echo "[$(date '+%d/%m/%Y %H:%M:%S')] $1" >> "$LOG_FILE"
}

run_step() {
    local step="$1"
    local title="$2"
    local script="$3"

    step_header "$step" "$title"

    # Verifica se o script existe
    if [ ! -f "$SCRIPTS_DIR/$script" ]; then
        echo -e "  ${YELLOW}⚠ Script $script não encontrado em $SCRIPTS_DIR${NC}"
        echo -e "  ${DIM}Passo ignorado automaticamente.${NC}"
        log "[$step/$TOTAL_STEPS] $title – IGNORADO (script não encontrado)"
        echo ""
        return
    fi

    # Executa o script
    log "[$step/$TOTAL_STEPS] $title – INICIADO"
    bash "$SCRIPTS_DIR/$script"
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo -e "  ${GREEN}✔ $title concluído.${NC}"
        log "[$step/$TOTAL_STEPS] $title – OK"
    else
        echo ""
        echo -e "  ${RED}✘ $title encerrou com erro (código $exit_code).${NC}"
        log "[$step/$TOTAL_STEPS] $title – ERRO (código $exit_code)"
        echo ""
        echo -ne "  ${YELLOW}Deseja continuar para o próximo passo? (s/n) [s]${NC}: "
        read resp
        [ -z "$resp" ] && resp="s"
        case "$resp" in
            n|N)
                echo -e "  ${RED}Instalação interrompida pelo usuário.${NC}"
                log "Instalação interrompida pelo usuário no passo $step"
                exit 1
                ;;
        esac
    fi
}

# =============================================================
#  INÍCIO
# =============================================================

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✘ Execute como root: sudo bash ./install.sh${NC}"
    exit 1
fi

header

echo -e "  Este script irá guiar a instalação completa do PDV SOCIN."
echo -e "  Cada passo pode ser executado ou ignorado individualmente."
echo -e "  Log salvo em: ${CYAN}$LOG_FILE${NC}"
echo ""
echo -ne "  ${YELLOW}▸ Iniciar instalação? (s/n) [s]${NC}: "
read resp_inicio
[ -z "$resp_inicio" ] && resp_inicio="s"
case "$resp_inicio" in
    n|N)
        echo -e "  ${YELLOW}Instalação cancelada.${NC}"
        exit 0
        ;;
esac

log "=========================================="
log "Instalação iniciada"
log "=========================================="

# =============================================================
#  PASSOS – adicione novos scripts aqui na ordem desejada
# =============================================================

run_step  1  "Configuração de Rede"              "01_rede.sh"
run_step  2  "Configuração X11VNC"               "03_x11vnc.sh"
run_step  3  "Instalação PDV eConect"            "04_pdv_econect.sh"
run_step  4  "IP do Concentrador (eConect)"      "02_concentrador.sh"
run_step  5  "Configuração Chama Caixa"          "05_chama_caixa.sh"
run_step  6  "PinPad e Balança (udev)"           "06_pinpad_udev.sh"
run_step  7  "Fuso Horário e NTP"                "07_hora.sh"
run_step  8  "Desabilitar Notif. Impressora"     "08_impressora.sh"
run_step  9  "Resolução e Ambiente OPENBOX"       "09_ambiente.sh"
run_step 10  "Finalização e Cópia de Arquivos"    "10_finalizar.sh"
run_step 11  "Cadastro de Clientes (Firefox)"     "11_cadastro_clientes.sh"

# =============================================================
#  FINALIZAÇÃO
# =============================================================

echo ""
echo -e "${RED}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║${NC}  ${GREEN}${BOLD}  ✔ Instalação concluída!${NC}                              ${RED}║${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Log completo disponível em: ${CYAN}$LOG_FILE${NC}"
echo ""

log "Instalação finalizada"
log "=========================================="
