const fs = require('fs');
const path = require('path');
const https = require('https');

/**
 * DICIONÁRIO DE INTELIGÊNCIA EXECUTIVA (CÉREBRO DO PROJETO)
 * Mapeamento semântico dos componentes vitais para o Obsidian.
 */
const KNOWLEDGE_BASE = {
    // --- CORE & PERSISTÊNCIA ---
    'realtime_db_service.dart': {
        purpose: 'Cérebro da Persistência Multi-Conta. Gerencia o Firebase Realtime Database e sincronização dinâmica.',
        tags: ['#camada/service', '#tecnologia/firebase', '#modulo/persistência'],
        functions: [
            'getOmieAccounts: Orquestra o carregamento de contas tratando variações de formato (Map/List).',
            'saveOmieSyncData: Cache de longo prazo para performance e economia de chamadas de API.',
            'initializeNewUser: Bootstrapping de novos usuários com categorias padrão e perfil.'
        ]
    },
    'omie_service.dart': {
        purpose: 'Conectividade ERP. Gateway de comunicação direta com a API financeira da Omie.',
        tags: ['#camada/service', '#tecnologia/api-rest', '#modulo/omie'],
        functions: [
            'getFinancialSummary: Snapshot de saldo e fluxo projetado com cache inteligente.',
            'listAccountsReceivable: Recuperação de títulos a receber com paginação automática.',
            'payBill: Baixa de títulos e pagamentos via API.'
        ]
    },

    // --- MOTORES DE INTELIGÊNCIA (AI) ---
    'ai_insight_service.dart': {
        purpose: 'Agente Financeiro IA. Transforma dados brutos em decisões executivas via Gemini 1.5 Flash.',
        tags: ['#camada/service', '#tecnologia/ia', '#modulo/agente'],
        functions: [
            'generateInsights: Narrativas de decisão baseadas em KPIs reais.',
            'analyzeOverduePayments: Detecção de inadimplência com sugestão de cobrança proativa.'
        ]
    },
    'anomaly_service.dart': {
        purpose: 'Guardião de Segurança. Detecta desvios, duplicidades e anomalias estatísticas.',
        tags: ['#camada/service', '#modulo/seguranca', '#modulo/ia'],
        functions: [
            'detectAnomalies: Motor heurístico para identificar lançamentos suspeitos.'
        ]
    },

    // --- OPERAÇÕES & DADOS ---
    'pdf_report_service.dart': {
        purpose: 'Módulo de Reporting Executivo. Gera PDFs profissionais (DRE, Fluxo de Caixa, Multi-Empresa).',
        tags: ['#camada/service', '#modulo/relatorio', '#saida/pdf'],
        functions: [
            'generateExecutiveReport: Relatório premium de performance mensal.',
            'generateMultiCompany6MonthReport: Visão consolidada de holding (Sigma/Micro/Manut).'
        ]
    },
    'bank_import_service.dart': {
        purpose: 'Conciliação Bancária IA. Processa extratos (OFX/CSV) e categoriza via LLM.',
        tags: ['#camada/service', '#modulo/conciliacao', '#tecnologia/ia'],
        functions: [
            'parseOFX: Extrator de dados bancários padrão.',
            'enrichWithAI: Categorização automática de lançamentos usando Gemini.'
        ]
    },

    // --- DASHBOARDS & UX ---
    'war_room_screen.dart': {
        purpose: 'Sala de Guerra. Painel executivo tempo real com foco em Margens e Runway.',
        tags: ['#camada/ui', '#modulo/dashboard', '#status/premium'],
        functions: [
            'buildKpiCards: Monitoramento crítico de EBITDA e Fluxo Operacional.'
        ]
    },
    'simulation_screen.dart': {
        purpose: 'Simulador "What If". Laboratório de projeções neon para análise de riscos e investimentos.',
        tags: ['#camada/ui', '#modulo/simulacao', '#status/premium'],
        functions: [
            'calculateWhatIfScenario: Motor matemático para projeção de 6 meses de caixa.'
        ]
    }
};

const CONFIG = {
    apiKey: '10daf2dc912d777237d3236b9a011413e8c89fbfcfec3e6170886979c3dcb592',
    baseUrl: '127.0.0.1',
    port: 27124,
    mapping: {
        'core': '01 - Core & Fundamentos',
        'services': '02 - Negocio & Integracoes',
        'providers': '03 - Fluxo de Dados (State)',
        'models': '04 - Entidades (Models)',
        'screens': '05 - Telas & Fluxos',
        'widgets': '06 - Componentes Reutilizaveis'
    }
};

const agent = new https.Agent({ rejectUnauthorized: false });

