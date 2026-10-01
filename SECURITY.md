# Política de segurança

O Discipulu guarda dados de igrejas, incluindo dados de menores e informação de filiação religiosa, que é dado pessoal sensível pela LGPD. Levamos a sério qualquer falha que possa expor esses dados.

## Versões com suporte

O projeto está em desenvolvimento inicial e ainda não tem versão estável. As correções de segurança entram na branch `main` e no serviço em [discipulu.com.br](https://discipulu.com.br).

## Como reportar uma vulnerabilidade

**Não abra issue pública.** Use o reporte privado do GitHub:

1. Abra [Report a vulnerability](https://github.com/Discipulu/discipulu/security/advisories/new) (aba **Security** do repositório).
2. Descreva o problema, como reproduzir, o impacto que você enxerga e, se tiver, uma sugestão de correção.

O que esperar:

- confirmação de recebimento em poucos dias úteis;
- avaliação e um plano de correção, com atualização ao longo do processo;
- crédito no aviso de segurança, se você quiser, quando a correção for publicada.

Pedimos que você não divulgue a falha antes de a correção estar disponível.

## Escopo

Entram no escopo, entre outros:

- vazamento de dados entre igrejas ou congregações (falha de isolamento multi-tenant ou de Row Level Security);
- acesso sem autenticação ou elevação de privilégio;
- exposição de segredos ou de dados pessoais.

Durante a investigação:

- use só contas e dados de teste seus;
- não acesse, altere nem apague dados de terceiros no serviço em produção;
- não faça teste de negação de serviço nem engenharia social.
