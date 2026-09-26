# Regras de colaboração — GerePag

Estas regras valem para Claude Code, Codex e qualquer outra ferramenta ou pessoa que altere o repositório.

## Sincronização obrigatória

- `origin/main` é a fonte de verdade para todo código e documentação versionados.
- Toda alteração versionada deve passar por branch curta, pull request e merge normal na `main`; não fazer commits diretos na `main`.
- Após cada merge, sincronizar a cópia local principal com `git pull --ff-only origin main` antes de continuar o desenvolvimento local.
- Antes de iniciar qualquer alteração, fazer `git fetch origin`, confirmar a branch e preservar alterações locais não relacionadas.
- Ao finalizar, confirmar que a cópia local principal e `origin/main` apontam para o mesmo commit. O projeto local e o remoto devem permanecer iguais quanto a arquivos versionados.

## Única exceção permitida

Arquivos locais ignorados pelo Git podem diferir, exclusivamente por conterem segredos ou configuração do ambiente, por exemplo:

- `android/key.properties`;
- upload keystores (`.jks`/`.keystore`);
- `.env` e credenciais OAuth baixadas;
- exports privados, certificados e arquivos temporários de build.

Nunca versionar, enviar, copiar para issues/PRs ou exibir em logs senhas, chaves, tokens, keystores, certificados privados ou exports de dados.

## Commits e validação

- Criar **um commit por arquivo alterado**. Um merge commit de pull request pode agrupar esses commits, mas não substituir os commits individuais.
- Rodar as validações proporcionais à alteração antes de abrir a PR. Para mudanças Android, executar ao menos testes e build debug; para release, validar também a assinatura sem expor segredos.
