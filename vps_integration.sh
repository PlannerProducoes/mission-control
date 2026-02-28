#!/bin/bash
# ──────────────────────────────────────────────────────────────
# Mission Control — VPS Integration Script
# Configura os 4 agentes para reportar ao Convex em tempo real
# ──────────────────────────────────────────────────────────────

CONVEX_URL="https://vivid-mule-180.convex.cloud"
WORKSPACE_DIR="$HOME/.openclaw/workspace"

echo "🚀 Mission Control — Integração VPS"
echo "======================================"

# ── 1. Criar HEARTBEAT.md compartilhado ──
cat > "$WORKSPACE_DIR/HEARTBEAT.md" << 'HEARTBEAT_EOF'
# Heartbeat Protocol — Mission Control

When you receive a heartbeat trigger, follow this exact procedure:

## Step 1: Report Status
Use the shell tool to call the Mission Control API:

```bash
curl -s -X POST https://vivid-mule-180.convex.site/api/heartbeat \
  -H "Content-Type: application/json" \
  -d '{"agentId": "YOUR_AGENT_ID", "status": "active"}'
```

Replace YOUR_AGENT_ID with your actual agent ID from IDENTITY.md.

## Step 2: Check Pending Work
The heartbeat response will contain:
- `notifications`: Any @mentions or assignments for you
- `tasks`: Tasks currently assigned to you

Review these and:
1. If there are new tasks assigned → Start working on the highest priority one
2. If there are @mentions → Read the context and respond appropriately
3. If nothing pending → Reply HEARTBEAT_OK

## Step 3: Update Task Status
If you complete or make progress on a task, update it:

```bash
curl -s -X POST https://vivid-mule-180.convex.cloud/api/tasks/create \
  -H "Content-Type: application/json" \
  -d '{"title": "TASK_TITLE", "status": "in_progress", "priority": "normal", "createdBy": "YOUR_AGENT_ID", "assignedTo": "YOUR_AGENT_ID"}'
```

## Step 4: Log Activity
After taking any action, it will be automatically logged to the Mission Control Live Feed.

## Important Rules
- Always report your heartbeat FIRST before doing any other work
- Keep task titles concise and descriptive
- Use priorities: "urgent", "high", "normal", "low"
- Use statuses: "inbox", "assigned", "in_progress", "review", "blocked", "done"
HEARTBEAT_EOF

echo "✅ HEARTBEAT.md criado"

# ── 2. Criar script de heartbeat individual para cada agente ──
mkdir -p "$HOME/.openclaw/scripts"

# Jarvis (Squad Lead)
cat > "$HOME/.openclaw/scripts/heartbeat_squad_lead.sh" << 'EOF'
#!/bin/bash
curl -s -X POST https://vivid-mule-180.convex.site/api/heartbeat \
  -H "Content-Type: application/json" \
  -d '{"agentId": "squad_lead", "status": "active", "name": "Jarvis", "emoji": "🎯", "role": "Chief of Staff", "model":"openrouter/deepseek/deepseek-v3.2"}'
EOF

# Investidor Pro
cat > "$HOME/.openclaw/scripts/heartbeat_investidor.sh" << 'EOF'
#!/bin/bash
curl -s -X POST https://vivid-mule-180.convex.site/api/heartbeat \
  -H "Content-Type: application/json" \
  -d '{"agentId": "investidor_pro", "status": "active", "name": "Investidor Pro", "emoji": "📈", "role": "Investment Analyst", "model":"openrouter/minimax/minimax-m2.5"}'
EOF

# Bibliotecária IA
cat > "$HOME/.openclaw/scripts/heartbeat_bibliotecaria.sh" << 'EOF'
#!/bin/bash
curl -s -X POST https://vivid-mule-180.convex.site/api/heartbeat \
  -H "Content-Type: application/json" \
  -d '{"agentId": "bibliotecaria_ia", "status": "active", "name": "Bibliotecária IA", "emoji": "📚", "role": "Knowledge Curator", "model":"openrouter/google/gemini-2.0-flash-001"}'
EOF

# Estrategista Growth
cat > "$HOME/.openclaw/scripts/heartbeat_estrategista.sh" << 'EOF'
#!/bin/bash
curl -s -X POST https://vivid-mule-180.convex.site/api/heartbeat \
  -H "Content-Type: application/json" \
  -d '{"agentId": "estrategista", "status": "active", "name": "Estrategista", "emoji": "🚀", "role": "Business Strategist", "model":"openrouter/x-ai/grok-2-1212"}'
EOF

chmod +x $HOME/.openclaw/scripts/heartbeat_*.sh
echo "✅ Scripts de heartbeat criados"

# ── 3. Configurar crons escalonados (a cada 15 min, offset de 5 min) ──
# Remove crons antigos do mission control
crontab -l 2>/dev/null | grep -v "heartbeat_" > /tmp/cron_clean
# Adiciona novos crons escalonados
echo "*/15 * * * * $HOME/.openclaw/scripts/heartbeat_squad_lead.sh >> /tmp/heartbeat.log 2>&1" >> /tmp/cron_clean
echo "5,20,35,50 * * * * $HOME/.openclaw/scripts/heartbeat_investidor.sh >> /tmp/heartbeat.log 2>&1" >> /tmp/cron_clean
echo "10,25,40,55 * * * * $HOME/.openclaw/scripts/heartbeat_bibliotecaria.sh >> /tmp/heartbeat.log 2>&1" >> /tmp/cron_clean
echo "3,18,33,48 * * * * $HOME/.openclaw/scripts/heartbeat_estrategista.sh >> /tmp/heartbeat.log 2>&1" >> /tmp/cron_clean
crontab /tmp/cron_clean
rm /tmp/cron_clean
echo "✅ Crons escalonados configurados"

# ── 4. Teste imediato — dispara heartbeat de todos os agentes ──
echo ""
echo "🔄 Testando heartbeats..."
echo "--- Squad Lead ---"
bash $HOME/.openclaw/scripts/heartbeat_squad_lead.sh
echo ""
echo "--- Investidor Pro ---"
bash $HOME/.openclaw/scripts/heartbeat_investidor.sh
echo ""
echo "--- Bibliotecária IA ---"
bash $HOME/.openclaw/scripts/heartbeat_bibliotecaria.sh
echo ""
echo "--- Estrategista ---"
bash $HOME/.openclaw/scripts/heartbeat_estrategista.sh
echo ""

echo ""
echo "✅ ============================="
echo "✅  MISSION CONTROL INTEGRADO!"
echo "✅ ============================="
echo ""
echo "Heartbeats escalonados a cada 15 min:"
echo "  :00 :15 :30 :45 → Jarvis (Squad Lead)"
echo "  :05 :20 :35 :50 → Investidor Pro"
echo "  :10 :25 :40 :55 → Bibliotecária IA"
echo "  :03 :18 :33 :48 → Estrategista Growth"
echo ""
echo "Dashboard: https://plannerproducoes.github.io/mission-control/"
echo "Convex:    $CONVEX_URL"
