#!/bin/bash
# =============================================================
#  06_pinpad_udev.sh – Configuração PinPad/Balança (udev)
#  Baratão da Carne | TI – Sistemas e Infraestrutura
# =============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

RULES_DST="/etc/udev/rules.d/99-usb-serial.rules"

# =============================================================
#  FUNÇÕES
# =============================================================

header() {
    clear
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}  ${BOLD}BARATÃO DA CARNE – PinPad e Balança (udev)${NC}          ${RED}║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

ask() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    local value=""
    echo -ne "  ${CYAN}▸ ${BOLD}$prompt${NC}"
    [ -n "$default" ] && echo -ne " ${YELLOW}[padrão: $default]${NC}"
    echo -ne ": "
    read value
    [ -z "$value" ] && value="$default"
    eval "$var_name='$value'"
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
#  GRAVAR REGRAS UDEV (conteúdo embutido no script)
# =============================================================

copy_rules() {
    echo -e "  ${BOLD}[1/4] Gravando regras udev...${NC}"
    echo ""

    # Faz backup se já existir
    if [ -f "$RULES_DST" ]; then
        cp "$RULES_DST" "${RULES_DST}.bak"
        echo -e "  ${DIM}Backup salvo em: ${RULES_DST}.bak${NC}"
    fi

    cat > "$RULES_DST" << 'RULESEOF'
#Gertec PPC900/910
KERNELS=="*[0-9]", DRIVERS=="cdc_acm", SUBSYSTEMS=="usb", ACTION=="add", ATTRS{modalias}=="usb:v1753pC901d0001dc02dsc00dp00ic02isc02ip01", SYMLINK+="ttyS60"
KERNELS=="*[0-9]", DRIVERS=="cdc_acm", SUBSYSTEMS=="usb", ACTION=="add", ATTRS{modalias}=="usb:v1753pC902d0001dc02dsc00dp00ic02isc02ip01in00", SYMLINK+="ttyS60"
KERNELS=="*[0-9]", DRIVERS=="cdc_acm", SUBSYSTEMS=="usb", ACTION=="add", ATTRS{modalias}=="usb:v1753pC902d0001dc02dsc00dp00ic0Aisc00ip00in01", SYMLINK+="ttyS60"

#Igenico IPP 320
KERNELS=="*[0-9]", DRIVERS=="cdc_acm", SUBSYSTEMS=="usb", ACTION=="add", ATTRS{modalias}=="usb:v079Bp0028d0000dc02dsc00dp00ic02isc02ip01in00", SYMLINK+="ttyS60"
KERNELS=="*[0-9]", DRIVERS=="cdc_acm", SUBSYSTEMS=="usb", ACTION=="add", ATTRS{modalias}=="usb:v079Bp0028d0000dc02dsc00dp00ic02isc02ip01", SYMLINK+="ttyS60"

#Scanner Elgin EL4200
KERNELS=="*[0-9]", DRIVERS=="cdc_acm", SUBSYSTEMS=="usb", ACTION=="add", ATTRS{modalias}=="usb:v0B7Fp0FE7d0101dc02dsc00dp00ic02isc02ip01in00", SYMLINK+="ttyS55"

#Sat Dimep
KERNELS=="*[0-9]", DRIVERS=="cdc_acm", SUBSYSTEMS=="usb", ACTION=="add", ATTRS{modalias}=="usb:v0525pA4A7d2499dc02dsc00dp00ic02isc02ip01in00", SYMLINK+="ttyS40"
KERNELS=="*[0-9]", DRIVERS=="cdc_acm", SUBSYSTEMS=="usb", ACTION=="add", ATTRS{modalias}=="usb:v1753p0A01d0312dcEFdsc02dp01ic02isc02ip01in00", SYMLINK+="ttyS40"

#Sat Gertec
KERNELS=="*[0-9]", DRIVERS=="cdc_acm", SUBSYSTEMS=="usb", ACTION=="add", ATTRS{modalias}=="usb:v1753p0A01d0312dcEFdsc02dp01ic02isc02ip01in00", SYMLINK+="ttyS40"

#Sat Bematech RB-2000
KERNELS=="*[0-9]", DRIVERS=="cdc_acm", SUBSYSTEMS=="usb", ACTION=="add", ATTRS{modalias}=="usb:v0B1Bp0109d*dc*dsc*dp*ic*isc*ip*in*", SYMLINK+="ttyS40"

#Balança Toledo 8217
KERNELS=="*[0-9]", DRIVERS=="cdc_acm", SUBSYSTEMS=="usb", ACTION=="add", ATTRS{modalias}=="usb:v1509p2206d0100dc02dsc00dp00ic02isc02ip01in00", SYMLINK+="ttyS45"

#Daruma DR800
KERNELS=="*[0-9]", DRIVERS=="cdc_acm", SUBSYSTEMS=="usb", ACTION=="add", ATTRS{modalias}=="usb:v23B8p0005d*dc*dsc*dp*ic*isc*ip*in*", SYMLINK+="ttyACM9"

#Daruma DR700
KERNELS=="*[0-9]", DRIVERS=="ftdi_sio", SUBSYSTEMS=="usb", ACTION=="add", ATTRS{modalias}=="usb:v0403p6001d*dc*dsc*dp*ic*isc*ip*in*", SYMLINK+="ttyUSB9"

#Bematech MP-4200TH
KERNELS=="*[0-9]", DRIVERS=="cdc_acm", SUBSYSTEMS=="usb", ACTION=="add", ATTRS{modalias}=="usb:v0B1Bp0003d0001dc02dsc00dp00ic02isc02ip01in00", SYMLINK+="ttyS50", OWNER="lp", GROUP="lp", MODE="0666"
KERNELS=="*[0-9]", DRIVERS=="cdc_acm", SUBSYSTEMS=="usb", ACTION=="add", ATTRS{modalias}=="usb:v0B1Bp0003d0001dc02dsc00dp00ic0Aisc00ip00in01", SYMLINK+="ttyS50", OWNER="lp", GROUP="lp", MODE="0666"
KERNELS=="*[0-9]", DRIVERS=="cdc_acm", SUBSYSTEMS=="usb", ACTION=="add", ATTRS{modalias}=="usb:v0B1Bp0003d0001dc02dsc00dp00ic02isc02ip00", SYMLINK+="ttyS50", OWNER="lp", GROUP="lp", MODE="0666"

#Sweda SI300
KERNELS=="*[0-9]", DRIVERS=="cdc_acm", SUBSYSTEMS=="usb", ACTION=="add", ATTRS{modalias}=="usb:v1C8Ap3001d0100dc02dsc00dp00ic02isc02ip01in00", SYMLINK+="ttyS50", OWNER="lp", GROUP="lp", MODE="0666"

#MP-4200TH
KERNEL=="*[0-9]", SUBSYSTEM=="usb", ACTION=="add", ATTRS{idVendor}=="0b1b", ATTRS{idProduct}=="0003", SYMLINK+="/dev/ttyS50", OWNER="lp", GROUP="lp", MODE="0666"
SUBSYSTEM=="tty", ACTION=="add", ATTRS{idVendor}=="0b1b", ATTRS{idProduct}=="0003", SYMLINK+="/dev/ttyS50", OWNER="lp", GROUP="lp", MODE="0666"
SUBSYSTEM=="tty", ACTION=="add", ATTRS{idVendor}=="0b1b", ATTRS{idProduct}=="0103", SYMLINK+="/dev/ttyS50", OWNER="lp", GROUP="lp", MODE="0666"
SUBSYSTEM=="tty", ACTION=="add", ATTRS{idVendor}=="2843", ATTRS{idProduct}=="0000", SYMLINK+="/dev/ttyS50", OWNER="lp", GROUP="lp", MODE="0666"
SUBSYSTEM=="tty", ACTION=="add", ATTRS{idVendor}=="0b1b", ATTRS{idProduct}=="0001", SYMLINK+="/dev/ttyS50", OWNER="lp", GROUP="lp", MODE="0666"

#MP4000TH
SUBSYSTEM=="usb", ACTION=="add", ATTRS{idVendor}=="0b1b", ATTRS{idProduct}=="0001", MODE="0777", GROUP="lp"

#MP4200TH
SUBSYSTEM=="usb", ACTION=="add", ATTRS{idVendor}=="0b1b", ATTRS{idProduct}=="0003", MODE="0777", GROUP="lp"

#MP2500TH
SUBSYSTEM=="usb", ACTION=="add", ATTRS{idVendor}=="0b1b", ATTRS{idProduct}=="0004", MODE="0777", GROUP="lp"

#Gertec PPC930 / RS232-USB (wildcard)
KERNELS=="*[0-9]", DRIVERS=="cdc_acm", SUBSYSTEMS=="usb", ACTION=="add", ATTRS{modalias}=="usb:v1753pC902d*dc*dsc*dp*ic*isc*ip*in*", SYMLINK+="ttyS60"
KERNELS=="*[0-9]", DRIVERS=="cdc_acm", SUBSYSTEMS=="usb", ACTION=="add", ATTRS{modalias}=="usb:v16C0p06EAd*dc*dsc*dp*ic*isc*ip*in*", SYMLINK+="ttyS45"
RULESEOF

    chmod 644 "$RULES_DST"
    echo -e "  ${GREEN}✔ Regras gravadas em: ${CYAN}$RULES_DST${NC}"
    echo ""
}

