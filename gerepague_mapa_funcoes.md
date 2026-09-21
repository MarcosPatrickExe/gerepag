# Mapa Completo de Classes e Funções - GEREPAGUE

Este documento apresenta uma visão estruturada de todas as classes, métodos e funções detectados no código-fonte do aplicativo **GEREPAGUE**.

## Categoria: CORE

### Arquivo: `lib/core/app_theme.dart`

#### Classe: `AppTheme`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `inputDecoration` | `InputDecoration` | `String label, IconData icon` | `static` |

---

## Categoria: MODELS

### Arquivo: `lib/models/badge_model.dart`

#### Classe: `BadgeModel`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `toMap` | `dynamic>` | `` | - |

---

### Arquivo: `lib/models/business_goal_model.dart`

#### Classe: `BusinessGoalModel`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `toMap` | `dynamic>` | `` | - |

---

### Arquivo: `lib/models/challenge_model.dart`

#### Classe: `ChallengeModel`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `toMap` | `dynamic>` | `` | - |

---

### Arquivo: `lib/models/credit_card_model.dart`

#### Classe: `CreditCardModel`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `toMap` | `dynamic>` | `` | - |

---

### Arquivo: `lib/models/dre_node.dart`

#### Classe: `DreNode`

*Nenhum método ou função detectado.*

---

### Arquivo: `lib/models/goal_model.dart`

#### Classe: `GoalModel`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `toMap` | `dynamic>` | `` | - |

---

### Arquivo: `lib/models/mission_model.dart`

#### Classe: `MissionModel`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `copyWith` | `MissionModel` | `{MissionStatus? status}` | - |
| `MissionModel` | `return` | `id: id, title: title, description: description, rewardXp: rewardXp, status: status ?? this.status, categoryFilter: categoryFilter, keywordFilter: keywordFilter,` | - |

---

### Arquivo: `lib/models/omie_account.dart`

#### Classe: `OmieAccount`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `toMap` | `dynamic>` | `` | - |
| `OmieAccount` | `return` | `id: map['id'] ?? '', name: map['name'] ?? '', appKey: map['appKey'] ?? '', appSecret: map['appSecret'] ?? '', cnpj: map['cnpj'],` | - |

---

### Arquivo: `lib/models/transaction_model.dart`

#### Classe: `TransactionModel`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `toMap` | `dynamic>` | `` | - |

---

### Arquivo: `lib/models/wallet_model.dart`

#### Classe: `WalletModel`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `toMap` | `dynamic>` | `` | - |

---

## Categoria: PROVIDERS

### Arquivo: `lib/providers/admin_provider.dart`

#### Classe: `AdminProvider`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `setFilter` | `void` | `String type` | - |
| `setSort` | `void` | `String type` | - |
| `toggleInactiveFilter` | `void` | `` | - |
| `setSearchQuery` | `void` | `String query` | - |
| `fetchAllUsers` | `Future<void>` | `` | - |
| `changeUserRole` | `Future<void>` | `String uid, String newRole` | - |
| `deleteUser` | `Future<void>` | `String uid` | - |

---

### Arquivo: `lib/providers/business_bi_provider.dart`

#### Classe: `BusinessBiProvider`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `_loadGoals` | `Future<void>` | `` | - |
| `addGoal` | `Future<void>` | `BusinessGoalModel goal` | - |
| `calculatePlannedVsActual` | `double>>` | `TransactionsProvider txProvider, { int? month, int? year, }` | - |
| `_getActualValue` | `double` | `BusinessMetricType metric, TransactionsProvider txProvider` | - |
| `simulateResult` | `double>` | `{ required double revenueAdj, required double costAdj, required double expenseAdj, required TransactionsProvider txProvider, }` | - |

---

### Arquivo: `lib/providers/global_settings_provider.dart`

#### Classe: `GlobalSettingsProvider`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `_init` | `void` | `` | - |
| `updateSetting` | `Future<void>` | `String key, dynamic value` | - |
| `dispose` | `void` | `` | - |

---

### Arquivo: `lib/providers/subscription_provider.dart`

#### Classe: `SubscriptionProvider`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `_hasPromoEmail` | `bool` | `String? email` | - |
| `_init` | `Future<void>` | `` | - |
| `_loadSubscriptionData` | `await` | `user.uid` | - |
| `_loadSubscriptionData` | `Future<void>` | `String uid` | - |
| `upgradeTo` | `Future<void>` | `SubscriptionTier newTier, {required String sessionId, int durationDays = 30}` | - |
| `incrementOCRUsage` | `Future<void>` | `` | - |
| `incrementNegotiationUsage` | `Future<void>` | `` | - |

---

### Arquivo: `lib/providers/transactions_provider.dart`

#### Classe: `TransactionsProvider`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `_loadCache` | `Future<void>` | `` | - |
| `_saveCache` | `Future<void>` | `` | - |
| `updateOSStage` | `Future<void>` | `String osId, String newStageEtapa` | - |
| `_saveCache` | `await` | `` | - |
| `setOmieFilterMode` | `void` | `OmieFilterMode mode` | - |
| `setProjectId` | `void` | `String? id` | - |
| `setDepartmentId` | `void` | `String? id` | - |
| `setUnitId` | `void` | `String? id` | - |
| `setCategoryId` | `void` | `String? id` | - |
| `_invalidateCache` | `void` | `` | - |
| `isIntercompany` | `bool` | `dynamic x` | - |
| `togglePrivacyMode` | `void` | `` | - |
| `setBusinessMode` | `void` | `bool enabled` | - |
| `toggleBusinessMode` | `void` | `[BuildContext? context]` | - |
| `updateUserName` | `Future<void>` | `String name` | - |
| `updateClientLogo` | `Future<void>` | `String base64` | - |
| `toggleConsolidatedMode` | `void` | `` | - |
| `setPeriod` | `void` | `int month, int year` | - |
| `setSpecificDate` | `void` | `DateTime? date` | - |
| `setYear` | `void` | `int year` | - |
| `setCustomRange` | `void` | `DateTime start, DateTime end` | - |
| `filterByCategory` | `void` | `String? categoryId` | - |
| `filterByClient` | `void` | `String? clientId` | - |
| `updateAccountSyncStatus` | `void` | `String accountId, String status, {DateTime? time}` | - |
| `saveOmieAccount` | `Future<void>` | `String name, String key, String secret` | - |
| `_saveAccountsToPrefs` | `await` | `` | - |
| `refreshOmieData` | `await` | `fullSync: true` | - |
| `saveBillingRecord` | `Future<void>` | `{ required String contactName, required double amount, required String dueDate, required String description, required String whatsappText, required String clientId, }` | - |
| `switchAccount` | `Future<void>` | `String id` | - |
| `_saveAccountsToPrefs` | `await` | `` | - |
| `refreshOmieData` | `await` | `fullSync: true` | - |
| `removeAccount` | `Future<void>` | `String id` | - |
| `switchAccount` | `await` | `_omieAccounts.first.id` | - |
| `_saveAccountsToPrefs` | `await` | `` | - |
| `_saveAccountsToPrefs` | `Future<void>` | `` | - |
| `isWithinCurrentFilterDetailed` | `bool` | `dynamic x` | - |
| `_applyGlobalFilters` | `return` | `x` | - |
| `_applyGlobalFilters` | `bool` | `dynamic x` | - |
| `_isWithinCurrentFilter` | `bool` | `DateTime dt` | - |
| `getWalletBalance` | `double` | `String walletId` | - |
| `processList` | `void` | `List<dynamic> list, String key` | - |
| `payOmieBill` | `Future<bool>` | `int nCodLanc, double amount` | - |
| `notify` | `void` | `` | - |
| `startAuthListener` | `void` | `` | - |
| `clearSession` | `await` | `` | - |
| `init` | `await` | `` | - |
| `_getSyncCacheKey` | `String` | `` | - |
| `_getAccountsKey` | `String` | `` | - |
| `_getActiveAccountIdKey` | `String` | `` | - |
| `_getUsingOmieKey` | `String` | `` | - |
| `_getBusinessModeKey` | `String` | `` | - |
| `clearSession` | `Future<void>` | `` | - |
| `init` | `Future<void>` | `` | - |
| `_saveAccountsToPrefs` | `await` | `` | - |
| `_saveAccountsToPrefs` | `await` | `` | - |
| `print` | `Nuvem` | `'✅ [SYNC] Credenciais legado migradas com sucesso!'` | - |
| `_loadCache` | `await` | `` | - |
| `dispose` | `void` | `` | - |
| `setUsingOmie` | `Future<void>` | `bool val` | - |
| `_sumByPeriod` | `double` | `List<dynamic> list` | - |
| `_safeParseDate` | `DateTime` | `dynamic input` | - |
| `DateTime` | `return` | `2000` | - |
| `DateTime` | `return` | `2000` | - |
| `_getCrmOpportunityDeltaForMonth` | `double` | `DateTime targetDate` | - |
| `process` | `void` | `List<dynamic> list, String type` | - |
| `parseOFXDate` | `DateTime` | `String raw` | - |
| `DateTime` | `return` | `year, month, day` | - |
| `updateUserNiche` | `Future<void>` | `String niche` | - |
| `toggleDemoMode` | `void` | `` | - |
| `_loadCache` | `await` | `` | - |
| `_injectDemoData` | `void` | `` | - |

---

### Arquivo: `lib/providers/transactions_provider/parts/bi_intelligence.dart`

*Este arquivo não contém classes estruturadas (pode ser um arquivo de configuração ou somente widgets sem classes).* 

### Arquivo: `lib/providers/transactions_provider/parts/check_panel.dart`

*Este arquivo não contém classes estruturadas (pode ser um arquivo de configuração ou somente widgets sem classes).* 

### Arquivo: `lib/providers/transactions_provider/parts/crm_engine.dart`

*Este arquivo não contém classes estruturadas (pode ser um arquivo de configuração ou somente widgets sem classes).* 

### Arquivo: `lib/providers/transactions_provider/parts/forecasting_engine.dart`

*Este arquivo não contém classes estruturadas (pode ser um arquivo de configuração ou somente widgets sem classes).* 

### Arquivo: `lib/providers/transactions_provider/parts/inventory_bi.dart`

*Este arquivo não contém classes estruturadas (pode ser um arquivo de configuração ou somente widgets sem classes).* 

