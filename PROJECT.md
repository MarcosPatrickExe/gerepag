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

- App GerePag existente no Play Console: `com.marcos.gurgel.gerepag`.
- Android e Firebase Android atuais no código: `com.real.finance.control`.
- iOS atual: `com.antigravity.appfinancerio`.

Decisão de publicação: reutilizar o app existente no Play Console. O projeto Firebase `gerePag` já contém o app Android `com.marcos.gurgel.gerepag`; não recriar nem excluir o projeto. A configuração local ainda aponta para o Firebase antigo `financeiroapp-8b809` em `android/app/google-services.json` e `lib/firebase_options.dart`. Antes da publicação Android, migrar em conjunto o `applicationId`, namespace e fontes Kotlin, baixar o `google-services.json` do app Firebase correto e regenerar `firebase_options.dart` para Android/Web. Não alterar somente o Gradle, nem enviar um AAB com o package atual ao cadastro do Play Console.

## Segurança e billing

- Nunca coloque chaves secretas Stripe, IA, OAuth, exports de banco ou keystores no Git.
- O app usa `GEREPAG_BILLING_API_BASE_URL` para falar com um backend autenticado.
- O backend deve validar UID, plano, preço e moeda, criar a sessão Stripe e confirmar pagamento por webhook idempotente.
- Chaves anteriormente publicadas devem ser revogadas; removê-las do arquivo atual não as remove do histórico Git.
- Regras de Firebase e App Check ainda precisam ser versionados e auditados.

## Build Android assinado

O build release exige `android/key.properties` e uma upload keystore fora do Git. O exemplo está em `android/key.properties.example`. A upload key original foi perdida; uma nova chave externa foi criada e a redefinição foi solicitada no Play Console em 21 de setembro de 2026. Aguarde a ativação antes de enviar artefatos assinados.

No GitHub Actions, configure:

- `ANDROID_UPLOAD_KEYSTORE_BASE64`;
- `ANDROID_KEY_ALIAS`;
- `ANDROID_KEY_PASSWORD`;
- `ANDROID_STORE_PASSWORD`;
- variável `GEREPAG_BILLING_API_BASE_URL`.

Nunca versione a keystore, o certificado PEM, caminhos locais, aliases confidenciais ou senhas. Não altere a chave de assinatura do app no Play Console para recuperar a upload key.

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