# =============================================================
#  LISTAR USB E CRUZAR COM REGRAS
# =============================================================

show_usb_devices() {
    echo -e "  ${BOLD}[2/4] Dispositivos USB conectados:${NC}"
    echo ""

    # Lista conhecida de vendor:product → descrição + porta mapeada
    declare -A KNOWN_DEVICES
    KNOWN_DEVICES["1753:c901"]="Gertec PPC900/910          → ttyS60"
    KNOWN_DEVICES["1753:c902"]="Gertec PPC930 PinPad       → ttyS60"
    KNOWN_DEVICES["079b:0028"]="Ingenico IPP320            → ttyS60"
    KNOWN_DEVICES["0b7f:0fe7"]="Scanner Elgin EL4200       → ttyS55"
    KNOWN_DEVICES["0525:a4a7"]="SAT Dimep                  → ttyS40"
    KNOWN_DEVICES["1753:0a01"]="SAT Gertec                 → ttyS40"
    KNOWN_DEVICES["0b1b:0109"]="SAT Bematech RB-2000       → ttyS40"
    KNOWN_DEVICES["1509:2206"]="Balança Toledo 8217        → ttyS45"
    KNOWN_DEVICES["16c0:06ea"]="RS232 to USB (balança)     → ttyS45"
    KNOWN_DEVICES["23b8:0005"]="Daruma DR800               → ttyACM9"
    KNOWN_DEVICES["0403:6001"]="Daruma DR700               → ttyUSB9"
    KNOWN_DEVICES["0b1b:0003"]="Bematech MP-4200TH         → ttyS50"
    KNOWN_DEVICES["0b1b:0001"]="Bematech MP-4000TH         → ttyS50"
    KNOWN_DEVICES["1c8a:3001"]="Sweda SI300                → ttyS50"

    local lsusb_out
    lsusb_out=$(lsusb 2>/dev/null)

    local found_unknown=false

    while IFS= read -r line; do
        # Extrai ID do dispositivo (vendorid:productid)
        local id
        id=$(echo "$line" | grep -oP 'ID \K[0-9a-fA-F]{4}:[0-9a-fA-F]{4}' | tr '[:upper:]' '[:lower:]')
        local desc
        desc=$(echo "$line" | sed 's/.*ID [^ ]* //')

        if [ -n "${KNOWN_DEVICES[$id]}" ]; then
            echo -e "  ${GREEN}✔${NC} ${CYAN}$id${NC}  $desc"
            echo -e "     ${GREEN}└─ Mapeado: ${KNOWN_DEVICES[$id]}${NC}"
        else
            # Ignora hubs USB genéricos (1d6b)
            local vendor
            vendor=$(echo "$id" | cut -d: -f1)
            if [ "$vendor" != "1d6b" ] && [ "$vendor" != "413c" ] && \
               [ "$vendor" != "04b8" ] && [ "$vendor" != "05f9" ]; then
                echo -e "  ${YELLOW}?${NC}  ${CYAN}$id${NC}  $desc"
                echo -e "     ${YELLOW}└─ Não encontrado nas regras${NC}"
                found_unknown=true
            else
                echo -e "  ${DIM}  $id  $desc${NC}"
            fi
        fi
    done <<< "$lsusb_out"

    echo ""

    if $found_unknown; then
        echo -e "  ${YELLOW}⚠ Há dispositivos não mapeados. Você pode adicioná-los no próximo passo.${NC}"
    else
        echo -e "  ${GREEN}✔ Todos os periféricos relevantes estão mapeados nas regras.${NC}"
    fi
    echo ""
}