### Arquivo: `lib/providers/transactions_provider/parts/ops_finance.dart`

*Este arquivo não contém classes estruturadas (pode ser um arquivo de configuração ou somente widgets sem classes).* 

### Arquivo: `lib/providers/transactions_provider/parts/sales_bi.dart`

*Este arquivo não contém classes estruturadas (pode ser um arquivo de configuração ou somente widgets sem classes).* 

### Arquivo: `lib/providers/transactions_provider/parts/semester_flow.dart`

*Este arquivo não contém classes estruturadas (pode ser um arquivo de configuração ou somente widgets sem classes).* 

### Arquivo: `lib/providers/transactions_provider/parts/simulation_core.dart`

*Este arquivo não contém classes estruturadas (pode ser um arquivo de configuração ou somente widgets sem classes).* 

### Arquivo: `lib/providers/transactions_provider/parts/sync_core.dart`

*Este arquivo não contém classes estruturadas (pode ser um arquivo de configuração ou somente widgets sem classes).* 

### Arquivo: `lib/providers/user_stats_provider.dart`

#### Classe: `UserStatsProvider`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `init` | `Future<void>` | `` | - |
| `_initMissions` | `void` | `` | - |
| `_loadBadges` | `void` | `` | - |
| `BadgeModel` | `return` | `id: badge.id, title: badge.title, description: badge.description, icon: badge.icon, unlockedAt: unlocked[badge.id],` | - |
| `addXp` | `Future<void>` | `int amount` | - |
| `reportRadarSurvival` | `Future<void>` | `bool survived` | - |
| `addXp` | `await` | `100` | - |
| `addXp` | `await` | `_dailyMissions[missionIdx].rewardXp` | - |
| `processTransaction` | `void` | `TransactionModel t, int totalTransactions, bool isPremium` | - |
| `reportSubscriptionDeleted` | `void` | `` | - |
| `notifyListeners` | `real` | `` | - |
| `checkMonthlyPerformance` | `void` | `double balance, int positiveMonthsStreak` | - |
| `recordDailyLogin` | `void` | `` | - |
| `addXp` | `await` | `50` | - |

---

## Categoria: RAIZ

### Arquivo: `lib/firebase_options.dart`

#### Classe: `DefaultFirebaseOptions`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `UnsupportedError` | `throw` | `'DefaultFirebaseOptions are not supported for this platform.',` | - |

---

### Arquivo: `lib/main.dart`

#### Classe: `ControleFinanceiroApp extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `ControleFinanceiroApp` | `const` | `{ super.key, required this.showOnboarding }` | - |
| `build` | `Widget` | `BuildContext context` | - |

#### Classe: `AuthGate extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `AuthGate` | `const` | `{super.key}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `AuthSessionLoader` | `const` | `` | - |
| `LoginScreen` | `const` | `` | - |

#### Classe: `AuthSessionLoader extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `AuthSessionLoader` | `const` | `{super.key}` | - |
| `_AuthSessionLoaderState` | `>` | `` | - |

---

## Categoria: SCREENS

### Arquivo: `lib/screens/admin_dashboard_screen.dart`

#### Classe: `AdminDashboardScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `AdminDashboardScreen` | `const` | `{super.key}` | - |
| `_AdminDashboardScreenState` | `>` | `` | - |

#### Classe: `_GlobalSettingsSheet extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `_GlobalSettingsSheet` | `const` | `` | - |
| `build` | `Widget` | `BuildContext context` | - |

---

### Arquivo: `lib/screens/admin_settings_screen.dart`

#### Classe: `AdminSettingsScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `AdminSettingsScreen` | `const` | `{super.key}` | - |
| `_AdminSettingsScreenState` | `>` | `` | - |

---

### Arquivo: `lib/screens/admin_user_details_screen.dart`

#### Classe: `AdminUserDetailsScreen extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `AdminUserDetailsScreen` | `const` | `{super.key, required this.user}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_buildProfileHeader` | `Widget` | `NumberFormat currency` | - |
| `_buildBadge` | `Widget` | `String text, Color color` | - |
| `_buildWalletCard` | `Widget` | `Map<String, dynamic> wallet, NumberFormat currency` | - |
| `_buildGoalCard` | `Widget` | `Map<String, dynamic> goal, NumberFormat currency` | - |

---

### Arquivo: `lib/screens/ai_chat_screen.dart`

#### Classe: `AiChatScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `AiChatScreen` | `const` | `{super.key, this.initialMessage}` | - |
| `_AiChatScreenState` | `>` | `` | - |

---

### Arquivo: `lib/screens/anomaly_alert_screen.dart`

#### Classe: `AnomalyAlertScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `AnomalyAlertScreen` | `const` | `{ super.key, required this.transaction, required this.reason, required this.onConfirm, required this.onCancel, }` | - |
| `_AnomalyAlertScreenState` | `>` | `` | - |

---

### Arquivo: `lib/screens/badges_screen.dart`

#### Classe: `BadgesScreen extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `BadgesScreen` | `const` | `{super.key}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_BadgeCard` | `return` | `badge: template, isUnlocked: isUnlocked, unlockedAt: unlocked[template.id], isBusiness: isBusiness,` | - |
| `_buildXpBar` | `Widget` | `UserStatsProvider stats, bool isBusiness` | - |

#### Classe: `_MissionTile extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `_MissionTile` | `const` | `{required this.mission, required this.isBusiness}` | - |
| `build` | `Widget` | `BuildContext context` | - |

#### Classe: `_BadgeCard extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `_BadgeCard` | `const` | `{ required this.badge, required this.isUnlocked, required this.isBusiness, this.unlockedAt, }` | - |
| `build` | `Widget` | `BuildContext context` | - |

---

### Arquivo: `lib/screens/bank_reconciliation_screen.dart`

#### Classe: `BankReconciliationScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `BankReconciliationScreen` | `const` | `{ super.key, required this.extractedTransactions }` | - |
| `_BankReconciliationScreenState` | `>` | `` | - |

#### Classe: `ReconciliationItem`

*Nenhum método ou função detectado.*

---

### Arquivo: `lib/screens/bank_sync_inbox_screen.dart`

#### Classe: `BankSyncInboxScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `BankSyncInboxScreen` | `const` | `{super.key}` | - |
| `_BankSyncInboxScreenState` | `>` | `` | - |

#### Classe: `_RulesManagerBottomSheet extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `_RulesManagerBottomSheet` | `const` | `` | - |
| `_RulesManagerBottomSheetState` | `>` | `` | - |

---

### Arquivo: `lib/screens/batch_scanner_screen.dart`

#### Classe: `BatchScannedItem`

*Nenhum método ou função detectado.*

#### Classe: `BatchScannerScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `BatchScannerScreen` | `const` | `{super.key, required this.processedItems}` | - |
| `_BatchScannerScreenState` | `>` | `` | - |

---

### Arquivo: `lib/screens/bpo_tower_screen.dart`

#### Classe: `BpoTowerScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `BpoTowerScreen` | `const` | `{super.key, this.isHomeScreen = false}` | - |
| `_BpoTowerScreenState` | `>` | `` | - |

#### Classe: `Rx`

*Nenhum método ou função detectado.*

#### Classe: `_ClientSnap`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `_ClientSnap` | `const` | `{required this.income, required this.expense, required this.txCount}` | - |
| `_ClientSnap` | `const` | `income: 0, expense: 0, txCount: 0` | - |

#### Classe: `_ClientWithSnap`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `_ClientWithSnap` | `const` | `{required this.name, required this.uid, required this.snap}` | - |

#### Classe: `KeepAliveWrapper extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `KeepAliveWrapper` | `const` | `{super.key, required this.child}` | - |
| `_KeepAliveWrapperState` | `>` | `` | - |

#### Classe: `_DonutChartPainter extends CustomPainter`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `paint` | `void` | `Canvas canvas, Size size` | - |
| `shouldRepaint` | `bool` | `covariant _DonutChartPainter oldDelegate` | - |

---

### Arquivo: `lib/screens/break_even_screen.dart`

#### Classe: `BreakEvenScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `BreakEvenScreen` | `const` | `{super.key}` | - |
| `_BreakEvenScreenState` | `>` | `` | - |

---

### Arquivo: `lib/screens/business_dashboard_screen.dart`

#### Classe: `BusinessDashboardScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `BusinessDashboardScreen` | `const` | `{super.key}` | - |
| `_BusinessDashboardScreenState` | `>` | `` | - |

---

### Arquivo: `lib/screens/category_manager_screen.dart`

#### Classe: `CategoryManagerScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `CategoryManagerScreen` | `const` | `{super.key}` | - |
| `_CategoryManagerScreenState` | `>` | `` | - |

---

### Arquivo: `lib/screens/clients_manager_screen.dart`

#### Classe: `ClientsManagerScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `ClientsManagerScreen` | `const` | `{super.key}` | - |
| `_ClientsManagerScreenState` | `>` | `` | - |

---

### Arquivo: `lib/screens/credit_cards_screen.dart`

#### Classe: `CreditCardsScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `CreditCardsScreen` | `const` | `{super.key}` | - |
| `_CreditCardsScreenState` | `>` | `` | - |

---

### Arquivo: `lib/screens/custom_report_screen.dart`

#### Classe: `CustomReportScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `CustomReportScreen` | `const` | `{super.key}` | - |
| `_CustomReportScreenState` | `>` | `` | - |

---

### Arquivo: `lib/screens/document_vault_screen.dart`

#### Classe: `DocumentVaultScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `DocumentVaultScreen` | `const` | `{super.key}` | - |
| `_DocumentVaultScreenState` | `>` | `` | - |

---

### Arquivo: `lib/screens/dre_what_if_screen.dart`

#### Classe: `DreWhatIfScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `DreWhatIfScreen` | `const` | `{super.key}` | - |
| `_DreWhatIfScreenState` | `>` | `` | - |

---

### Arquivo: `lib/screens/family_setup_screen.dart`

#### Classe: `FamilySetupScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `FamilySetupScreen` | `const` | `{super.key}` | - |
| `_FamilySetupScreenState` | `>` | `` | - |

---

### Arquivo: `lib/screens/freelancer_kanban_screen.dart`

