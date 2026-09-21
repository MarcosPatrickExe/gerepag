# CHECKPOINT — Projeto GerePag

> Atualizado em 21 de setembro de 2026. Este documento registra o estado observado do repositório `MarcosPatrickExe/gerepag`, decisões tomadas, bloqueios e pendências. Ele deve ser usado como contexto inicial ao continuar o trabalho em outro chat ou em um Projeto do ChatGPT.

## 1. Objetivo da continuidade

Trabalhar exclusivamente em ambiente cloud, usando o GitHub como fonte de verdade. Analisar e evoluir o aplicativo Flutter/Dart, preservar a regra de negócio, melhorar segurança e arquitetura, automatizar validações e gerar AAB Android assinado. Toda alteração deve ocorrer em branch separada e por pull request; não alterar diretamente a `main`.

## 2. Estado remoto confirmado

- Repositório: `https://github.com/MarcosPatrickExe/gerepag`.
- Branch padrão observada: `main`.
- Commit remoto observado: `98e57331830d9f2e5c8d37b0d43c3a264a2eb0a2`.
- Mensagem do commit: `configurando projeto no meu repositorio`.
- O commit local anteriormente citado, `61aa41e`, não foi encontrado no GitHub.
- Não foram encontradas outras branches remotas durante a auditoria inicial.
- A integração GitHub voltou a permitir escrita em 21 de setembro de 2026.
- A branch `docs/checkpoint-gerepag` foi criada e este checkpoint foi enviado com sucesso.
- A permissão do aplicativo GitHub dentro do ChatGPT está configurada como `Permitir todas as ações`.

## 3. Visão do produto e regra de negócio

O GerePag é um copiloto financeiro pessoal e empresarial. O produto atende quatro públicos principais:

1. Autônomos e freelancers.
2. Pequenas e médias empresas, especialmente clientes do ERP Omie.
3. BPOs financeiros e contadores que administram diversos clientes.
4. Infoprodutores e afiliados que precisam recuperar vendas e cobranças.

Fluxo principal observado:

1. Inicialização do Firebase e serviços de notificação.
2. Autenticação e onboarding.
3. Carregamento de perfil, papel, nicho e assinatura.
4. Seleção de contexto pessoal, familiar ou empresarial.
5. Leitura de dados financeiros no Firebase.
6. Sincronização opcional de uma ou várias contas Omie.
7. Exibição de dashboards, DRE, fluxo de caixa, projeções, cobranças e relatórios.
8. Uso de IA, OCR e automações condicionado ao plano/limites do usuário.

Planos descritos na documentação atual:

- Grátis: dashboard básico, uma conta Omie e cotas pequenas de OCR/IA.
- PRO: IA/OCR, relatórios e simulação DRE.
- Business: multiempresa, equipe, alertas e recursos voltados a BPO.

Preços e limites aparecem em mais de um ponto. Eles devem ser centralizados no backend para impedir divergências e adulteração pelo cliente.

## 4. Arquitetura observada

| Área | Responsabilidade atual |
|---|---|
| `lib/main.dart` | Inicialização, Firebase, providers, onboarding e autenticação |
| `lib/models/` | Transações, carteiras, cartões, metas, desafios e objetos Omie/BI |
| `lib/providers/` | Estado global e regras; destaque para o grande `TransactionsProvider` |
| `lib/providers/transactions_provider/parts/` | Sincronização, CRM, forecast, operações, vendas, estoque, BI e simulação |
| `lib/services/` | Firebase, Omie, IA, OCR, voz, Stripe, exportação, biometria, FCM e widget |
| `lib/screens/` | Jornadas pessoais, empresariais, BPO, contador, assinatura e administração |
| `lib/widgets/` | Dashboards e componentes especializados |
| `android/` | Integrações nativas, notificações e home widget |

Persistência observada:

- Dados por usuário em `users/{uid}`.
- Dados familiares em `families/{familyId}`.
- Configurações globais, portfólio público, assinatura, clientes BPO/contador e cache Omie.
- Cache local com `SharedPreferences`.

Integrações observadas:

- Firebase Authentication, Realtime Database, Firestore, Messaging e Core.
- ERP Omie.
- Gemini/OpenAI.
- Stripe.
- OCR/ML Kit.
- WhatsApp por links/fluxos de cobrança.
- Notificações locais, biometria e home widget Android.

## 5. Documentação encontrada

- `README.md`: originalmente era o README padrão do Flutter e não descrevia o produto.
- `gerepague.txt`: briefing de produto, públicos, funcionalidades e planos.
- `gerepague_mapa_funcoes.md`: inventário extenso de classes e funções; pode estar desatualizado.
- `implementation_plan.md`: auditoria anterior e plano de refatoração.
- `Todas_as_Rotas_da_Omie.docx`: material de referência das rotas Omie.
- Não foram encontrados inicialmente `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` ou instruções equivalentes na raiz.

## 6. Achados críticos de segurança

### Credenciais expostas