# =============================================================
#  ADICIONAR NOVO DISPOSITIVO (lógica do udev_.sh)
# =============================================================

add_device() {
    echo -e "  ${BOLD}[3/4] Adicionar dispositivo às regras:${NC}"
    echo ""
    echo -e "  Informe os dados do dispositivo USB (visíveis no lsusb acima)."
    echo -e "  Deixe ${BOLD}PORTA em branco${NC} para registrar sem symlink fixo."
    echo ""

    ask "VENDOR (ex: 1753)" "" VENDOR
    ask "PRODUCT (ex: c902)" "" PRODUCT
    ask "PORTA (ex: ttyS60 — ou Enter para deixar vazio)" "" PORTA

    VENDOR="${VENDOR^^}"
    PRODUCT="${PRODUCT^^}"
    MODALIAS="usb:v${VENDOR}p${PRODUCT}d*dc*dsc*dp*ic*isc*ip*in*"

    echo ""
    echo -e "  Regra que será adicionada:"
    echo -e "  ${DIM}KERNELS==\"*[0-9]\", DRIVERS==\"cdc_acm\", SUBSYSTEMS==\"usb\", ACTION==\"add\", ATTRS{modalias}==\"$MODALIAS\", SYMLINK+=\"$PORTA\"${NC}"
    echo ""

    ask_yn "Confirmar e adicionar?" "s" CONFIRMA
    if [ "$CONFIRMA" = "s" ]; then
        cat >> "$RULES_DST" <<EOF

# Adicionado em $(date '+%d/%m/%Y %H:%M') via script
KERNELS=="*[0-9]", DRIVERS=="cdc_acm", SUBSYSTEMS=="usb", ACTION=="add", ATTRS{modalias}=="$MODALIAS", SYMLINK+="$PORTA"
EOF
        echo -e "  ${GREEN}✔ Dispositivo adicionado ao arquivo de regras.${NC}"
    else
        echo -e "  ${YELLOW}Dispositivo não adicionado.${NC}"
    fi
    echo ""
}