#### Classe: `FreelancerKanbanScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `FreelancerKanbanScreen` | `const` | `{super.key}` | - |
| `_FreelancerKanbanScreenState` | `>` | `` | - |

---

### Arquivo: `lib/screens/future_planning_screen.dart`

#### Classe: `FuturePlanningScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `FuturePlanningScreen` | `const` | `{super.key}` | - |
| `_FuturePlanningScreenState` | `>` | `` | - |

---

### Arquivo: `lib/screens/glauber_profile_screen.dart`

#### Classe: `GlauberProfileScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `GlauberProfileScreen` | `const` | `{super.key}` | - |
| `_GlauberProfileScreenState` | `>` | `` | - |

---

### Arquivo: `lib/screens/goals_screen.dart`

#### Classe: `GoalsScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `GoalsScreen` | `const` | `{super.key}` | - |
| `_GoalsScreenState` | `>` | `` | - |

#### Classe: `_GoalCard extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `_GoalCard` | `const` | `{required this.goal, required this.onDeposit, required this.onEdit}` | - |
| `build` | `Widget` | `BuildContext context` | - |

---

### Arquivo: `lib/screens/home_screen.dart`

#### Classe: `HomeScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `HomeScreen` | `const` | `{super.key}` | - |
| `_HomeScreenState` | `>` | `` | - |

#### Classe: `DotGridPainter extends CustomPainter`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `paint` | `void` | `Canvas canvas, Size size` | - |

#### Classe: `ConfettiParticle`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `update` | `void` | `` | - |

---

### Arquivo: `lib/screens/insights_screen.dart`

#### Classe: `InsightsScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `InsightsScreen` | `const` | `{super.key}` | - |
| `_InsightsScreenState` | `>` | `` | - |

#### Classe: `_ScoreGaugePainter extends CustomPainter`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `paint` | `void` | `Canvas canvas, Size size` | - |

#### Classe: `_DotGridPainter extends CustomPainter`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `paint` | `void` | `Canvas canvas, Size size` | - |

---

### Arquivo: `lib/screens/login_screen.dart`

#### Classe: `LoginScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `LoginScreen` | `const` | `{super.key}` | - |
| `_LoginScreenState` | `>` | `` | - |

#### Classe: `DotGridPainter extends CustomPainter`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `paint` | `void` | `Canvas canvas, Size size` | - |

---

### Arquivo: `lib/screens/my_subscriptions_screen.dart`

#### Classe: `MySubscriptionsScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `MySubscriptionsScreen` | `const` | `{super.key}` | - |
| `_MySubscriptionsScreenState` | `>` | `` | - |

---

### Arquivo: `lib/screens/omie_billing_screen.dart`

#### Classe: `OmieBillingScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OmieBillingScreen` | `const` | `{super.key}` | - |
| `_OmieBillingScreenState` | `>` | `` | - |

---

### Arquivo: `lib/screens/omie_setup_wizard_screen.dart`

#### Classe: `OmieSetupWizardScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OmieSetupWizardScreen` | `const` | `{super.key}` | - |
| `_OmieSetupWizardScreenState` | `>` | `` | - |

---

### Arquivo: `lib/screens/onboarding_screen.dart`

#### Classe: `OnboardingScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OnboardingScreen` | `const` | `{super.key}` | - |
| `_OnboardingScreenState` | `>` | `` | - |

#### Classe: `DotGridPainter extends CustomPainter`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `paint` | `void` | `Canvas canvas, Size size` | - |

#### Classe: `OnboardingData`

*Nenhum método ou função detectado.*

---

### Arquivo: `lib/screens/saving_goals_screen.dart`

#### Classe: `SavingGoalsScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `SavingGoalsScreen` | `const` | `{super.key}` | - |
| `_SavingGoalsScreenState` | `>` | `` | - |

---

### Arquivo: `lib/screens/scanner_screen.dart`

#### Classe: `ScannerScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `ScannerScreen` | `const` | `{super.key}` | - |
| `_ScannerScreenState` | `>` | `` | - |

#### Classe: `_ScannerButton extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `_ScannerButton` | `const` | `{ required this.icon, required this.label, required this.onPressed, this.isSecondary = false, this.trailing, }` | - |
| `build` | `Widget` | `BuildContext context` | - |

---

### Arquivo: `lib/screens/settings_screen.dart`

#### Classe: `SettingsScreen extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `SettingsScreen` | `const` | `{super.key}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_buildSectionTitle` | `Widget` | `String title` | - |
| `_buildSubscriptionCard` | `Widget` | `BuildContext context, SubscriptionProvider provider` | - |
| `_buildBusinessSection` | `Widget` | `BuildContext context, TransactionsProvider provider, SubscriptionProvider subProvider` | - |
| `_buildAccountItem` | `Widget` | `BuildContext context, OmieAccount acc, TransactionsProvider provider` | - |
| `_showAddAccountDialog` | `void` | `BuildContext context, TransactionsProvider provider` | - |
| `_confirmDeleteAccount` | `void` | `BuildContext context, OmieAccount acc, TransactionsProvider provider` | - |
| `_buildSettingsTile` | `Widget` | `{ required IconData icon, required String title, required String subtitle, required VoidCallback onTap, Widget? trailing, Color? color, }` | - |
| `_exportToCsv` | `void` | `BuildContext context, SubscriptionProvider sub, TransactionsProvider trans` | - |

---

### Arquivo: `lib/screens/simulation_screen.dart`

#### Classe: `SimulationScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `SimulationScreen` | `const` | `{super.key}` | - |
| `_SimulationScreenState` | `>` | `` | - |

---

### Arquivo: `lib/screens/subscription_dashboard_screen.dart`

#### Classe: `SubscriptionDashboardScreen extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `SubscriptionDashboardScreen` | `const` | `{super.key}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_buildTierBadge` | `Widget` | `SubscriptionTier tier` | - |
| `_buildCountdownCard` | `Widget` | `int days, bool isPremium` | - |
| `_buildBenefitsList` | `Widget` | `SubscriptionTier tier` | - |
| `_buildBenefitItem` | `Widget` | `String title, String status, bool isActive` | - |
| `_buildActionButtons` | `Widget` | `BuildContext context, bool isPremium` | - |

---

### Arquivo: `lib/screens/upgrade_screen.dart`

#### Classe: `UpgradeScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `UpgradeScreen` | `const` | `{super.key}` | - |
| `_UpgradeScreenState` | `>` | `` | - |

---

### Arquivo: `lib/screens/user_profile_screen.dart`

#### Classe: `UserProfileScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `UserProfileScreen` | `const` | `{super.key}` | - |
| `_UserProfileScreenState` | `>` | `` | - |

#### Classe: `_DotGridPainter extends CustomPainter`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `paint` | `void` | `Canvas canvas, Size size` | - |

---

### Arquivo: `lib/screens/wallets_screen.dart`

#### Classe: `WalletsScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `WalletsScreen` | `const` | `{super.key}` | - |
| `_WalletsScreenState` | `>` | `` | - |

---

### Arquivo: `lib/screens/war_room_screen.dart`

#### Classe: `WarRoomScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `WarRoomScreen` | `const` | `{super.key}` | - |
| `_WarRoomScreenState` | `>` | `` | - |

#### Classe: `GridPainter extends CustomPainter`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `paint` | `void` | `Canvas canvas, Size size` | - |

---

### Arquivo: `lib/screens/whatsapp_cobranca_screen.dart`

#### Classe: `WhatsAppCobrancaScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `WhatsAppCobrancaScreen` | `const` | `{ super.key, this.initialClientName, this.initialAmount, this.initialDescription, }` | - |
| `_WhatsAppCobrancaScreenState` | `>` | `` | - |

---

### Arquivo: `lib/screens/zen_investments_screen.dart`

#### Classe: `ZenInvestmentsScreen extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `ZenInvestmentsScreen` | `const` | `{super.key}` | - |
| `_ZenInvestmentsScreenState` | `>` | `` | - |

---

## Categoria: SERVICES

### Arquivo: `lib/services/ai_chat_service.dart`

#### Classe: `AiChatService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `_ensureGeminiInitialized` | `Future<void>` | `` | - |
| `getAdvice` | `Future<String>` | `String message, List<TransactionModel> transactions, {String? businessContext}` | - |
| `_getOpenAIAdvice` | `return` | `message, systemContext, assistantName` | - |
| `_getGeminiAdvice` | `return` | `message, systemContext, assistantName` | - |
| `_getOpenAIAdvice` | `Future<String>` | `String message, String context, String assistantName` | - |
| `_getGeminiAdvice` | `Future<String>` | `String message, String context, String assistantName` | - |
| `_ensureGeminiInitialized` | `await` | `` | - |
| `_ensureGeminiInitialized` | `await` | `` | - |
| `_buildSystemContext` | `String` | `List<TransactionModel> transactions, String? businessContext, { required String assistantName, required String personality, required List<String> memories, }` | - |
| `generateNegotiationProposal` | `Future<String>` | `{ required String contactName, required double amount, required String dueDate, required String description, required String type, }` | - |
| `_ensureGeminiInitialized` | `await` | `` | - |

---

### Arquivo: `lib/services/ai_insight_service.dart`

#### Classe: `AiAction`

*Nenhum método ou função detectado.*

#### Classe: `AiInsightResult`

*Nenhum método ou função detectado.*

#### Classe: `AiInsightService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `getSmartAlert` | `>` | `TransactionsProvider provider` | - |
| `_getOpenAIInsight` | `return` | `provider` | - |
| `_getGeminiInsight` | `return` | `provider` | - |
| `_getGeminiInsight` | `>` | `TransactionsProvider provider` | - |
| `_parseResponse` | `return` | `response.text` | - |
| `_getOpenAIInsight` | `>` | `TransactionsProvider provider` | - |
| `_getGeminiInsight` | `return` | `provider` | - |
| `_parseResponse` | `return` | `content` | - |
| `_getGeminiInsight` | `return` | `provider` | - |
| `_buildPrompt` | `String` | `TransactionsProvider provider` | - |
| `_parseResponse` | `AiInsightResult?` | `String? text` | - |

---

### Arquivo: `lib/services/analysis_service.dart`

#### Classe: `AnalysisService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `getQuickInsight` | `String` | `List<TransactionModel> transactions` | `static` |
| `getWeeklyData` | `List<double>` | `List<TransactionModel> transactions` | `static` |

