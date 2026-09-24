# GerePag — Roadmap de prontidão para App Store

> Atualizado em 23 de setembro de 2026. Este documento é um plano de lançamento, não uma declaração de aprovação pela Apple. Itens P0 bloqueiam o envio a App Store Connect.

## Decisão de produto para iOS

O primeiro aplicativo iOS atenderá dois públicos:

1. consumidores autônomos, que poderão contratar recursos digitais do GerePag;
2. usuários de empresas já contratadas diretamente pelos proprietários do GerePag.

Essa distinção determina a cobrança. Recursos digitais vendidos a consumidores dentro do app iOS precisam de compra no app/StoreKit. Clientes empresariais com acesso previamente contratado podem entrar e usar o serviço corporativo, desde que o aplicativo não ofereça uma compra externa para o consumidor nessa jornada. O checkout Stripe existente não é, por si só, um caminho de compra aceitável para os planos digitais do público consumidor no iOS.

## Resultado da auditoria de código

### Escopo revisado

- 181 arquivos Dart em `lib/`, além de `android/`, `ios/`, `firebase.json`, regras do Realtime Database, dependências e workflows.
- Inventário histórico consultado: `gerepague_mapa_funcoes.md`; comportamentos críticos confirmados em `main.dart`, `realtime_db_service.dart`, telas de login/configurações, providers, Stripe e projetos nativos.
- Persistência financeira pessoal: **Firebase Realtime Database**, principalmente sob `users/{uid}`; `SharedPreferences` é cache e preferências locais. Firestore é dependência, mas não é o caminho observado para carteiras e transferências atuais.
- Validação anterior registrada: login com E-mail/Senha, criação de duas contas e transferência continuam após reabrir o app. A confirmação entre dispositivos/Console ainda é recomendada.

### Funcionalidades já presentes

- autenticação por e-mail/senha, onboarding e perfis iniciais;
- contas, transferências, transações, cartões, metas, parcelas e dashboards pessoais;
- jornadas de BPO, contador e empresa/Omie;
- OCR, IA, notificações, biometria e relatórios, sujeitos a validação por plataforma/plano;
- Firebase Android/Web configurado para `gerepag-9e692`;
- build Android debug e testes existentes aprovados em validações anteriores.

### Achados que impedem um lançamento público responsável

| Prioridade | Achado | Ação de encerramento |
|---|---|---|
| P0 | A conta iOS local usa `com.antigravity.appfinancerio`, mas o Firebase iOS exibido usa `com.marcos.gurgel.gerepag`. Não há `GoogleService-Info.plist` nem opção Firebase iOS gerada. | Criar/confirmar o App ID Apple e migrar o Xcode, Firebase e FlutterFire juntos para `com.marcos.gurgel.gerepag`; então fazer build iOS em CI. |
| P0 | O app cria conta e armazena dados financeiros. A Apple exige que o usuário possa iniciar a exclusão dentro do app. | O botão e fluxo de confirmação foram adicionados. Antes do envio, concluir o backend para limpeza de vínculos compartilhados, dados públicos e retenções legais; testar em projeto Firebase de homologação. |
| Concluído | A política de privacidade está publicada em `https://gerepague.netlify.app/privacidade` e acessível em Configurações. | O app verifica a conectividade, abre a página em WebView interna e informa falta de internet por modal. Manter a URL ativa e preencher App Privacy no App Store Connect. |
| P0 | As regras atuais do Realtime Database isolam somente `users/{uid}` e `omie_sync/{uid}`. O código também opera famílias, BPO, contador, portfólio e administração. | Modelar e testar autorização de menor privilégio com Emulator Suite e regras versionadas; impedir escalonamento de papel no cliente. |
| P0 | Há fluxos administrativos que escrevem `role=admin` no cliente e integrações sensíveis (Omie/IA) ainda próximas do dispositivo. | Transferir privilégios, credenciais e decisões de acesso para backend autenticado; remover métodos de promoção do build de produção. |
| P0 | O checkout Stripe atende ao fluxo atual, mas não há StoreKit/IAP para consumidor iOS. | Implementar assinatura/entitlement por App Store, validação no servidor e restauração de compras. Condicionar/remover Stripe na experiência iOS para consumidor. |
| P0 | Segredos e dados já expostos no histórico exigem resposta a incidente. | Revogar/rotacionar chaves, revisar uso, tratar LGPD e limpar o histórico com plano de reclone. |
| P1 | 507 avisos/informações legados do analisador e só 10 testes. | Criar cobertura para autenticação, exclusão, contas/transferências, regras Firebase, planos e telas críticas; reduzir avisos por lotes. |
| P1 | O perfil de usuário pode exibir o fallback `Usuário` quando a conta é criada diretamente no Firebase Console. | Provisionar `users/{uid}/profile/name` de maneira confiável e exibir o nome no dashboard. |

## Exclusão de conta e privacidade

### Implementado nesta entrega

Em **Drawer → Configurações**, abaixo de **Sair da Conta**, há **Excluir minha conta** em vermelho. O usuário vê aviso, confirma com a senha atual e o app tenta:

1. reautenticar;
2. remover `users/{uid}` e `omie_sync/{uid}` no Realtime Database;
3. excluir o usuário do Firebase Authentication;
4. apagar as preferências locais e voltar à tela de login.

O processo exige rede e senha. Enquanto a operação não retornar sucesso, o usuário deve receber erro e poder tentar novamente.

### Ainda obrigatório antes da App Store

