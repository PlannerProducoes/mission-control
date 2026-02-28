#!/bin/bash
# ══════════════════════════════════════════════════════════════
# Mission Control — Deploy + Integração Completa na VPS
# ══════════════════════════════════════════════════════════════

CONVEX_URL="https://vivid-mule-180.convex.cloud"

echo "🚀 Mission Control — Deploy Completo"
echo "======================================"

# ── 1. Instalar e configurar o dashboard ──
echo "[1/5] Preparando diretório do dashboard..."
mkdir -p ~/mission-control/dist
mkdir -p ~/.openclaw/scripts

# ── 2. Criar o servidor estático ──
echo "[2/5] Criando servidor do dashboard..."
cat > ~/mission-control/serve.js << 'SERVEREOF'
const http = require('http');
const fs = require('fs');
const path = require('path');
const PORT = 3000;
const DIST = path.join(__dirname, 'dist');
const MIME = {'.html':'text/html','.js':'application/javascript','.css':'text/css','.json':'application/json','.svg':'image/svg+xml'};
http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  let fp = path.join(DIST, req.url === '/' ? 'index.html' : req.url);
  if (!fs.existsSync(fp)) fp = path.join(DIST, 'index.html');
  const ct = MIME[path.extname(fp)] || 'application/octet-stream';
  try { const c = fs.readFileSync(fp); res.writeHead(200, {'Content-Type': ct}); res.end(c); }
  catch { res.writeHead(404); res.end('Not Found'); }
}).listen(PORT, '0.0.0.0', () => console.log('🚀 Mission Control on http://0.0.0.0:' + PORT));
SERVEREOF

# ── 3. Criar scripts de heartbeat ──
echo "[3/5] Criando scripts de heartbeat..."

cat > ~/.openclaw/scripts/heartbeat_squad_lead.sh << 'EOF'
#!/bin/bash
curl -s -X POST https://vivid-mule-180.convex.site/api/heartbeat \
  -H "Content-Type: application/json" \
  -d '{"agentId":"squad_lead","status":"active","name":"Jarvis","emoji":"🎯","role":"Chief of Staff","model":"openrouter/deepseek/deepseek-v3.2"}'
EOF

cat > ~/.openclaw/scripts/heartbeat_investidor.sh << 'EOF'
#!/bin/bash
curl -s -X POST https://vivid-mule-180.convex.site/api/heartbeat \
  -H "Content-Type: application/json" \
  -d '{"agentId":"investidor_pro","status":"active","name":"Investidor Pro","emoji":"📈","role":"Investment Analyst","model":"openrouter/minimax/minimax-m2.5"}'
EOF

cat > ~/.openclaw/scripts/heartbeat_bibliotecaria.sh << 'EOF'
#!/bin/bash
curl -s -X POST https://vivid-mule-180.convex.site/api/heartbeat \
  -H "Content-Type: application/json" \
  -d '{"agentId":"bibliotecaria_ia","status":"active","name":"Bibliotecária IA","emoji":"📚","role":"Knowledge Curator","model":"openrouter/google/gemini-2.0-flash-001"}'
EOF

cat > ~/.openclaw/scripts/heartbeat_estrategista.sh << 'EOF'
#!/bin/bash
curl -s -X POST https://vivid-mule-180.convex.site/api/heartbeat \
  -H "Content-Type: application/json" \
  -d '{"agentId":"estrategista","status":"active","name":"Estrategista","emoji":"🚀","role":"Business Strategist","model":"openrouter/x-ai/grok-2-1212"}'
EOF

chmod +x ~/.openclaw/scripts/heartbeat_*.sh

# ── 4. Configurar crons escalonados ──
echo "[4/5] Configurando crons escalonados..."
crontab -l 2>/dev/null | grep -v "heartbeat_" > /tmp/cron_clean
echo "*/15 * * * * ~/.openclaw/scripts/heartbeat_squad_lead.sh >> /tmp/heartbeat.log 2>&1" >> /tmp/cron_clean
echo "5,20,35,50 * * * * ~/.openclaw/scripts/heartbeat_investidor.sh >> /tmp/heartbeat.log 2>&1" >> /tmp/cron_clean
echo "10,25,40,55 * * * * ~/.openclaw/scripts/heartbeat_bibliotecaria.sh >> /tmp/heartbeat.log 2>&1" >> /tmp/cron_clean
echo "3,18,33,48 * * * * ~/.openclaw/scripts/heartbeat_estrategista.sh >> /tmp/heartbeat.log 2>&1" >> /tmp/cron_clean
crontab /tmp/cron_clean
rm /tmp/cron_clean

# ── 5. Testar heartbeats ──
echo "[5/5] Testando heartbeats em tempo real..."
echo ""
echo "--- Squad Lead (Jarvis) ---"
bash ~/.openclaw/scripts/heartbeat_squad_lead.sh
echo ""
echo "--- Investidor Pro ---"
bash ~/.openclaw/scripts/heartbeat_investidor.sh
echo ""
echo "--- Bibliotecária IA ---"
bash ~/.openclaw/scripts/heartbeat_bibliotecaria.sh
echo ""
echo "--- Estrategista ---"
bash ~/.openclaw/scripts/heartbeat_estrategista.sh
echo ""

# ── 6. Iniciar o servidor do dashboard ──
echo ""
echo "Iniciando dashboard na porta 3000..."
pkill -f "node.*serve.js" 2>/dev/null
nohup node ~/mission-control/serve.js > ~/mission-control/dashboard.log 2>&1 &
sleep 2

echo ""
echo "✅ ======================================="
echo "✅  MISSION CONTROL — DEPLOY COMPLETO!"
echo "✅ ======================================="
echo ""
echo "📊 Dashboard:  http://187.77.51.5:3000"
echo "🔄 Convex:     $CONVEX_URL"
echo ""
echo "⏰ Heartbeats escalonados:"
echo "   :00 :15 :30 :45 → 🎯 Jarvis"
echo "   :05 :20 :35 :50 → 📈 Investidor Pro"
echo "   :10 :25 :40 :55 → 📚 Bibliotecária IA"
echo "   :03 :18 :33 :48 → 🚀 Estrategista"
echo ""
crontab -l | grep heartbeat