---

### Arquivo: `lib/services/anomaly_service.dart`

#### Classe: `AnomalyResult`

*Nenhum método ou função detectado.*

#### Classe: `AnomalyService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `check` | `AnomalyResult` | `TransactionModel transaction, List<TransactionModel> history` | `static` |
| `AnomalyResult` | `return` | `isSuspect: false, reason: 'Modo Aprendizado Ativo.'` | - |
| `AnomalyResult` | `return` | `isSuspect: true, reason: 'Valor muito acima da sua média habitual para esta categoria.', score: 0.8` | - |
| `AnomalyResult` | `return` | `isSuspect: false, reason: 'Dentro do padrão esperado.'` | - |

---

### Arquivo: `lib/services/auth_lock_service.dart`

#### Classe: `AuthLockService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `isBiometricAvailable` | `Future<bool>` | `` | - |
| `authenticate` | `Future<bool>` | `` | - |

---

### Arquivo: `lib/services/bank_import_service.dart`

#### Classe: `BankImportService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `parseOFX` | `dynamic>>` | `String content` | - |
| `parseCSV` | `dynamic>>` | `String content` | - |
| `_extractTag` | `String?` | `String text, String tag` | - |
| `_parseOFXDate` | `DateTime` | `String raw` | - |
| `DateTime` | `return` | `year, month, day` | - |
| `processExtractedDocuments` | `List<TransactionModel>` | `List<ExtractedDocument> docs` | - |
| `enrichWithAI` | `Future<List<TransactionModel>>` | `List<Map<String, dynamic>> rawItems` | - |

---

### Arquivo: `lib/services/bank_sync_service.dart`

#### Classe: `BankSyncService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `onNotificationCallback` | `void` | `NotificationEvent evt` | `static` |
| `_ensureInitialized` | `await` | `` | - |
| `_processBankNotification` | `suspensa` | `evt` | - |
| `_ensureInitialized` | `Future<void>` | `` | `static` |
| `init` | `Future<void>` | `` | `static` |
| `_ensureInitialized` | `await` | `` | - |
| `_generateUniqueKey` | `String` | `NotificationEvent event` | `static` |
| `_isDuplicate` | `Future<bool>` | `String uniqueKey` | `static` |
| `_suggestCategoryByHistory` | `>` | `String participant, bool isIncome` | - |
| `_findMatchingTitle` | `>` | `OcrResult result` | - |
| `_getFriendlyAppName` | `String` | `String packageName` | `static` |
| `_processBankNotification` | `void` | `NotificationEvent event` | `static` |
| `_findMatchingTitle` | `await` | `result` | - |
| `_suggestCategoryByHistory` | `await` | `result.restaurant ?? '', result.isIncome` | - |
| `debugPrint` | `DB` | `"💾 [DEBUG] Saving auto-reconciled transaction to DB with amount: ${result.amount}, category: $finalCategoryString"` | - |
| `_showSyncSuggestion` | `Future<void>` | `OcrResult result, { required String finalCategory, int? nCodLanc, Map<String, dynamic>? match, required String uniqueKey, bool isSuspect = false, String? anomalyReason, }` | `static` |
| `_handleNotificationAction` | `void` | `NotificationResponse response` | `static` |
| `_payOmieBillInBackground` | `Future<void>` | `int nCodLanc, double amount` | `static` |
| `requestPermission` | `Future<void>` | `` | `static` |

---

### Arquivo: `lib/services/bio_auth_service.dart`

#### Classe: `BioAuthService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `isBiometricsAvailable` | `Future<bool>` | `` | - |
| `authenticate` | `Future<bool>` | `` | - |
| `isEnabled` | `Future<bool>` | `` | - |
| `setEnabled` | `Future<void>` | `bool enabled` | - |

---

### Arquivo: `lib/services/bpo_pdf_service.dart`

#### Classe: `BpoClientSnap`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `BpoClientSnap` | `const` | `{required this.income, required this.expense, required this.txCount}` | - |

#### Classe: `BpoPdfService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `generateAndPrintExecutivePdf` | `Future<void>` | `{ required String clientName, required String regime, required BpoClientSnap snap, required String accountantNotes, }` | `static` |

---

### Arquivo: `lib/services/budget_service.dart`

#### Classe: `BudgetService extends ChangeNotifier`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `_init` | `void` | `` | - |
| `setBudget` | `Future<void>` | `String category, double amount` | - |
| `deleteBudget` | `Future<void>` | `String category` | - |
| `getProgress` | `double` | `String category, double currentSpent` | - |
| `isOverBudget` | `bool` | `String category, double currentSpent` | - |
| `isNearLimit` | `bool` | `String category, double currentSpent` | - |

---

### Arquivo: `lib/services/coach_service.dart`

#### Classe: `CoachInsight`

*Nenhum método ou função detectado.*

#### Classe: `CoachService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `_ensureGeminiInitialized` | `Future<void>` | `` | - |
| `init` | `void` | `String apiKey` | - |
| `generateDailyInsight` | `>` | `List<TransactionModel> transactions` | - |
| `_getOpenAICoachInsight` | `return` | `transactions` | - |
| `_getGeminiCoachInsight` | `return` | `transactions` | - |
| `_getOpenAICoachInsight` | `>` | `List<TransactionModel> transactions` | - |
| `CoachInsight` | `return` | `text: text` | - |
| `_getGeminiCoachInsight` | `>` | `List<TransactionModel> transactions` | - |
| `_ensureGeminiInitialized` | `await` | `` | - |
| `CoachInsight` | `return` | `text: response.text!` | - |
| `_buildCoachPrompt` | `String` | `List<TransactionModel> transactions` | - |

---

### Arquivo: `lib/services/config_service.dart`

#### Classe: `ConfigService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `getGeminiApiKeys` | `Future<List<String>>` | `` | - |
| `getGeminiApiKey` | `>` | `` | - |
| `getGeminiApiKeys` | `await` | `` | - |
| `setGeminiApiKey` | `Future<void>` | `String key` | - |
| `getOpenAIApiKey` | `>` | `` | - |
| `setOpenAIApiKey` | `Future<void>` | `String key` | - |
| `getAiProvider` | `Future<String>` | `` | - |
| `setAiProvider` | `Future<void>` | `String provider` | - |
| `getAutoBusinessAi` | `Future<bool>` | `` | - |
| `setAutoBusinessAi` | `Future<void>` | `bool enabled` | - |
| `hasAiKey` | `Future<bool>` | `` | - |
| `getAiProvider` | `await` | `` | - |
| `getGeminiApiKey` | `await` | `` | - |
| `getOpenAIApiKey` | `await` | `` | - |

---

### Arquivo: `lib/services/csv_export_service.dart`

#### Classe: `CsvExportService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `exportTransactionsToCsv` | `>` | `List<TransactionModel> transactions` | - |
| `getApplicationDocumentsDirectory` | `await` | `` | - |

---

### Arquivo: `lib/services/document_ai_service.dart`

#### Classe: `ExtractedDocument`

*Nenhum método ou função detectado.*

#### Classe: `DocumentAiService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `processDocument` | `>` | `Uint8List bytes, String mimeType` | - |
| `_processDocumentWithOpenAI` | `return` | `bytes, mimeType` | - |
| `_processDocumentWithGemini` | `return` | `bytes, mimeType` | - |
| `_processDocumentWithOpenAI` | `>` | `Uint8List bytes, String mimeType` | - |
| `Exception` | `throw` | `'API Key da OpenAI não configurada.'` | - |
| `_processDocumentWithGemini` | `>` | `Uint8List bytes, String mimeType` | - |
| `_buildDocumentPrompt` | `String` | `` | - |
| `processBankStatement` | `Future<List<ExtractedDocument>>` | `Uint8List bytes, String mimeType` | - |
| `_buildBankStatementPrompt` | `String` | `` | - |
| `analyzeRawText` | `Future<String>` | `String text` | - |
| `_analyzeTextWithOpenAI` | `return` | `text, apiKey` | - |
| `_analyzeTextWithGemini` | `return` | `text, apiKey` | - |
| `_analyzeTextWithOpenAI` | `Future<String>` | `String text, String apiKey` | - |
| `_analyzeTextWithGemini` | `Future<String>` | `String text, String apiKey` | - |

---

### Arquivo: `lib/services/excel_export_service.dart`

#### Classe: `ExcelExportService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `exportToExcel` | `Future<void>` | `TransactionsProvider provider` | `static` |
| `getTemporaryDirectory` | `await` | `` | - |

---

### Arquivo: `lib/services/feature_discovery_service.dart`

#### Classe: `FeatureDiscoveryService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `shouldShowTour` | `Future<bool>` | `` | - |
| `markTourAsCompleted` | `Future<void>` | `` | - |
| `resetTour` | `Future<void>` | `` | - |

---

### Arquivo: `lib/services/ocr_service.dart`

#### Classe: `OcrResult`

*Nenhum método ou função detectado.*

#### Classe: `OcrService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `processImage` | `Future<OcrResult>` | `String imagePath` | - |
| `_parseExtractedText` | `return` | `fullText` | - |
| `_parseExtractedText` | `OcrResult` | `String fullText` | - |
| `parseNotification` | `OcrResult` | `String text` | - |
| `cleanName` | `String` | `String name` | - |
| `dispose` | `void` | `` | - |
| `parseNotificationWithAi` | `>` | `String text` | - |
| `conta` | `na` | `recebido/Pix recebido/depósito` | - |

---

### Arquivo: `lib/services/omie_service.dart`

