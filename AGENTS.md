# Regras de trabalho — GerePag

## Contexto obrigatório

Antes de alterar o projeto, leia `PROJECT.md` e `CHECKPOINT_GEREPAG.md`. Consulte `gerepague_mapa_funcoes.md` como inventário, mas confirme o comportamento no código-fonte.

## Fluxo Git

- `main` é a fonte de verdade e não deve receber commits diretos.
- Trabalhe em branch curta com prefixo `codex/`, `feature/`, `fix/` ou `chore/`.
- Entregue mudanças por pull request e mantenha cada PR focado.
- Preserve alterações locais que não pertençam à tarefa.

## Segurança

- Não versionar tokens, chaves secretas, senhas, keystores, arquivos OAuth baixados ou exports de dados.
- Não reproduzir valores sensíveis em logs, documentos, commits ou respostas.
- Stripe e decisões de plano/preço pertencem ao backend autenticado.
- Credenciais Omie e de IA no cliente são risco conhecido; não ampliar essa superfície.
- Mudanças em autenticação, papéis, billing e isolamento Firebase exigem testes específicos.

## Qualidade

- Preserve a regra de negócio existente salvo requisito explícito.
- Evite aumentar as responsabilidades do `TransactionsProvider` e das telas monolíticas.
- Adicione ou atualize testes para cálculos financeiros, serialização, limites de plano e widgets afetados.
- Execute análise, testes e ao menos um build da plataforma alterada antes de concluir.
- Não afirme que uma validação passou sem registrar a execução real.

## Release

- Nunca use assinatura debug em release.
- Não gere nova upload key para um aplicativo já publicado sem verificar a chave original/Play Console.
- Não altere application ID ou bundle ID sem plano de migração aprovado pelos proprietários.
