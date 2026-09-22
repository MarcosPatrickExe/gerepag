# GerePag

Copiloto financeiro pessoal e empresarial em Flutter, com dashboards, integração Omie, OCR, IA, cobrança e relatórios para autônomos, PMEs, BPOs/contadores e negócios digitais.

## Plataformas

- Android e iOS para publicação nas lojas.
- Web pelo toolchain oficial do Flutter.

## Desenvolvimento

Requisitos validados: Flutter 3.41.8 ou compatível com Dart `^3.9.0` e Java 17.

```bash
flutter pub get --enforce-lockfile
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build web --debug --no-pub
flutter build apk --debug --no-pub
```

## Documentação

- [PROJECT.md](PROJECT.md): produto, arquitetura, integrações, estado técnico e release.
- [CHECKPOINT_GEREPAG.md](CHECKPOINT_GEREPAG.md): riscos e roadmap priorizado.
- [AGENTS.md](AGENTS.md): regras para colaboradores e agentes de IA.
- [SECURITY.md](SECURITY.md): política de segredos e resposta a incidentes.

## Atenção antes de publicar

O app GerePag existente no Play Console usa `com.marcos.gurgel.gerepag`, enquanto o código Android atual ainda usa `com.real.finance.control`; a migração coordenada para o identificador do Play Console é obrigatória antes do próximo AAB. O bundle ID iOS atual é `com.antigravity.appfinancerio`. Builds release Android exigem uma upload keystore externa ao repositório, uma redefinição de chave de upload ativa no Play Console e o backend de billing configurado por `GEREPAG_BILLING_API_BASE_URL`.