#### Classe: `OmieService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `_postWithRetry` | `>` | `Uri url, Map<String, dynamic> body, {int remainingRetries = 3}` | - |
| `_postWithRetry` | `return` | `url, body, remainingRetries: remainingRetries - 1` | - |
| `getFinancialSummary` | `>` | `` | - |
| `_postWithRetry` | `await` | `url, body` | - |
| `listAccountsReceivable` | `Future<List<dynamic>>` | `` | - |
| `_postWithRetry` | `await` | `url, body` | - |
| `listAccountsPayable` | `Future<List<dynamic>>` | `` | - |
| `_postWithRetry` | `await` | `url, body` | - |
| `listCategories` | `String>>` | `` | - |
| `_postWithRetry` | `await` | `url, body` | - |
| `listClients` | `String>>` | `` | - |
| `_postWithRetry` | `await` | `url, body` | - |
| `listProjects` | `String>>` | `` | - |
| `_postWithRetry` | `await` | `url, body` | - |
| `listDepartments` | `String>>` | `` | - |
| `_postWithRetry` | `await` | `url, body` | - |
| `listBusinessUnits` | `String>>` | `` | - |
| `_postWithRetry` | `await` | `url, body` | - |
| `listServiceOrders` | `Future<List<dynamic>>` | `` | - |
| `_postWithRetry` | `await` | `url, body` | - |
| `listSalesOrders` | `Future<List<dynamic>>` | `` | - |
| `_postWithRetry` | `await` | `url, body` | - |
| `getCompanyCnpj` | `>` | `` | - |
| `_postWithRetry` | `await` | `url, body` | - |
| `payBill` | `Future<bool>` | `int nCodLanc, double amount` | - |
| `_postWithRetry` | `await` | `url, body` | - |
| `addAccountReceivable` | `Future<bool>` | `{ required int clientCode, required String dueDate, required double amount, required String categoryCode, required String description, }` | - |
| `_postWithRetry` | `await` | `url, body` | - |

---

### Arquivo: `lib/services/pdf_report_service.dart`

#### Classe: `PdfReportService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `generateExecutiveReport` | `Future<void>` | `TransactionsProvider provider` | `static` |
| `generateCustomExecutiveReport` | `Future<void>` | `TransactionsProvider provider, { required String title, required String subtitle, required bool showKpis, required bool showAging, required bool showTaxes, required bool showNotes, bool showTopExpenses = true, bool showScore = true, bool showTopClientsSuppliers = true, bool showMoMComparison = true, bool showBankBalances = true, bool showSentinelaReport = true, bool showRunwayStats = true, bool showSparkline = true, String primaryColorHex = '#2563EB', String consultantNotes = '', String? logoBase64, }` | `static` |
| `safeParseDate` | `DateTime` | `dynamic input` | - |
| `DateTime` | `return` | `2000` | - |
| `DateTime` | `return` | `2000` | - |
| `isWithinPrevPeriod` | `bool` | `dynamic item` | - |
| `generateCashFlowReport` | `Future<void>` | `TransactionsProvider provider` | `static` |
| `generateMultiCompany6MonthReport` | `Future<void>` | `TransactionsProvider provider` | `static` |
| `addToConsolidated` | `void` | `Map<String, List<double>> target, Map<String, List<double>> source` | - |
| `_buildCategoryRows` | `TableRow>` | `Map<String, List<double>> data, List<String> categories, PdfColor bgColor, NumberFormat currency` | - |
| `_buildSummaryRow` | `TableRow` | `String label, Map<String, List<double>> data, List<String> categories, PdfColor bgColor, NumberFormat currency` | - |
| `_buildDynamicNetProfitRow` | `TableRow` | `String label, Map<String, List<double>> income, Map<String, List<double>> expense, PdfColor bgColor, NumberFormat currency` | - |
| `_buildKpiCard` | `Widget` | `String title, String value, PdfColor color` | - |

---

### Arquivo: `lib/services/pdf_service.dart`

#### Classe: `PdfService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `generateBusinessReport` | `Future<void>` | `TransactionsProvider provider` | `static` |
| `_buildMetricBox` | `Widget` | `String label, String value, PdfColor color` | - |

---

### Arquivo: `lib/services/premium_service.dart`

#### Classe: `PremiumService extends ChangeNotifier`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `upgradeToPremium` | `void` | `` | - |
| `resetPremium` | `void` | `` | - |

---

### Arquivo: `lib/services/proactive_insight_service.dart`

#### Classe: `ProactiveInsight`

*Nenhum método ou função detectado.*

#### Classe: `ProactiveInsightService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `generateInsights` | `List<ProactiveInsight>` | `TransactionsProvider provider` | `static` |
| `_checkCategorySaving` | `void` | `List<TransactionModel> thisWeek, List<TransactionModel> lastWeek, String category, List<ProactiveInsight> insights` | `static` |

---

### Arquivo: `lib/services/push_notification_service.dart`

#### Classe: `PushNotificationService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `init` | `Future<void>` | `` | `static` |
| `_saveToken` | `await` | `token` | - |
| `_setupMessageHandlers` | `mensagens` | `` | - |
| `_saveToken` | `Future<void>` | `String token` | `static` |
| `_setupMessageHandlers` | `void` | `` | `static` |
| `firebaseMessagingBackgroundHandler` | `Future<void>` | `RemoteMessage message` | `static` |

---

### Arquivo: `lib/services/realtime_db_service.dart`

#### Classe: `RealtimeDbService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `setBpoActiveClient` | `void` | `String? clientUid` | - |
| `init` | `Future<void>` | `` | - |
| `createFamily` | `Future<String>` | `` | - |
| `_migrateToFamily` | `await` | `uid, familyId` | - |
| `updateUserProfile` | `Future<void>` | `Map<String, dynamic> data` | - |
| `saveClientLogo` | `Future<void>` | `String base64` | - |
| `getClientLogo` | `>` | `` | - |
| `getUserProfile` | `>` | `` | - |
| `initializeNewUser` | `Future<void>` | `String email, {required String niche}` | - |
| `_migrateToFamily` | `Future<void>` | `String uid, String familyId` | - |
| `joinFamily` | `Future<bool>` | `String familyId` | - |
| `getTransactions` | `Stream<List<TransactionModel>>` | `` | - |
| `addTransaction` | `Future<void>` | `TransactionModel transaction` | - |
| `deleteTransaction` | `Future<void>` | `String id` | - |
| `getCategories` | `Stream<List<String>>` | `` | - |
| `addCategory` | `Future<void>` | `String category` | - |
| `getBudgets` | `double>>` | `` | - |
| `setBudget` | `Future<void>` | `String category, double amount` | - |
| `deleteBudget` | `Future<void>` | `String category` | - |
| `getGoals` | `Stream<List<GoalModel>>` | `` | - |
| `addGoal` | `Future<void>` | `GoalModel goal` | - |
| `unlockBadge` | `await` | `'first_goal'` | - |
| `updateGoalProgress` | `Future<void>` | `String goalId, double newAmount` | - |
| `deleteGoal` | `Future<void>` | `String goalId` | - |
| `getWallets` | `Stream<List<WalletModel>>` | `` | - |
| `addWallet` | `Future<void>` | `WalletModel wallet` | - |
| `updateWallet` | `Future<void>` | `String walletId, Map<String, dynamic> data` | - |
| `deleteWallet` | `Future<void>` | `String walletId` | - |
| `getCreditCards` | `Stream<List<CreditCardModel>>` | `` | - |
| `addCreditCard` | `Future<void>` | `CreditCardModel card` | - |
| `updateCreditCard` | `Future<void>` | `String cardId, Map<String, dynamic> data` | - |
| `deleteCreditCard` | `Future<void>` | `String cardId` | - |
| `getSubscriptions` | `dynamic>>>` | `` | - |
| `addSubscription` | `Future<void>` | `Map<String, dynamic> subscription` | - |
| `deleteSubscription` | `Future<void>` | `String id` | - |
| `getUnlockedBadges` | `DateTime>>` | `` | - |
| `unlockBadge` | `Future<void>` | `String badgeId` | - |
| `saveOmieCredentials` | `Future<void>` | `String key, String secret` | - |
| `getOmieCredentials` | `>` | `` | - |
| `saveOmieSyncData` | `Future<void>` | `String type, List<dynamic> items` | - |
| `getOmieSyncData` | `Stream<List<dynamic>>` | `String type` | - |
| `saveOmieCategories` | `Future<void>` | `Map<String, String> categories` | - |
| `getOmieCategories` | `String>>` | `` | - |
| `saveOmieClients` | `Future<void>` | `Map<String, String> clients` | - |
| `getOmieClients` | `String>>` | `` | - |
| `saveOmieProjects` | `Future<void>` | `Map<String, String> projects` | - |
| `getOmieProjects` | `String>>` | `` | - |
| `saveOmieSummary` | `Future<void>` | `Map<String, dynamic> summary` | - |
| `getOmieSummary` | `dynamic>>` | `` | - |
| `saveOmieOS` | `Future<void>` | `List<dynamic> items` | - |
| `getOmieOS` | `Stream<List<dynamic>>` | `` | - |
| `saveOmieOrders` | `Future<void>` | `List<dynamic> items` | - |
| `getOmieOrders` | `Stream<List<dynamic>>` | `` | - |
| `saveOmieAccounts` | `Future<void>` | `List<Map<String, dynamic>> accounts` | - |
| `getOmieAccounts` | `dynamic>>>` | `` | - |
| `setActiveOmieAccountId` | `Future<void>` | `String id` | - |
| `getActiveOmieAccountId` | `>` | `` | - |
| `saveOmieGoal` | `Future<void>` | `double goal` | - |
| `getOmieGoal` | `Stream<double>` | `` | - |
| `getChallenges` | `Stream<List<ChallengeModel>>` | `` | - |
| `addChallenge` | `Future<void>` | `ChallengeModel challenge` | - |
| `updateChallenge` | `Future<void>` | `ChallengeModel challenge` | - |
| `deleteChallenge` | `Future<void>` | `String id` | - |
| `getAllUsers` | `dynamic>>>` | `` | - |
| `updateUserRole` | `Future<void>` | `String uid, String role` | - |
| `makeUserSuperAdminByEmail` | `Future<void>` | `String email` | - |
| `promoteCurrentUserToAdmin` | `Future<void>` | `` | - |
| `deleteUser` | `Future<void>` | `String uid` | - |
| `saveBpoClientTaxRegime` | `Future<void>` | `String clientUid, String regime` | - |
| `saveBpoClientTags` | `Future<void>` | `String clientUid, List<String> tags` | - |
| `addBpoClientFiscalEvent` | `Future<void>` | `String clientUid, Map<String, dynamic> event` | - |
| `getBpoClientFiscalCalendar` | `dynamic>>>` | `String clientUid` | - |
| `toggleBpoClientFiscalEventStatus` | `Future<void>` | `String clientUid, String eventId, bool isDone` | - |
| `deleteBpoClientFiscalEvent` | `Future<void>` | `String clientUid, String eventId` | - |
| `setBpoClientMessage` | `Future<void>` | `String clientUid, String message` | - |
| `getBpoMessageForClient` | `>` | `` | - |
| `saveBpoClientNote` | `Future<void>` | `String clientUid, String note` | - |
| `getClientNote` | `>` | `String clientUid` | - |
| `addAuditLog` | `Future<void>` | `Map<String, dynamic> entry` | - |
| `getAuditLogs` | `dynamic>>>` | `` | - |
| `getClientRecentTransactions` | `dynamic>>>` | `String clientUid, { int limit = 6, }` | - |
| `getBpoClients` | `dynamic>>>` | `` | - |
| `getSavingGoals` | `dynamic>>>` | `` | - |
| `addSavingGoal` | `Future<void>` | `Map<String, dynamic> goal` | - |
| `updateGoalAmount` | `Future<void>` | `String id, double newAmount` | - |
| `deleteSavingGoal` | `Future<void>` | `String id` | - |
| `saveBillingRecord` | `Future<void>` | `{ required String contactName, required double amount, required String dueDate, required String description, required String whatsappText, required String clientId, }` | - |
| `getBillingHistory` | `dynamic>>>` | `` | - |
| `saveLocalClient` | `Future<void>` | `String id, Map<String, dynamic> client` | - |
| `deleteLocalClient` | `Future<void>` | `String id` | - |
| `getTransactionsOnce` | `Future<List<TransactionModel>>` | `` | - |
| `init` | `await` | `` | - |
| `addNotificationLog` | `Future<void>` | `String logId, Map<String, dynamic> log` | - |
| `init` | `await` | `` | - |
| `getNotificationLogs` | `dynamic>>>` | `` | - |
| `updateNotificationLogStatus` | `Future<void>` | `String logId, String status` | - |
| `init` | `await` | `` | - |
| `updateNotificationLogStatusAndFlags` | `Future<void>` | `String logId, {required String status, required bool autoReconciled}` | - |
| `init` | `await` | `` | - |
| `getReconciliationRules` | `dynamic>>>` | `` | - |
| `getReconciliationRulesOnce` | `dynamic>>>` | `` | - |
| `init` | `await` | `` | - |
| `addReconciliationRule` | `Future<void>` | `Map<String, dynamic> rule` | - |
| `init` | `await` | `` | - |
| `deleteReconciliationRule` | `Future<void>` | `String ruleId` | - |
| `init` | `await` | `` | - |
| `saveLocalService` | `Future<void>` | `String id, Map<String, dynamic> service` | - |
| `deleteLocalService` | `Future<void>` | `String id` | - |
| `updateLocalServiceStatus` | `Future<void>` | `String id, String status` | - |
| `getLocalServices` | `dynamic>>>` | `` | - |
| `saveGlauberProfile` | `Future<void>` | `Map<String, dynamic> profile` | - |
| `addGlauberMemory` | `Future<void>` | `String memory` | - |
| `deleteGlauberMemory` | `Future<void>` | `int index` | - |
| `getGlauberProfile` | `dynamic>>` | `` | - |
| `savePixKey` | `Future<void>` | `String key` | - |
| `getPixKey` | `Stream<String>` | `` | - |
| `linkClientToBpo` | `Future<bool>` | `String clientUid, String clientName, {String? phone}` | - |
| `saveClientNote` | `Future<void>` | `String clientUid, String note` | - |
| `saveBpoClientNote` | `await` | `clientUid, note` | - |
| `saveBpoClientRegimeAndTags` | `Future<void>` | `String clientUid, String regime, List<String> tags, {String? phone}` | - |
| `saveBpoClientMessage` | `Future<void>` | `String clientUid, String message, bool visibleToClient` | - |
| `getBpoClientMessage` | `>` | `String clientUid` | - |
| `saveBpoFee` | `Future<void>` | `String clientUid, double amount, int dueDay, String status, {String? phone}` | - |
| `getBpoFees` | `dynamic>>` | `` | - |
| `getClientTransactions` | `Stream<List<TransactionModel>>` | `String clientUid` | - |
| `getBpoDocuments` | `dynamic>>` | `` | - |
| `saveBpoDocumentStatus` | `Future<void>` | `String clientUid, String docType, bool value` | - |
| `getLocalClients` | `dynamic>>>` | `` | - |
| `getBpoNotes` | `dynamic>>` | `` | - |
| `addBpoNote` | `Future<void>` | `String text` | - |
| `deleteBpoNote` | `Future<void>` | `String noteId` | - |
| `addManualTransaction` | `Future<void>` | `String targetUid, TransactionModel transaction` | - |
| `getClientTransactionsOnce` | `Future<List<TransactionModel>>` | `String clientUid` | - |
| `getBpoPixKey` | `Future<String>` | `String bpoUid` | - |
| `payBpoFee` | `Future<void>` | `String bpoUid, double amount, int dueDay` | - |
| `saveBpoClientRevenueGoal` | `Future<void>` | `String clientUid, double targetAmount` | - |
| `getBpoClientRevenueGoal` | `Stream<double>` | `` | - |
| `sendBpoMessageToMural` | `Future<void>` | `String clientUid, String messageText` | - |
| `markBpoMessageAsRead` | `Future<void>` | `String messageId` | - |
| `getBpoMessagesForClient` | `dynamic>>>` | `` | - |
| `getBpoClientSentMessages` | `dynamic>>>` | `String clientUid` | - |