Foram encontradas no conteúdo/histórico do repositório:

- Chave secreta de produção da Stripe embutida no aplicativo Flutter.
- Chaves Gemini embutidas como valores padrão.
- Cópias desses valores em um dump textual que agregava os arquivos do projeto.

Os valores não devem ser reproduzidos neste documento. Mesmo removendo-os da versão atual, eles continuam comprometidos porque já estiveram publicados no histórico Git.

### Dados pessoais e financeiros

Foi encontrada uma exportação do Firebase contendo estrutura de famílias, perfis, e-mails, metas e transações. A exposição deve ser tratada como possível incidente de segurança e privacidade.

### Arquitetura insegura de pagamentos

O cliente Flutter criava e consultava sessões diretamente na API Stripe usando segredo de servidor. O fluxo precisa passar integralmente por backend autenticado. O backend deve validar usuário, plano, preço, moeda e resultado via webhook.

### Outros limites de confiança

- Chaves de IA salvas ou entregues ao cliente podem ser extraídas.
- O proxy Omie precisa de autenticação, autorização, limitação de uso e isolamento por usuário.
- As regras e índices Firebase não estão versionados no repositório, impossibilitando auditoria completa de autorização.
- Papéis administrativos, BPO e contador precisam ser validados no servidor/regras, nunca apenas na interface.

## 7. Android, assinatura e AAB

- `applicationId` e namespace observados: `com.real.finance.control`.
- O `google-services.json` Android atual utiliza o mesmo package name.
- Existe comentário no Gradle sugerindo mudança futura para `com.patrickson.gerepag`; isso precisa ser decidido antes de publicação/migração.
- O bundle identifier iOS observado é `com.antigravity.appfinancerio`.
- A configuração Firebase gerada contém Web e Android, mas não apresenta configuração iOS completa.
- Não existe upload keystore versionada, o que é correto.
- Não existe `android/key.properties` versionado.
- Não foi possível confirmar se a upload keystore original está guardada fora do repositório.
- A configuração original permitia fallback de release para assinatura debug; isso foi corrigido no commit cloud preparado.

Secrets planejados para o GitHub Actions:

- `ANDROID_UPLOAD_KEYSTORE_BASE64`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_STORE_PASSWORD`

Variável opcional planejada:

- `GEREPAG_BILLING_API_BASE_URL`

Se o aplicativo já tiver sido publicado, não gerar outra chave antes de localizar a upload key original ou verificar o processo de redefinição na Play Console.

## 8. Validações e testes

- Não há pasta/suíte Dart `test/` versionada.
- Existe apenas a estrutura padrão de testes nativos iOS/macOS.
- Um arquivo antigo `analyze_res.txt` indicava grande quantidade de dependências desatualizadas e problemas do analisador, mas não constituía uma validação atual confiável.
- A tentativa de instalar/executar Flutter no runner cloud foi interrompida pelo ambiente de segurança quando a ferramenta tentou acessar metadados internos da instância.
- Portanto, não se deve afirmar que `flutter analyze`, testes ou builds passaram.
- O workflow preparado deve executar `flutter pub get`, `flutter analyze`, testes quando existirem, build de APK debug e varredura de segredos em um runner GitHub Actions.

## 9. Alterações preparadas, mas ainda não enviadas ao GitHub

Foi criado no ambiente cloud o commit local:

- Commit: `2f53985`
- Mensagem: `chore: harden secrets and add cloud build workflows`

Principais mudanças desse commit:

- Novo `README.md` específico do GerePag.
- Novo `PROJECT.md` com produto, arquitetura, integrações e riscos.
- Novo `AGENTS.md` como instrução central para agentes de IA.
- Novo `SECURITY.md` com orientação de resposta ao incidente.
- Novo `android/key.properties.example`.
- Workflow `.github/workflows/flutter-ci.yml`.
- Workflow `.github/workflows/android-release.yml`.
- Remoção de chaves Gemini padrão do cliente.
- Remoção da chave secreta Stripe do cliente.
- Alteração do Stripe para usar backend configurado por `GEREPAG_BILLING_API_BASE_URL`.
- Remoção do fallback de assinatura release para debug.
- Expansão do `.gitignore` para bloquear keystores, credenciais, exports e dumps.
- Exclusão da exportação Firebase, arquivo OAuth baixado, cópia duplicada de configuração e dump agregado do código.

O commit não está no GitHub. A tentativa de criar/enviar a branch `codex/cloud-audit-ci` foi recusada com HTTP 403. A branch `main` permaneceu intacta.

Uma cópia segura do estado preparado foi preservada como `gerepag-cloud-audit-2f53985.tar.gz`. Não usar um patch Git contendo exclusões sensíveis, pois patches incluem o conteúdo removido.

## 10. Roadmap priorizado

### P0 — Liberar acesso GitHub

- [x] Configurar a instalação do aplicativo GitHub para acessar `MarcosPatrickExe/gerepag`.
- [x] Garantir `Contents: read/write`.
- [ ] Garantir `Pull requests: read/write`.
- [ ] Garantir acesso a Actions/Workflows quando disponível.
- [x] Reconectar o GitHub no ChatGPT após ajustar a instalação.
- [x] Testar criação de uma branch segura.
- [ ] Enviar o commit preparado em branch separada.
- [ ] Abrir pull request para `main`.
- [ ] Acompanhar o CI e corrigir falhas.
- [ ] Fazer merge somente após revisão/autorização do usuário.

### P0 — Resposta ao incidente

- [ ] Revogar a chave Stripe exposta.
- [ ] Criar uma nova chave apenas no backend.
- [ ] Revogar todas as chaves Gemini expostas.
- [ ] Revisar logs de uso e faturamento Stripe/Google.
- [ ] Avaliar a exposição dos dados Firebase e medidas aplicáveis de LGPD.
- [ ] Fazer backup seguro antes de reescrever o histórico.
- [ ] Limpar o histórico Git com ferramenta apropriada depois da rotação.
- [ ] Coordenar reclone do repositório após a limpeza.

### P1 — CI, build e release Android

- [ ] Rodar a primeira execução do Flutter CI.
- [ ] Corrigir todos os erros de compilação/análise.
- [ ] Reduzir warnings progressivamente.
- [ ] Confirmar build do APK debug.
- [ ] Localizar a upload keystore original.
- [ ] Confirmar alias e senhas.
- [ ] Cadastrar os quatro secrets Android no GitHub.
- [ ] Executar o workflow manual de AAB.
- [ ] Verificar a assinatura do AAB.
- [ ] Testar o artefato em aparelho/faixa interna da Play Console.
- [ ] Configurar proteção da `main` exigindo CI aprovado.

### P1 — Backend e integrações

- [ ] Implementar backend autenticado para Stripe.
- [ ] Criar endpoints de criação e consulta de checkout.
- [ ] Implementar webhooks Stripe idempotentes.
- [ ] Validar plano/preço no servidor.
- [ ] Migrar IA para backend/proxy seguro.
- [ ] Proteger ou substituir o proxy Omie.
- [ ] Implementar rate limiting, auditoria e cotas.
- [ ] Não registrar segredos nem respostas financeiras sensíveis em logs.

### P1 — Firebase e autorização

- [ ] Versionar regras Realtime Database.
- [ ] Versionar regras Firestore.
- [ ] Versionar índices Firebase.
- [ ] Ativar/configurar App Check.
- [ ] Testar isolamento entre usuários e famílias.
- [ ] Testar papéis de admin, BPO, contador e cliente.
- [ ] Impedir autoatribuição de privilégios.
- [ ] Definir retenção e exclusão de dados.

### P1 — Testes

- [ ] Criar estrutura `test/`.
- [ ] Testar cálculos financeiros, parcelamentos e arredondamentos.
- [ ] Testar filtros de datas e fuso horário.
- [ ] Testar planos e limites de uso.
- [ ] Testar cache e sincronização Omie.
- [ ] Criar testes de integração para autenticação e isolamento de dados.
- [ ] Adicionar testes de widgets para jornadas críticas.

### P2 — Refatoração

- [ ] Reduzir responsabilidades do `TransactionsProvider`.
- [ ] Dividir telas monolíticas, sobretudo BPO Tower.
- [ ] Corrigir uso de `BuildContext` após `await`.
- [ ] Cancelar subscriptions/controllers no `dispose`.
- [ ] Encapsular notificações de `ChangeNotifier`.
- [ ] Remover imports, variáveis e código morto.
- [ ] Atualizar APIs Flutter depreciadas.
- [ ] Centralizar configuração de planos, preços e limites.
- [ ] Atualizar o mapa de funções após a refatoração.

### P2 — Plataformas e produto

- [ ] Decidir o application ID Android definitivo.
- [ ] Configurar Firebase iOS corretamente.
- [ ] Revisar bundle ID iOS.
- [ ] Testar FCM, biometria, câmera, arquivos e home widget em dispositivos reais.
- [ ] Validar responsividade Web/Desktop/Mobile.
- [ ] Revisar consistência de preços e benefícios entre telas, código e briefing.

## 11. Próxima ação recomendada

1. Corrigir a instalação/permissões do aplicativo GitHub.
2. Informar no chat: `já reconectei o GitHub`.
3. Testar uma criação de branch antes de qualquer outra mutação.
4. Publicar `codex/cloud-audit-ci` e abrir PR.
5. Rodar CI.
6. Priorizar imediatamente rotação de chaves e resposta à exposição de dados.

## 12. Instrução para a próxima conversa/agente

Use este checkpoint como contexto, mas confira novamente o estado remoto antes de agir. O GitHub é a fonte de verdade; commits locais citados podem não existir remotamente. Não exponha valores de segredos, não restaure exports privados e não assuma que testes passaram sem evidência. Atualize as caixas deste roadmap conforme cada item for concluído.
