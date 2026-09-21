# Plano de Refatoração e Melhorias - GEREPAGUE

Este plano detalha as ações para auditar, refatorar e otimizar o projeto Flutter **GEREPAGUE**, alinhando-o com os princípios de Clean Architecture, Clean Code, SOLID e eliminando os mais de 1200 alertas apontados pelo analisador estático do Flutter.

---

## 1. Resumo da Análise (Auditoria)

Após a execução do analisador estático do Flutter (`flutter analyze`) e inspeção de código manual, foram identificadas as seguintes áreas críticas de atenção:
* **Falta de verificação de context.mounted em operações assíncronas**: Risco crítico de crash e memory leak se a tela for fechada durante uma chamada de API ou banco de dados.
* **Acesso irregular a membros protegidos**: Uso de `notifyListeners()` (protegido) dentro de extensões (`extension`) de `TransactionsProvider` gerando diversos erros de compilação/warning.
* **Telas monolíticas massivas**: Arquivos como `bpo_tower_screen.dart` possuem mais de 4.200 linhas de código misturando UI, regras de negócio, diálogos e até geração de PDFs executivos.
* **Uso extensivo de APIs legadas e depreciadas**: Uso de `withOpacity`, `background` e `onBackground` no tema e campos de formulário obsoletos.
* **Vazamentos de memória (Memory Leaks)**: `GlobalSettingsProvider` inicia `StreamSubscription` sem gerenciamento e sem fechamento (`cancel`) no ciclo de vida.
* **Importações duplicadas ou não utilizadas** e variáveis mortas poluindo a legibilidade.

---

## 2. Problemas Encontrados (Classificação)

| Localização | Problema / Explicação | Impacto | Gravidade | Melhor Solução |
| :--- | :--- | :--- | :--- | :--- |
| `lib/providers/global_settings_provider.dart` | `StreamSubscription` não gerenciada ou cancelada. | Vazamento de memória se o provider for recriado. | Média | Salvar a inscrição em uma variável privada e realizar `.cancel()` no método `dispose()`. |
| Extensões de `TransactionsProvider` (ex: `ops_finance.dart`, `sync_core.dart`) | Chamada direta de `notifyListeners()` de fora da classe (via extensão). | Avisos de uso inválido de membro protegido / Quebra de encapsulamento. | Alta | Implementar um método público `void notify() => notifyListeners();` na classe principal e chamá-lo nas extensões. |
| Múltiplos arquivos (ex: `bpo_tower_screen.dart`, `bank_sync_inbox_screen.dart`) | Uso de `BuildContext` (`Navigator`, `ScaffoldMessenger`) após `await` sem checar se a tela está montada (`mounted`). | Crash do aplicativo se o usuário sair da tela antes da conclusão do processo assíncrono. | Alta | Adicionar `if (!mounted) return;` ou `if (context.mounted)` antes de interagir com o `BuildContext` pós-async. |
| `lib/screens/bpo_tower_screen.dart` | Monólito com mais de 4200 linhas (contém regras, diálogos, telas secundárias, exportação para PDF). | Código difícil de ler, manter, testar e evoluir. | Crítica | Extrair o gerador de PDF para um serviço auxiliar. Dividir diálogos e sub-widgets complexos para arquivos separados. |
| `lib/core/app_theme.dart` | Uso de `ColorScheme.background` e `ColorScheme.onBackground` obsoletos. | Dificulta atualizações futuras do Flutter e gera avisos do compilador. | Baixa | Substituir por `surface` e `onSurface`. |
| Todo o projeto | Uso do método depreciado `withOpacity(val)` em cores. | Depreciação no Flutter 3.3x+; perda de precisão. | Baixa | Substituir por `.withValues(alpha: val)` conforme as especificações modernas do Flutter/Dart. |

---

## 3. Plano de Ação & Refatoração Proposta

### Fase 1: Correção de Bugs de Ciclo de Vida e Avisos do Compilador
* **Criar método publico para notificar listeners**:
  * Adicionar `void notify() => notifyListeners();` no [transactions_provider.dart](file:///c:/Users/Gabriele/OneDrive/Documentos/GitHub/GEREPAGUE/lib/providers/transactions_provider.dart).
  * Atualizar as chamadas de `notifyListeners()` nas extensões em `parts/` para usar `notify()`.
* **Fixar a segurança do BuildContext (Async Gaps)**:
  * Adicionar guards `if (!mounted) return;` em todas as telas que realizam operações assíncronas de Firebase e Omie.
* **Corrigir Memory Leak no GlobalSettingsProvider**:
  * Adicionar `StreamSubscription? _settingsSub;` na classe, atribuí-la na inicialização e sobrescrever o método `dispose()` para cancelá-la.

### Fase 2: Modularização e Decomposição de Monólitos (`BpoTowerScreen`)
* **Extrair Geração de PDF**:
  * Criar um helper ou utilizar o `PdfReportService` para mover a lógica pesada de layout PDF do arquivo de UI.
* **Modularizar Diálogos**:
  * Mover `_showLinkClientDialog`, `_showEditClientSettingsDialog`, `_showSendMessageToClientDialog` e `_showSendMessageToAllClientsDialog` para componentes de diálogo dedicados na pasta `lib/widgets/bpo/`.
* **Separar Sub-widgets**:
  * Mover as seções principais da tab para widgets dedicados focados.

### Fase 3: Modernização de UI/UX e Responsividade
* **Adequação ao Material 3**:
  * Ajustar o tema de cores em `lib/core/app_theme.dart` removendo chaves obsoletas.
  * Atualizar o uso de `withOpacity` para `.withValues(alpha: ...)`.
* **Garantia de Responsividade**:
  * Validar o uso de larguras flexíveis nas telas maiores (Desktop/Web) e testar possíveis quebras de layout usando `LayoutBuilder` nas páginas reformuladas.

---

## 4. Plano de Verificação

### Testes Manuais
* **Executar a compilação local**: Certificar-se de que as mudanças não quebram o build e reduzem substancialmente o número de avisos do `flutter analyze`.
* **Fluxo de Login & Sincronização Omie**: Validar se a sincronização de contas continua funcionando perfeitamente sem erros de concorrência ou nulidade.
* **Simulador Financeiro / BPO Tower**: Testar a ativação de clientes BPO, geração e visualização de PDF de relatório.
* **Verificação de Orientação e Responsividade**: Redimensionar telas para verificar quebras (Overflows) no painel.

### Análise Estática Automatizada
* Executar `flutter analyze` após as alterações para garantir zero erros e avisos reduzidos ao mínimo.