---

### Arquivo: `lib/services/recurrence_service.dart`

#### Classe: `RecurringPattern`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `RecurringPattern` | `histórico` | `{ required this.category, required this.amount, required this.averageDay, required this.frequency, }` | - |

#### Classe: `RecurrenceService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `detectPatterns` | `List<RecurringPattern>` | `List<TransactionModel> transactions` | `static` |

---

### Arquivo: `lib/services/stripe_service.dart`

#### Classe: `StripeService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `createCheckoutSession` | `>` | `{ required String planName, required double amount, required String interval, int intervalCount = 1 }` | - |
| `verifyPaymentStatus` | `Future<bool>` | `String sessionId` | - |
| `print` | `finalizada` | `'🧠 [STRIPE] Status da Sessão: $status, Pagamento: $paymentStatus'` | - |
| `launchStripeCheckout` | `Future<bool>` | `String url` | - |
| `launchUrl` | `await` | `uri, mode: LaunchMode.externalApplication,` | - |

---

### Arquivo: `lib/services/voice_service.dart`

#### Classe: `VoiceService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `init` | `Future<bool>` | `` | - |
| `_ensureAiInitialized` | `Future<void>` | `` | - |
| `processCommandWithAi` | `>` | `String text` | - |
| `_ensureAiInitialized` | `await` | `` | - |
| `_ensureAiInitialized` | `await` | `` | - |
| `stopListening` | `void` | `` | - |

---

### Arquivo: `lib/services/widget_service.dart`

#### Classe: `WidgetService`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `updateBalance` | `Future<void>` | `double balance` | `static` |
| `_updateWidget` | `await` | `` | - |
| `updateStats` | `Future<void>` | `int level, int xp` | `static` |
| `_updateWidget` | `await` | `` | - |
| `updateRadar` | `Future<void>` | `double limit, double remaining` | `static` |
| `_updateWidget` | `await` | `` | - |
| `_updateWidget` | `Future<void>` | `` | `static` |

---

## Categoria: WIDGETS

### Arquivo: `lib/widgets/ai_negotiation_card.dart`

#### Classe: `AiNegotiationCard extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `AiNegotiationCard` | `const` | `{ super.key, required this.contactName, required this.amount, required this.dueDate, required this.description, required this.type, }` | - |
| `show` | `void` | `BuildContext context, { required String contactName, required double amount, required String dueDate, required String description, required String type, }` | `static` |
| `_AiNegotiationCardState` | `>` | `` | - |

---

### Arquivo: `lib/widgets/bpo/edit_client_settings_dialog.dart`

#### Classe: `EditClientSettingsDialog extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `EditClientSettingsDialog` | `const` | `{ super.key, required this.client, required this.db, required this.onSuccess, }` | - |
| `_EditClientSettingsDialogState` | `>` | `` | - |

---

### Arquivo: `lib/widgets/bpo/link_client_dialog.dart`

#### Classe: `LinkClientDialog extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `LinkClientDialog` | `const` | `{super.key}` | - |
| `_LinkClientDialogState` | `>` | `` | - |

---

### Arquivo: `lib/widgets/bpo/send_message_to_all_clients_dialog.dart`

#### Classe: `SendMessageToAllClientsDialog extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `SendMessageToAllClientsDialog` | `const` | `{super.key}` | - |
| `_SendMessageToAllClientsDialogState` | `>` | `` | - |

---

### Arquivo: `lib/widgets/bpo/send_message_to_client_dialog.dart`

#### Classe: `SendMessageToClientDialog extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `SendMessageToClientDialog` | `const` | `{ super.key, required this.client, required this.db, }` | - |
| `_SendMessageToClientDialogState` | `>` | `` | - |

---

### Arquivo: `lib/widgets/budget_dashboard_view.dart`

#### Classe: `BudgetDashboardView extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `BudgetDashboardView` | `const` | `{super.key}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_getBudgetColor` | `Color` | `double progress, bool isOver` | - |
| `_buildEmptyState` | `Widget` | `` | - |
| `_showSetBudgetDialog` | `void` | `BuildContext context, BudgetService service, List<String> availableCategories, {double? initialAmount}` | - |

---

### Arquivo: `lib/widgets/challenges_section.dart`

#### Classe: `ChallengesSection extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `ChallengesSection` | `const` | `{super.key}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_showChallengeDialog` | `void` | `BuildContext context, {ChallengeModel? challenge}` | - |
| `_buildChallengeCard` | `Widget` | `BuildContext context, ChallengeModel c` | - |

---

### Arquivo: `lib/widgets/command_palette.dart`

#### Classe: `CommandPalette extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `CommandPalette` | `const` | `{super.key}` | - |
| `_CommandPaletteState` | `>` | `` | - |

#### Classe: `CommandAction`

*Nenhum método ou função detectado.*

---

### Arquivo: `lib/widgets/credit_card_summaries.dart`