/**
 * MAPEAMENTO DE ARQUIVOS (Para Linkagem Automática)
 */
const FILE_MAP = {};
function buildFileMap(dir) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory()) buildFileMap(fullPath);
        else if (file.endsWith('.dart')) {
            FILE_MAP[file.replace('.dart', '')] = file;
        }
    }
}

function transformToMarkdown(fileName, content, relPath) {
    const baseName = fileName.replace('.dart', '');
    const info = KNOWLEDGE_BASE[fileName] || { 
        purpose: 'Componente modular do sistema.', 
        tags: [`#camada/${relPath.split(path.sep)[0] || 'outros'}`],
        functions: [] 
    };

    // 1. Tags Automáticas por Pasta
    const folderTags = [`#projeto/appfinancerio`];
    const folder = relPath.split(path.sep)[0];
    if (CONFIG.mapping[folder]) {
        folderTags.push(`#camada/${folder}`);
    }

    // 2. Linkagem Inteligente de Código
    let linkedContent = content;
    Object.keys(FILE_MAP).forEach(key => {
        if (key === baseName) return; // Não linkar o próprio arquivo
        
        // Expressão regular para encontrar a menção à classe/arquivo, garantindo que não seja parte de outra palavra
        const regex = new RegExp(`(?<!\\[\\[|\\/)\\b${key}\\b(?![\\w])`, 'g');
        if (regex.test(linkedContent)) {
            linkedContent = linkedContent.replace(regex, `[[${key}]]`);
        }
    });

    // 3. Montagem do Markdown com Frontmatter
    const allTags = [...new Set([...folderTags, ...(info.tags || [])])];
    
    return `---
title: ${fileName}
path: ${relPath}
tags: ${allTags.join(', ')}
last_sync: ${new Date().toISOString()}
---

# 📄 ${fileName}

> **Contexto**: \`${relPath}\` | ${allTags.join(' ')}

## 📝 Escopo & Propósito
${info.purpose}

### 🛠️ Funções & Inteligência
${info.functions && info.functions.length > 0 
    ? info.functions.map(f => `- **${f.split(':')[0]}**: ${f.split(':')[1]}`).join('\n')
    : '> *Funções detectadas automaticamente no código base.*'}

## 🔗 Grafo de Dependências
Arquivos citados neste módulo: ${Object.keys(FILE_MAP).filter(k => content.includes(k) && k !== baseName).map(k => `[[${k}]]`).join(', ') || 'Nativa'}

## 💻 Código Fonte (Réplica)

\`\`\`dart
${linkedContent}
\`\`\`

---
*Gerado por Antigravity Intelligent Engine v3.0 - Obsidian Sync*`;
}

async function sendToObsidian(filePath, content) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: CONFIG.baseUrl, port: CONFIG.port,
            path: `/vault/${encodeURIComponent(filePath)}`,
            method: 'PUT', agent: agent,
            headers: { 'Authorization': `Bearer ${CONFIG.apiKey}`, 'Content-Type': 'text/markdown' }
        };
        const req = https.request(options, (res) => {
            if (res.statusCode >= 200 && res.statusCode < 300) resolve();
            else reject(new Error(`Erro API: ${res.statusCode}`));
        });
        req.on('error', (e) => reject(e)); req.write(content); req.end();
    });
}

async function runSync() {
    console.log('🚀 Iniciando SYNC INTELIGENTE (Links + Tags + Frontmatter)...');
    const libPath = path.join(__dirname, 'lib');
    
    // Passo 1: Mapear todos os arquivos para linkagem
    buildFileMap(libPath);
    console.log(`📡 Scan concluído: ${Object.keys(FILE_MAP).length} arquivos mapeados.`);

    async function walk(dir) {
        const files = fs.readdirSync(dir);
        for (const file of files) {
            const fullPath = path.join(dir, file);
            if (fs.statSync(fullPath).isDirectory()) await walk(fullPath);
            else if (file.endsWith('.dart')) {
                const relPath = path.relative(libPath, fullPath);
                const folderKey = relPath.split(path.sep)[0];
                const folderName = CONFIG.mapping[folderKey] || '99 - Outros';
                const obsidianPath = `Projetos/GerePag/${folderName}/${file.replace('.dart', '.md')}`;
                
                const content = fs.readFileSync(fullPath, 'utf8');
                const markdown = transformToMarkdown(file, content, relPath);
                
                try {
                    await sendToObsidian(obsidianPath, markdown);
                    process.stdout.write('🔗');
                } catch (err) { process.stdout.write('❌'); }
            }
        }
    }
    await walk(libPath);
    console.log('\n\n✨ Sincronização Ultra-Linkada concluída!');
}

runSync();
