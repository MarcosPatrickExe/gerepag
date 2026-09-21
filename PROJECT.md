# GerePag — visão central do projeto

## Produto

O GerePag é um copiloto financeiro pessoal e empresarial em Flutter. Ele reúne controle financeiro, dados do ERP Omie, OCR, inteligência artificial, cobrança e relatórios para quatro públicos principais:

1. autônomos e freelancers;
2. pequenas e médias empresas;
3. BPOs financeiros e contadores com múltiplos clientes;
4. infoprodutores e afiliados que recuperam vendas e cobranças.

As plataformas-alvo são Android, iOS e Web. Desktop existe na árvore Flutter, mas não é prioridade comercial atual.

## Fluxo funcional

1. O aplicativo inicializa Firebase, notificações e tarefas de sincronização.
2. O usuário conclui onboarding e autenticação.
3. Perfil, papel, nicho e assinatura definem os recursos disponíveis.
4. Dados pessoais/familiares são carregados do Firebase.
5. Contas Omie opcionais alimentam dashboards pessoais, empresariais e multiempresa.
6. O usuário consulta DRE, fluxo de caixa, projeções, cobranças, metas e relatórios.
7. OCR, IA e automações respeitam o plano e os limites de uso.

## Arquitetura atual

| Caminho | Responsabilidade |
|---|---|
| `lib/main.dart` | Bootstrap, Firebase, providers, onboarding e autenticação |
| `lib/models/` | Entidades financeiras e modelos Omie/BI |
| `lib/providers/` | Estado global e regras de apresentação |
| `lib/providers/transactions_provider/parts/` | Sincronização, CRM, forecast, estoque, vendas, BI e simulação |
| `lib/services/` | Firebase, Omie, IA, OCR, voz, billing, exportação e notificações |
| `lib/screens/` | Jornadas pessoais, empresariais, BPO, contador, assinatura e administração |
| `lib/widgets/` | Dashboards e componentes reutilizáveis |
| `android/` e `ios/` | Integrações e configuração nativas |

O `TransactionsProvider` ainda concentra responsabilidades demais e deve ser decomposto gradualmente, sem mudanças amplas de comportamento numa única entrega.

## Persistência e integrações

- Firebase Authentication, Realtime Database, Firestore, Messaging e Core.
- Dados de usuário sob `users/{uid}` e dados familiares sob `families/{familyId}`.
- Preferências e cache de sincronização em `SharedPreferences`.
- ERP Omie, OCR/ML Kit, notificações locais, biometria e home widget Android.
- IA Gemini/OpenAI configurada pelo usuário; migração para proxy seguro continua pendente.
- Stripe deve ser acessado exclusivamente por backend autenticado.

## Planos atuais

- Grátis: dashboard básico, uma conta Omie e cotas pequenas de OCR/IA.
- PRO: IA/OCR, relatórios e simulação DRE.
- Business: multiempresa, equipe, alertas e recursos para BPO.

Preços e limites ainda aparecem em múltiplos pontos e precisam ser centralizados no backend antes da produção.

## Estado técnico validado em 21/09/2026

- Flutter 3.41.8 e Dart 3.11.5.
- Build Web debug concluído.
- Build APK debug concluído.
- Análise estática sem erros de compilação após corrigir `client_profitability_screen.dart`.
- Permanecem warnings e infos de manutenção; consulte `CHECKPOINT_GEREPAG.md`.
- Testes unitários e de widget ficam em `test/` e rodam no CI.

## Identidade de plataforma

- Android atual: `com.real.finance.control`.
- Firebase Android atual: `com.real.finance.control`.
- iOS atual: `com.antigravity.appfinancerio`.

Não altere esses identificadores sem uma decisão de migração, pois eles afetam Firebase, lojas, links e assinatura.

## Segurança e billing

- Nunca coloque chaves secretas Stripe, IA, OAuth, exports de banco ou keystores no Git.
- O app usa `GEREPAG_BILLING_API_BASE_URL` para falar com um backend autenticado.
- O backend deve validar UID, plano, preço e moeda, criar a sessão Stripe e confirmar pagamento por webhook idempotente.
- Chaves anteriormente publicadas devem ser revogadas; removê-las do arquivo atual não as remove do histórico Git.
- Regras de Firebase e App Check ainda precisam ser versionados e auditados.

## Build Android assinado

O build release exige `android/key.properties` e uma upload keystore fora do Git. O exemplo está em `android/key.properties.example`.

No GitHub Actions, configure:

- `ANDROID_UPLOAD_KEYSTORE_BASE64`;
- `ANDROID_KEY_ALIAS`;
- `ANDROID_KEY_PASSWORD`;
- `ANDROID_STORE_PASSWORD`;
- variável `GEREPAG_BILLING_API_BASE_URL`.

Se o aplicativo já foi publicado, localize a upload key original ou confirme a redefinição na Play Console antes de gerar outra.

## Comandos de validação

```bash
flutter pub get --enforce-lockfile
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build web --release --no-pub
flutter build apk --debug --no-pub
```

Para release Android, use o workflow manual `Android signed AAB` depois de cadastrar os secrets.

## Documentos relacionados

- `CHECKPOINT_GEREPAG.md`: riscos, decisões e roadmap priorizado.
- `AGENTS.md`: regras de trabalho para ferramentas de IA.
- `SECURITY.md`: tratamento de vulnerabilidades e credenciais.
- `gerepague_mapa_funcoes.md`: inventário histórico de classes e funções; pode ficar desatualizado.
- `implementation_plan.md`: plano histórico de refatoração.