#### Classe: `CreditCardSummaries extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `CreditCardSummaries` | `const` | `{super.key}` | - |
| `_hexToColor` | `Color` | `String hex` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_buildCardItem` | `Widget` | `String name, String status, double amount, Color color, IconData icon, NumberFormat currency` | - |

---

### Arquivo: `lib/widgets/daily_spending_radar.dart`

#### Classe: `DailySpendingRadar extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `DailySpendingRadar` | `const` | `{super.key}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `GestureDetector` | `return` | `onTap: (` | - |
| `_showExplanation` | `void` | `BuildContext context, double budget, double spent, double available, int days, double limit, double todaySpent, double todayLeft` | - |
| `_buildCalcRow` | `Widget` | `String label, String value, IconData icon, {Color? color, bool isBold = false}` | - |

---

### Arquivo: `lib/widgets/dashboard/app_bottom_nav_bar.dart`

#### Classe: `AppBottomNavBar extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `AppBottomNavBar` | `const` | `{ super.key, required this.provider, required this.currentDashboard, required this.onDashboardChanged, }` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_getDashboardIndex` | `int` | `DashboardType type, bool isBusiness` | - |
| `_getDashboardTypeFromIndex` | `DashboardType` | `int index, bool isBusiness` | - |
| `_getAvailableDashboards` | `List<DashboardType>` | `bool isBusiness` | - |
| `_getIconForType` | `IconData` | `DashboardType type` | - |
| `_getLabelForType` | `String` | `DashboardType type` | - |

---

### Arquivo: `lib/widgets/dashboard/app_sidebar.dart`

#### Classe: `AppSidebar extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `AppSidebar` | `const` | `{ super.key, required this.provider, required this.currentDashboard, required this.onDashboardChanged, required this.extended, }` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_handleLogout` | `void` | `BuildContext context` | - |
| `_buildBpoTowerItem` | `Widget` | `BuildContext context, bool extended` | - |
| `_buildPortalBiItem` | `Widget` | `bool extended` | - |
| `_buildDreSimulatorItem` | `Widget` | `BuildContext context, SubscriptionProvider subProvider, bool extended` | - |
| `_buildGoalsItem` | `Widget` | `BuildContext context, bool extended` | - |
| `_buildSimulatorItem` | `Widget` | `BuildContext context, bool extended` | - |
| `_buildKanbanItem` | `Widget` | `BuildContext context, bool extended` | - |
| `_buildSidebarIcon` | `Widget` | `IconData icon, DashboardType type, String label, bool extended` | - |
| `_buildUsageLimitsCard` | `Widget` | `BuildContext context, SubscriptionProvider subProvider` | - |
| `Color` | `const` | `0xFF2563EB` | - |

---

### Arquivo: `lib/widgets/dashboard/brazil_vector_map.dart`

#### Classe: `BrazilVectorMap extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `BrazilVectorMap` | `const` | `{super.key, required this.data}` | - |
| `_BrazilVectorMapState` | `>` | `` | - |

#### Classe: `BrazilConstellationPainter extends CustomPainter`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `paint` | `void` | `Canvas canvas, Size size` | - |
| `getPixelOffset` | `Offset` | `Offset relOffset` | - |

---

### Arquivo: `lib/widgets/dashboard/comparison_dashboard.dart`

#### Classe: `ComparisonDashboard extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `ComparisonDashboard` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |

---

### Arquivo: `lib/widgets/dashboard/daily_forecast_dashboard.dart`

#### Classe: `DailyForecastDashboard extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `DailyForecastDashboard` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |

---

### Arquivo: `lib/widgets/dashboard/dre_matrix_dashboard.dart`

#### Classe: `DREMatrixDashboard extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `DREMatrixDashboard` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_buildDRETreeView` | `Widget` | `TransactionsProvider provider` | - |
| `_buildDREMatrixTable` | `Widget` | `TransactionsProvider provider` | - |
| `_buildDREFlowCards` | `Widget` | `TransactionsProvider provider` | - |
| `_buildFlowCard` | `Widget` | `String label, String value, String percent, Color color` | - |
| `_buildWaterfallProfitChart` | `Widget` | `TransactionsProvider provider` | - |

---

### Arquivo: `lib/widgets/dashboard/geographic_dashboard.dart`

#### Classe: `GeographicDashboard extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `GeographicDashboard` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `LayoutBuilder` | `return` | `builder: (context, constraints` | - |

---

### Arquivo: `lib/widgets/dashboard/omie/app_header.dart`

#### Classe: `AppHeader extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `AppHeader` | `const` | `{ super.key, required this.onShowSyncCenter, this.onStartVoice, this.isVoiceListening = false, }` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_buildSyncButton` | `Widget` | `TransactionsProvider provider` | - |
| `_buildFilterModeTab` | `Widget` | `TransactionsProvider provider, OmieFilterMode mode, String label` | - |

#### Classe: `_ActionMenuItem extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `_ActionMenuItem` | `const` | `{required this.icon, required this.label, required this.color}` | - |
| `build` | `Widget` | `BuildContext context` | - |

---

### Arquivo: `lib/widgets/dashboard/omie/bpo_control_tower_view.dart`

#### Classe: `BpoControlTowerView extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `BpoControlTowerView` | `const` | `{ super.key, this.onManageAccount, }` | - |
| `_BpoControlTowerViewState` | `>` | `` | - |

---

### Arquivo: `lib/widgets/dashboard/omie/business_agenda.dart`

#### Classe: `BusinessAgenda extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `BusinessAgenda` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_quickWhatsAppCobranca` | `await` | `context, item, client` | - |
| `_buildAgendaTile` | `Widget` | `{ required String title, required String subtitle, required String category, required double amount, required bool isIncome }` | - |
| `_quickWhatsAppCobranca` | `Future<void>` | `BuildContext context, dynamic item, String clientName` | - |
| `launchUrl` | `await` | `uri, mode: LaunchMode.externalApplication` | - |

---

### Arquivo: `lib/widgets/dashboard/omie/omie_abc_ranking.dart`

#### Classe: `OmieABCRanking extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OmieABCRanking` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |

---

### Arquivo: `lib/widgets/dashboard/omie/omie_aging_chart.dart`

#### Classe: `OmieAgingChart extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OmieAgingChart` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |

---

### Arquivo: `lib/widgets/dashboard/omie/omie_ai_consultant_card.dart`

#### Classe: `OmieAIConsultantCard extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OmieAIConsultantCard` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |

---

### Arquivo: `lib/widgets/dashboard/omie/omie_business_dashboard.dart`

#### Classe: `OmieBusinessDashboard extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OmieBusinessDashboard` | `const` | `{ super.key, required this.provider, required this.currentDashboard, required this.onShowSyncCenter, required this.onDashboardChanged, }` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `PremiumIncomeDashboard` | `return` | `provider: provider` | - |
| `PremiumExpenseDashboard` | `return` | `provider: provider` | - |
| `DREMatrixDashboard` | `return` | `provider: provider` | - |
| `ComparisonDashboard` | `return` | `provider: provider` | - |
| `GeographicDashboard` | `return` | `provider: provider` | - |
| `OSKanbanBoard` | `return` | `provider: provider` | - |
| `DailyForecastDashboard` | `return` | `provider: provider` | - |
| `BudgetDashboardView` | `return` | `` | - |
| `PremiumSummaryDashboard` | `return` | `provider: provider, onShowSyncCenter: onShowSyncCenter,` | - |

---

### Arquivo: `lib/widgets/dashboard/omie/omie_business_widgets.dart`

#### Classe: `OmieAgingChart extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OmieAgingChart` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |

#### Classe: `OmieFlashCashBanner extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OmieFlashCashBanner` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |

#### Classe: `OmieProductivityChart extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OmieProductivityChart` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_buildProgressCircle` | `Widget` | `String label, double value, Color color` | - |

#### Classe: `OmieABCRanking extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OmieABCRanking` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |

---

### Arquivo: `lib/widgets/dashboard/omie/omie_cash_flow_heatmap.dart`

#### Classe: `OmieCashFlowHeatmap extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OmieCashFlowHeatmap` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |

---

### Arquivo: `lib/widgets/dashboard/omie/omie_crm_widget.dart`

#### Classe: `OmieCRMWidget extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OmieCRMWidget` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_showClientSearchSheet` | `void` | `BuildContext context, TransactionsProvider provider` | - |
| `StatefulBuilder` | `return` | `builder: (context, setState` | - |
| `DraggableScrollableSheet` | `return` | `initialChildSize: 0.8, minChildSize: 0.5, maxChildSize: 0.95, expand: true, builder: (context, scrollController` | - |
| `_showClientHistorySheet` | `void` | `BuildContext context, String clientId, String clientName, TransactionsProvider provider` | - |
| `DraggableScrollableSheet` | `return` | `initialChildSize: 0.9, minChildSize: 0.5, maxChildSize: 0.95, expand: true, builder: (context, scrollController` | - |
| `launchUrl` | `await` | `uri, mode: LaunchMode.externalApplication` | - |
| `_buildBusinessMetric` | `Widget` | `String label, String value, Color color` | - |

---

### Arquivo: `lib/widgets/dashboard/omie/omie_dre_block.dart`

#### Classe: `OmieDREBlock extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OmieDREBlock` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_buildDRERow` | `Widget` | `String label, String value, Color color, {bool isBold = false}` | - |

---

### Arquivo: `lib/widgets/dashboard/omie/omie_expense_donut.dart`

#### Classe: `OmieExpenseDonut extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OmieExpenseDonut` | `const` | `{ super.key, required this.provider, required this.onCategoryTap, }` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `PieChartSectionData` | `return` | `color: colors[index % colors.length], value: entry.value, title: '', radius: 20,` | - |
| `_getCategoryIcon` | `IconData` | `String name` | - |

---

### Arquivo: `lib/widgets/dashboard/omie/omie_forecasting_chart.dart`

#### Classe: `OmieForecastingChart extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OmieForecastingChart` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |

---

### Arquivo: `lib/widgets/dashboard/omie/omie_goal_banner.dart`

#### Classe: `OmieGoalBanner extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OmieGoalBanner` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_showGoalEditDialog` | `void` | `BuildContext context, TransactionsProvider provider` | - |

---

### Arquivo: `lib/widgets/dashboard/omie/omie_health_panel.dart`

#### Classe: `OmieHealthPanel extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OmieHealthPanel` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_buildHealthCard` | `Widget` | `String label, String value, IconData icon, Color color` | - |

---

### Arquivo: `lib/widgets/dashboard/omie/omie_kpis.dart`

#### Classe: `OmieKPIs extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OmieKPIs` | `const` | `{super.key, required this.provider, required this.isDesktop}` | - |
| `_buildBillingButton` | `Widget` | `BuildContext context` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_buildSyncButton` | `Widget` | `TransactionsProvider provider` | - |
| `_buildKPICard` | `Widget` | `String label, String value, Color color, IconData icon` | - |
| `_buildOmieFlashCashBanner` | `Widget` | `TransactionsProvider provider` | - |
| `_buildBusinessMetric` | `Widget` | `String label, String value, Color color` | - |

---

### Arquivo: `lib/widgets/dashboard/omie/omie_pipeline_widget.dart`

#### Classe: `OmiePipelineWidget extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OmiePipelineWidget` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_buildPipelineRow` | `Widget` | `BuildContext context, String label, int count, Color color, IconData icon, [VoidCallback? onTap]` | - |

---

### Arquivo: `lib/widgets/dashboard/omie/omie_productivity_chart.dart`

#### Classe: `OmieProductivityChart extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OmieProductivityChart` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_buildProgressCircle` | `Widget` | `String label, double value, Color color` | - |

---

### Arquivo: `lib/widgets/dashboard/omie/omie_project_widget.dart`

#### Classe: `OmieProjectWidget extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OmieProjectWidget` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |

---

### Arquivo: `lib/widgets/dashboard/omie/omie_shared_components.dart`

#### Classe: `RankingCard extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `RankingCard` | `const` | `{ super.key, required this.title, required this.data, required this.color, }` | - |
| `build` | `Widget` | `BuildContext context` | - |

#### Classe: `ExtratoTable extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `ExtratoTable` | `const` | `{ super.key, required this.title, required this.items, required this.color, }` | - |
| `build` | `Widget` | `BuildContext context` | - |

---

### Arquivo: `lib/widgets/dashboard/omie/omie_team_performance.dart`

#### Classe: `OmieTeamPerformance extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OmieTeamPerformance` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |

---

### Arquivo: `lib/widgets/dashboard/omie/omie_yearly_comparison_chart.dart`

#### Classe: `OmieYearlyComparisonChart extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OmieYearlyComparisonChart` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_buildLegendItem` | `Widget` | `String label, Color color` | - |

---

### Arquivo: `lib/widgets/dashboard/os_kanban_board.dart`

#### Classe: `OSKanbanBoard extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `OSKanbanBoard` | `const` | `{ super.key, required this.provider, }` | - |
| `_OSKanbanBoardState` | `>` | `` | - |

---

### Arquivo: `lib/widgets/dashboard/personal_dashboard.dart`

#### Classe: `PersonalDashboard extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `PersonalDashboard` | `const` | `{ super.key, required this.provider, required this.currentDashboard, required this.buildCoachBanner, required this.buildRecurrenceSuggestions, required this.buildBalanceCard, required this.buildProactiveInsights, required this.buildActivityFeed, }` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `BudgetDashboardView` | `return` | `` | - |
| `MySubscriptionsScreen` | `const` | `` | - |
| `InstallmentsProjectionView` | `return` | `` | - |
| `CreditCardsScreen` | `const` | `` | - |
| `WalletsScreen` | `const` | `` | - |
| `Column` | `return` | `children: msgs.map((m` | - |
| `_buildUserHeader` | `Widget` | `BuildContext context, TransactionsProvider provider` | - |
| `_buildRunwayCard` | `Widget` | `BuildContext context` | - |
| `_showPayBpoFeeBottomSheet` | `void` | `BuildContext context, Map<String, dynamic> feeData` | - |
| `SizedBox` | `Pagamento` | `width: double.infinity, child: ElevatedButton.icon( onPressed: (` | - |
| `_showClientDreBottomSheet` | `void` | `BuildContext context` | - |
| `_legendDot` | `Widget` | `Color color, String label` | - |
| `_dreRow` | `Widget` | `String label, double val, NumberFormat currency, {bool isPrimary = false, bool isBold = false, bool isEbitda = false}` | - |
| `Color` | `const` | `0xFF10B981` | - |
| `Color` | `const` | `0xFFEF4444` | - |
| `Color` | `const` | `0xFFEF4444` | - |

---

### Arquivo: `lib/widgets/dashboard/premium_bi_header.dart`

#### Classe: `PremiumBIHeader extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `PremiumBIHeader` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_buildMetric` | `Widget` | `String label, String value, Color color` | - |

---

### Arquivo: `lib/widgets/dashboard/premium_card.dart`

#### Classe: `PremiumCard extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `PremiumCard` | `const` | `{ super.key, required this.title, required this.value, required this.icon, required this.color, }` | - |
| `build` | `Widget` | `BuildContext context` | - |

---

### Arquivo: `lib/widgets/dashboard/premium_expense_dashboard.dart`

#### Classe: `PremiumExpenseDashboard extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `PremiumExpenseDashboard` | `const` | `{ super.key, required this.provider, }` | - |
| `build` | `Widget` | `BuildContext context` | - |

---

### Arquivo: `lib/widgets/dashboard/premium_income_dashboard.dart`

#### Classe: `PremiumIncomeDashboard extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `PremiumIncomeDashboard` | `const` | `{ super.key, required this.provider, }` | - |
| `build` | `Widget` | `BuildContext context` | - |

---

### Arquivo: `lib/widgets/dashboard/premium_summary_dashboard.dart`

#### Classe: `PremiumSummaryDashboard extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `PremiumSummaryDashboard` | `const` | `{ super.key, required this.provider, required this.onShowSyncCenter, }` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `LayoutBuilder` | `return` | `builder: (context, constraints` | - |
| `Column` | `return` | `children: msgs.map((m` | - |
| `_showPayBpoFeeBottomSheet` | `void` | `BuildContext context, Map<String, dynamic> feeData` | - |
| `SizedBox` | `Pagamento` | `width: double.infinity, child: ElevatedButton.icon( onPressed: (` | - |
| `_showClientDreBottomSheet` | `void` | `BuildContext context` | - |
| `_legendDot` | `Widget` | `Color color, String label` | - |
| `_dreRow` | `Widget` | `String label, double val, NumberFormat currency, {bool isPrimary = false, bool isBold = false, bool isEbitda = false}` | - |
| `Color` | `const` | `0xFF10B981` | - |
| `Color` | `const` | `0xFFEF4444` | - |
| `Color` | `const` | `0xFFEF4444` | - |

---

### Arquivo: `lib/widgets/dre_tree_view.dart`

#### Classe: `DreTreeView extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `DreTreeView` | `const` | `{super.key, required this.nodes, this.isSmall = false}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_buildNode` | `Widget` | `DreNode node` | - |

---

### Arquivo: `lib/widgets/dynamic_background.dart`

#### Classe: `DynamicBackground extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `DynamicBackground` | `const` | `{super.key, required this.child}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `Container` | `return` | `color: Colors.white, child: child,` | - |

---

### Arquivo: `lib/widgets/financial_health_bar.dart`

#### Classe: `FinancialHealthBar extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `FinancialHealthBar` | `const` | `{super.key, this.onTap}` | - |
| `build` | `Widget` | `BuildContext context` | - |

---

### Arquivo: `lib/widgets/installments_projection_view.dart`

#### Classe: `InstallmentsProjectionView extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `InstallmentsProjectionView` | `const` | `{super.key}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `StatefulBuilder` | `return` | `builder: (context, setState` | - |
| `_buildFutureTransactionTile` | `Widget` | `dynamic t, NumberFormat currency` | - |
| `_generateRealProjection` | `List<double>` | `TransactionsProvider provider, {String? cardId}` | - |
| `_generateCategorySummary` | `List<Widget>` | `TransactionsProvider provider, NumberFormat currency, {String? cardId}` | - |

---

### Arquivo: `lib/widgets/premium_period_selector.dart`

#### Classe: `PremiumPeriodSelector extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `PremiumPeriodSelector` | `const` | `{super.key, required this.provider}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_buildMonthlySelect` | `Widget` | `BuildContext context` | - |
| `_buildYearlySelect` | `Widget` | `BuildContext context` | - |
| `_buildMenuItem` | `Widget` | `String text, bool isSelected` | - |
| `_buildCustomSelector` | `Widget` | `BuildContext context` | - |
| `GestureDetector` | `return` | `onTap: (` | - |

---

### Arquivo: `lib/widgets/radial_menu.dart`

#### Classe: `RadialMenu extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `RadialMenu` | `const` | `{super.key, required this.onActionSelected}` | - |
| `_RadialMenuState` | `>` | `` | - |

---

### Arquivo: `lib/widgets/report_settings_section.dart`

#### Classe: `ReportConfigModel`

*Nenhum método ou função detectado.*

#### Classe: `ReportSettingsSection extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `ReportSettingsSection` | `const` | `{super.key}` | - |
| `_ReportSettingsSectionState` | `>` | `` | - |

---

### Arquivo: `lib/widgets/spending_donut_chart.dart`

#### Classe: `SpendingDonutChart extends StatefulWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `SpendingDonutChart` | `const` | `{super.key}` | - |
| `_SpendingDonutChartState` | `>` | `` | - |

---

### Arquivo: `lib/widgets/spending_limits_card.dart`

#### Classe: `SpendingLimitsCard extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `SpendingLimitsCard` | `const` | `{super.key}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_buildLimitItem` | `Widget` | `String name, double current, double max, Color color` | - |

---

### Arquivo: `lib/widgets/sync_center_dialog.dart`

#### Classe: `SyncCenterDialog extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `SyncCenterDialog` | `const` | `{super.key}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `_getStatusColor` | `Color` | `String status` | - |

---

### Arquivo: `lib/widgets/user_header.dart`

#### Classe: `UserHeader extends StatelessWidget`

| Método / Getter / Setter | Tipo de Retorno | Parâmetros | Modificadores |
| :--- | :--- | :--- | :--- |
| `UserHeader` | `const` | `{super.key, required this.userName, required this.avatarLetter}` | - |
| `build` | `Widget` | `BuildContext context` | - |
| `InkWell` | `return` | `onTap: (` | - |

---
