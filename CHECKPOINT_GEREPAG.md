# CHECKPOINT — Projeto GerePag

> Atualizado em 21 de setembro de 2026. Este documento registra o estado observado do repositório `MarcosPatrickExe/gerepag`, decisões tomadas, bloqueios e pendências. Ele deve ser usado como contexto inicial ao continuar o trabalho em outro chat ou em um Projeto do ChatGPT.

## 1. Objetivo da continuidade

Usar o GitHub como fonte de verdade e manter a cópia local sincronizada com ele. Analisar e evoluir o aplicativo Flutter/Dart, preservar a regra de negócio, melhorar segurança e arquitetura, automatizar validações e gerar AAB Android assinado. Para mudanças futuras, preferir branch e pull request; a integração de segurança e CI descrita neste documento já foi revisada e integrada à `main`.

## 2. Estado remoto confirmado

- Repositório: `https://github.com/MarcosPatrickExe/gerepag`.
- Branch padrão observada: `main`.
- Commit atual de `main`: `d851f83b26046969d0a43bd7bc3a5eb93b474cf1`.
- O pacote de segurança, CI, documentação e testes foi integrado por fast-forward em 21 de setembro de 2026.
- A cópia local principal está em `main` e sincronizada com `origin/main` nesse mesmo commit.
- A integração GitHub voltou a permitir escrita em 21 de setembro de 2026.
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

- O app GerePag já existente no Play Console usa o package name `com.marcos.gurgel.gerepag`.
- O código Android e o Firebase Android atuais ainda usam `com.real.finance.control`.
- Decisão tomada: reutilizar o app existente no Play Console. Antes de um AAB de produção, migrar em conjunto `applicationId`, namespace, pacotes Kotlin e configuração Firebase para `com.marcos.gurgel.gerepag`.
- O projeto Firebase existente `gerePag` já possui o app Android registrado como `com.marcos.gurgel.gerepag`; manter esse projeto e, após a migração de código, baixar dele um novo `google-services.json`.
- Diagnóstico local em 21 de setembro de 2026: `android/app/google-services.json` e `lib/firebase_options.dart` ainda apontam para o projeto Firebase antigo `financeiroapp-8b809` (número `694627493774`), não para o Firebase `gerePag`.
- O APK debug foi instalado em emulador Android após limpar o armazenamento do AVD e alcançou a tela de login. A autenticação não foi validada porque o app ainda usa o Firebase antigo; depois da migração, confirmar que Email/Senha está habilitado no Firebase GerePag e testar uma conta de desenvolvimento sem registrar senhas no repositório.
- Não enviar AAB com `com.real.finance.control` ao cadastro existente do Play Console: ele seria recusado por package name diferente.
- O bundle identifier iOS observado é `com.antigravity.appfinancerio`.
- A configuração Firebase gerada contém Web e Android, mas não apresenta configuração iOS completa.
- Não existe upload keystore versionada, o que é correto.
- Não existe `android/key.properties` versionado.
- A upload keystore original está perdida. Uma nova upload keystore externa ao Git foi criada e o certificado PEM foi enviado em uma solicitação de redefinição no Play Console em 21 de setembro de 2026; aguardar a data/hora de ativação informada pelo Google antes de enviar novos artefatos.
- Não registrar neste repositório caminho, senha, arquivo da keystore ou certificado PEM. Não usar a opção de mudar a chave de assinatura do app para esta recuperação.
- A configuração original permitia fallback de release para assinatura debug; isso foi corrigido no commit cloud preparado.

Secrets planejados para o GitHub Actions:

- `ANDROID_UPLOAD_KEYSTORE_BASE64`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_STORE_PASSWORD`

Variável obrigatória para billing em builds de produção:

- `GEREPAG_BILLING_API_BASE_URL`

O próximo AAB deve ser assinado com a nova upload keystore somente após a redefinição ser ativada no Play Console.

## 8. Validações e testes

Validações locais executadas em 21 de setembro de 2026 com Flutter 3.41.8, Dart 3.11.5 e Java 17:

- `flutter pub get --enforce-lockfile`: aprovado depois da atualização reprodutível do lockfile.
- `flutter analyze --no-fatal-infos --no-fatal-warnings`: aprovado com zero erros, 189 warnings e 318 infos.
- `flutter test --no-pub`: 10 testes unitários/de widget aprovados.
- `flutter build web --debug --no-pub`: aprovado.
- `flutter build web --release --no-pub`: aprovado.
- `flutter build apk --debug --no-pub`: aprovado.
- `flutter build appbundle --release --no-pub` sem chave: bloqueado corretamente com mensagem de assinatura ausente.
- `flutter run` em emulador Android: build e instalação debug aprovados após limpar o armazenamento do AVD; tela de login exibida. O fluxo de autenticação permanece pendente da migração Firebase.

Os warnings e infos do analisador continuam no roadmap de manutenção. Os workflows já estão em `main`; confirmar as execuções no GitHub Actions e corrigir eventuais falhas.

## 9. Alterações integradas na main

O pacote de mudanças originalmente descrito no commit cloud `2f53985` não estava disponível nesta máquina e foi reconstruído, validado e publicado:

- Commits integrados: `a753953` (`chore: harden release pipeline and add tests`) e `d851f83` (`docs: update validation checkpoint`).

Principais mudanças:

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
- Correção dos quatro erros de compilação em `client_profitability_screen.dart`.
- Proteção contra divisão por zero no progresso de metas.
- Dez testes unitários/de widget cobrindo modelos financeiros e KPI.
- Atualização do lockfile para o SDK Flutter validado.

A `main` remota e local foram atualizadas. Próximas etapas: ativação da nova upload key, migração do package Android/Firebase, validação em emulador e geração do AAB.

## 10. Roadmap priorizado

### P0 — Liberar acesso GitHub

- [x] Configurar a instalação do aplicativo GitHub para acessar `MarcosPatrickExe/gerepag`.
- [x] Garantir `Contents: read/write`.
- [ ] Garantir `Pull requests: read/write`.
- [ ] Garantir acesso a Actions/Workflows quando disponível.
- [x] Reconectar o GitHub no ChatGPT após ajustar a instalação.
- [x] Testar criação de uma branch segura.
- [x] Enviar o commit preparado em branch separada.
- [x] Integrar as alterações revisadas na `main`.
- [ ] Acompanhar o CI e corrigir falhas.

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
- [x] Corrigir todos os erros de compilação/análise.
- [ ] Reduzir warnings progressivamente.
- [x] Confirmar build do APK debug.
- [x] Confirmar o package do app existente no Play Console: `com.marcos.gurgel.gerepag`.
- [x] Decidir reutilizar o app existente no Play Console.
- [x] Gerar nova upload keystore externa ao Git e solicitar redefinição da chave de upload.
- [ ] Aguardar a ativação da nova chave de upload no Play Console.
- [ ] Migrar package Android, namespace e código Kotlin para `com.marcos.gurgel.gerepag`.
- [x] Confirmar que o Firebase já possui o app Android `com.marcos.gurgel.gerepag`.
- [ ] Baixar o `google-services.json` desse app Firebase e substituir a configuração atual após a migração do package.
- [ ] Regenerar `lib/firebase_options.dart` para o projeto Firebase GerePag, incluindo Android e Web, sem registrar chaves privadas.
- [ ] Habilitar/confirmar o provedor Firebase Authentication Email/Senha no projeto GerePag e criar/validar uma conta de desenvolvimento.
- [ ] Criar `android/key.properties` somente na máquina local, fora do Git.
- [ ] Cadastrar os quatro secrets Android no GitHub.
- [ ] Executar o workflow manual de AAB.
- [ ] Verificar a assinatura do AAB.
- [ ] Executar o app em emulador Android e validar login, Firebase, navegação e funções prioritárias.
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

- [x] Criar estrutura `test/`.
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

- [x] Decidir o application ID Android alvo: `com.marcos.gurgel.gerepag`.
- [ ] Configurar Firebase iOS corretamente.
- [ ] Revisar bundle ID iOS.
- [ ] Testar FCM, biometria, câmera, arquivos e home widget em dispositivos reais.
- [ ] Validar responsividade Web/Desktop/Mobile.
- [ ] Revisar consistência de preços e benefícios entre telas, código e briefing.

## 11. Próxima ação recomendada

1. Baixar a configuração do app Android `com.marcos.gurgel.gerepag` no Firebase GerePag e regenerar a configuração Flutter para Android/Web; só então migrar e validar o package no código.
2. Confirmar Email/Senha no Firebase Authentication e retestar o login no emulador, guardando somente o código de erro, se existir.
3. Aguardar o e-mail/estado do Play Console que confirma a ativação da nova upload key (normalmente cerca de 48 horas após o pedido); não fazer upload à Play Store antes de concluir e validar a migração Firebase.
6. Priorizar imediatamente rotação de chaves e resposta à exposição de dados.

## 12. Instrução para a próxima conversa/agente

Use este checkpoint como contexto, mas confira novamente o estado remoto antes de agir. O GitHub é a fonte de verdade; commits locais citados podem não existir remotamente. Não exponha valores de segredos, não restaure exports privados e não assuma que testes passaram sem evidência. Atualize as caixas deste roadmap conforme cada item for concluído.