- [x] Publicar a política em `https://gerepague.netlify.app/privacidade` e adicioná-la em Configurações com abertura em WebView interna e aviso de falta de conexão.
- [ ] Escrever política que descreva dados financeiros, e-mail, dados de Omie, OCR, IA, notificações, terceiros, finalidade, base legal, retenção e contato.
- [ ] Definir o que ocorre com dados familiares, BPO, contador, `portfolio_slugs`, faturas, backups e dados legalmente retidos.
- [ ] Fazer essa exclusão completa no backend com trilha de auditoria mínima e confirmação ao usuário; não deixar referências compartilhadas órfãs.
- [ ] Informar tratamento/cancelamento de assinaturas iOS no fluxo de exclusão quando StoreKit for introduzido.
- [ ] Testar sucesso, senha incorreta, falta de rede e exclusão de conta com família/BPO em ambiente de homologação.

## Apple Developer → Codemagic → App Store Connect

### 1. Identidade e assinatura Apple

1. Confirmar uma assinatura ativa do Apple Developer Program na conta que os dois proprietários conseguirão administrar.
2. Em **Certificates, Identifiers & Profiles**, criar um identificador explícito `com.marcos.gurgel.gerepag` — somente se estiver disponível para a equipe Apple.
3. Habilitar apenas capabilities necessárias após a auditoria (por exemplo, Push Notifications quando FCM estiver pronto); não habilitar serviços por padrão.
4. Criar certificado/perfil de distribuição App Store manualmente, ou permitir que o Codemagic faça o signing automático depois da integração segura da conta.
5. Criar uma chave da App Store Connect API com papel mínimo adequado para o Codemagic, guardar o `.p8` apenas no cofre do Codemagic e documentar o emissor/key ID sem versionar o arquivo.

### 2. Preparar o projeto Flutter

- [ ] Trocar os três `PRODUCT_BUNDLE_IDENTIFIER` de Runner para o identificador Apple aprovado, incluindo configuração de testes correspondente.
- [ ] Baixar o `GoogleService-Info.plist` **do app Firebase iOS com o mesmo bundle ID** e colocá-lo em `ios/Runner/`.
- [ ] Rodar FlutterFire para iOS e regenerar `lib/firebase_options.dart`; revisar o diff para garantir Android e Web existentes.
- [ ] Criar `codemagic.yaml` com variáveis e certificados somente no cofre do Codemagic.
- [ ] Fazer build iOS assinado, depois TestFlight interno e teste em aparelho físico.
- [ ] Verificar permissões do iOS (câmera, microfone/voz, notificações, biometria, arquivos) e adicionar textos de propósito no `Info.plist` apenas para recursos efetivamente usados.

### 3. App Store Connect

- [ ] Criar o registro do app depois do App ID estar decidido.
- [ ] Preparar nome, subtítulo, descrição, categoria, suporte, marketing URL se houver, ícone e screenshots reais de iPhone/iPad.
- [ ] Disponibilizar uma conta de revisão sem dados reais, com instruções de login e de recursos restritos.
- [ ] Preencher App Privacy de acordo com a implementação e parceiros (Firebase, Omie, IA, OCR, notificações, analytics se ativado).
- [x] Inserir `https://gerepague.netlify.app/privacidade` como URL pública da política de privacidade.
- [ ] Definir classificação etária, export compliance, disponibilidade por país, direitos autorais e contato de revisão.
- [ ] Configurar produtos/assinaturas e testes sandbox de IAP antes de enviar a primeira versão.

## Firebase: nomes antigos no Console

As imagens mostram que **os IDs Android e iOS já são `com.marcos.gurgel.gerepag`**, mas o nome exibido de cada aplicativo Firebase ainda é `appfinanceiro`. Esse nome é um rótulo administrativo/cosmético: não altera package name, bundle ID, assinatura nem o app publicado. Não é necessário apagar nem recriar o projeto Firebase.

Pendências recomendadas:

- [ ] Renomear os rótulos Android e iOS no Firebase Console para `GerePag Android` e `GerePag iOS`.
- [ ] Manter o aplicativo macOS antigo (`com.antigravity.appfinancerio`) como legado ou removê-lo somente após confirmar que não há uso; ele não bloqueia o lançamento iOS.
- [ ] Não alterar nem excluir o app Firebase Android/iOS já associado aos IDs corretos.

## Ordem objetiva de execução

1. Concluir e validar o fluxo de exclusão em homologação; manter a política de privacidade publicada e acessível pelo aplicativo.
2. Corrigir autorização Firebase e a segurança das integrações/planos.
3. Definir StoreKit para consumidor e acesso pré-contratado para empresas.
4. Criar o App ID Apple `com.marcos.gurgel.gerepag`; depois alinhar Xcode + Firebase iOS + FlutterFire.
5. Configurar Codemagic e testar em TestFlight.
6. Completar App Store Connect e submeter apenas depois de todos os P0 fechados.

## Referências oficiais

- Apple: [exclusão de conta dentro do app](https://developer.apple.com/support/offering-account-deletion-in-your-app)
- Apple: [App Privacy e URL da política](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)
- Apple: [diretrizes de pagamentos e serviços empresariais](https://developer.apple.com/app-store/review/guidelines/uk/)
- Apple: [StoreKit/In-App Purchase](https://developer.apple.com/documentation/storekit/in-app-purchase)
- Codemagic: [assinatura iOS para Flutter](https://docs.codemagic.io/flutter-code-signing/ios-code-signing/)