# =============================================================
#  RECARREGAR UDEV E VERIFICAR
# =============================================================

reload_udev() {
    echo -e "  ${BOLD}[4/4] Recarregando regras udev...${NC}"
    echo ""

    udevadm control --reload-rules
    udevadm trigger
    sleep 2

    echo -e "  ${GREEN}✔ Regras recarregadas.${NC}"
    echo ""
    echo -e "  ${BOLD}Portas seriais reconhecidas pelo kernel:${NC}"
    echo ""
    dmesg | grep -i tty | tail -20 | sed 's/^/    /'
    echo ""
    echo -e "  ${BOLD}Symlinks criados em /dev:${NC}"
    ls -la /dev/ttyS4* /dev/ttyS5* /dev/ttyS6* /dev/ttyACM* /dev/ttyUSB* 2>/dev/null \
        | grep -v "^total" | sed 's/^/    /' \
        || echo -e "    ${DIM}(nenhum symlink encontrado ainda — reconecte os dispositivos)${NC}"
    echo ""
}

# =============================================================
#  EXECUÇÃO PRINCIPAL
# =============================================================

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✘ Execute como root: sudo bash ./06_pinpad_udev.sh${NC}"
    exit 1
fi

header

ask_yn "Deseja configurar PinPad/Balança (udev)?" "s" EXECUTAR
if [ "$EXECUTAR" = "n" ]; then
    echo -e "  ${YELLOW}Passo ignorado.${NC}"
    echo ""
    exit 0
fi

echo ""
copy_rules
show_usb_devices

ask_yn "Deseja adicionar um dispositivo não mapeado?" "n" ADD_DEVICE
echo ""
if [ "$ADD_DEVICE" = "s" ]; then
    add_device
    ask_yn "Adicionar mais um dispositivo?" "n" ADD_MAIS
    while [ "$ADD_MAIS" = "s" ]; do
        add_device
        ask_yn "Adicionar mais um dispositivo?" "n" ADD_MAIS
    done
fi

reload_udev

echo -e "${GREEN}${BOLD}  ✔ Configuração de PinPad/Balança concluída!${NC}"
echo ""
