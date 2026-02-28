#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
# VPS External Access — Fix OpenClaw bind to 0.0.0.0 + open UFW ports
# Execute on the VPS as root: bash vps_external_access.sh
# ──────────────────────────────────────────────────────────────────────────────

set -e
echo "🔧 Configurando acesso externo ao OpenClaw..."
echo "=============================================="

# ── Passo 1: Parar os serviços ──────────────────────────────────────────────
echo ""
echo "1️⃣  Parando serviços..."
systemctl --user stop openclaw-gateway.service 2>/dev/null || true
systemctl --user stop openclaw-control.service 2>/dev/null || true
sleep 2

# ── Passo 2: Editar o arquivo de serviço do gateway ─────────────────────────
echo ""
echo "2️⃣  Configurando gateway para escutar em 0.0.0.0..."
GATEWAY_SERVICE="$HOME/.config/systemd/user/openclaw-gateway.service"

if [ -f "$GATEWAY_SERVICE" ]; then
    echo "   Arquivo encontrado: $GATEWAY_SERVICE"
    cat "$GATEWAY_SERVICE"
    echo ""
    echo "   Editando ExecStart para adicionar --bind 0.0.0.0 ..."
    # Substituir a linha ExecStart para incluir --bind 0.0.0.0
    sed -i 's|ExecStart=.*openclaw gateway.*|ExecStart=/usr/local/bin/openclaw gateway --bind 0.0.0.0|' "$GATEWAY_SERVICE"
    # Se a linha não mudou (padrão diferente), tentar outra abordagem
    if grep -q "ExecStart=.*openclaw gateway" "$GATEWAY_SERVICE"; then
        echo "   ✅ ExecStart atualizado"
    else
        echo "   ⚠️  Linha ExecStart não encontrada com esse padrão. Conteúdo atual:"
        cat "$GATEWAY_SERVICE"
    fi
else
    echo "   ⚠️  Arquivo de serviço não encontrado em $GATEWAY_SERVICE"
    echo "   Criando novo arquivo de serviço..."
    mkdir -p "$HOME/.config/systemd/user"
    cat > "$GATEWAY_SERVICE" << 'SVCEOF'
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
ExecStart=/usr/local/bin/openclaw gateway --bind 0.0.0.0
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
SVCEOF
    echo "   ✅ Arquivo de serviço criado"
fi

# ── Passo 3: Editar o arquivo de serviço do control ─────────────────────────
echo ""
echo "3️⃣  Configurando control (painel) para escutar em 0.0.0.0..."
CONTROL_SERVICE="$HOME/.config/systemd/user/openclaw-control.service"

if [ -f "$CONTROL_SERVICE" ]; then
    echo "   Arquivo encontrado: $CONTROL_SERVICE"
    cat "$CONTROL_SERVICE"
    echo ""
    sed -i 's|ExecStart=.*openclaw control.*|ExecStart=/usr/local/bin/openclaw control --bind 0.0.0.0|' "$CONTROL_SERVICE"
    echo "   ✅ Control atualizado"
else
    echo "   ℹ️  Arquivo de control não encontrado (pode não ser necessário)"
fi

# ── Passo 4: Editar openclaw.json diretamente ────────────────────────────────
echo ""
echo "4️⃣  Verificando openclaw.json..."
OPENCLAW_JSON="$HOME/.openclaw/openclaw.json"
if [ -f "$OPENCLAW_JSON" ]; then
    echo "   Conteúdo atual:"
    cat "$OPENCLAW_JSON"
    echo ""
    # Usar python3 para editar o JSON com segurança
    python3 << PYEOF
import json, sys

with open("$OPENCLAW_JSON", "r") as f:
    config = json.load(f)

print("Config atual:", json.dumps(config, indent=2))

# Remover restrições de bind se existirem
changed = False
if "gateway" in config:
    if "bind" in config["gateway"]:
        del config["gateway"]["bind"]
        changed = True
        print("Removido: gateway.bind")
if "control" in config:
    if "bind" in config["control"]:
        del config["control"]["bind"]
        changed = True
        print("Removido: control.bind")

if changed:
    with open("$OPENCLAW_JSON", "w") as f:
        json.dump(config, f, indent=2)
    print("✅ openclaw.json atualizado")
else:
    print("ℹ️  Nenhuma alteração necessária no JSON")
PYEOF
else
    echo "   ℹ️  openclaw.json não encontrado"
fi

# ── Passo 5: Recarregar systemd ──────────────────────────────────────────────
echo ""
echo "5️⃣  Recarregando systemd..."
systemctl --user daemon-reload
echo "   ✅ daemon-reload OK"

# ── Passo 6: Reiniciar serviços ──────────────────────────────────────────────
echo ""
echo "6️⃣  Reiniciando serviços OpenClaw..."
systemctl --user start openclaw-gateway.service 2>/dev/null || true
sleep 3
systemctl --user start openclaw-control.service 2>/dev/null || true
sleep 3

# ── Passo 7: Verificar portas ────────────────────────────────────────────────
echo ""
echo "7️⃣  Verificando portas em uso..."
ss -tulpn | grep -E "18791|18789" || echo "   ⚠️  Portas não encontradas ainda"

# ── Passo 8: Configurar UFW ──────────────────────────────────────────────────
echo ""
echo "8️⃣  Configurando firewall UFW..."
if command -v ufw &>/dev/null; then
    ufw status
    ufw allow 18791/tcp comment "OpenClaw Control"
    ufw allow 18789/tcp comment "OpenClaw Gateway"
    echo "   ✅ Regras UFW adicionadas"
    ufw status numbered | grep -E "18791|18789"
else
    echo "   ℹ️  UFW não encontrado — verificando iptables..."
    iptables -I INPUT -p tcp --dport 18791 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p tcp --dport 18789 -j ACCEPT 2>/dev/null || true
    echo "   ✅ Regras iptables adicionadas"
fi

# ── Passo 9: Verificação final ───────────────────────────────────────────────
echo ""
echo "9️⃣  Verificação final..."
sleep 2
ss -tulpn | grep -E "18791|18789" | head -10 || echo "   ⚠️  Portas ainda não visíveis"

PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "IP não obtido")
echo ""
echo "=============================================="
echo "✅  CONFIGURAÇÃO CONCLUÍDA!"
echo "=============================================="
echo ""
echo "IP público da VPS: $PUBLIC_IP"
echo ""
echo "Teste de acesso externo:"
echo "  curl -s http://$PUBLIC_IP:18791 | head -5"
echo "  curl -s http://$PUBLIC_IP:18789 | head -5"
echo ""
echo "Se ainda não funcionar, execute manualmente:"
echo "  openclaw gateway --bind 0.0.0.0 &"
