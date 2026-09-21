# Segurança

## Como relatar

Não abra issue pública com chaves, dados pessoais ou detalhes exploráveis. Avise diretamente os proprietários do repositório e inclua somente o necessário para reproduzir o problema de forma segura.

## Segredos

- Segredos de servidor nunca devem estar no aplicativo Flutter.
- Keystores e `android/key.properties` devem permanecer fora do Git.
- Chaves expostas devem ser revogadas e substituídas; apagar o arquivo atual não limpa o histórico.
- Logs e artefatos não devem conter dados financeiros, tokens ou respostas sensíveis de integrações.

## Incidente conhecido

O histórico do repositório já conteve credencial Stripe, chaves de IA, arquivo OAuth e export de dados Firebase. Trate esses valores como comprometidos. A resposta mínima é: revogar/rotacionar, revisar uso e faturamento, avaliar impacto de privacidade/LGPD, fazer backup seguro e só então planejar a limpeza coordenada do histórico.

## Limites de confiança

- O backend deve validar identidade, papéis, plano, preço, moeda e resultado de pagamento.
- Regras Realtime Database/Firestore devem garantir isolamento por usuário/família.
- Funções administrativas, BPO e contador não podem depender apenas de bloqueios visuais no cliente.
- Webhooks de pagamento precisam de validação de assinatura e idempotência.
