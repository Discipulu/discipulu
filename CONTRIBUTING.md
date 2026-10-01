# Contribuindo com o Discipulu

Obrigado pelo interesse! O Discipulu é mantido por Micah Gomes e licenciado sob a [FSL-1.1-ALv2](LICENSE.md).

## Antes de começar

- **Abra uma issue antes de escrever código.** Assim combinamos o escopo e a abordagem, e ninguém perde tempo com um PR que não vai entrar. Correções de digitação e ajustes pequenos de documentação podem ir direto para PR.
- **Vulnerabilidades não vão em issue pública.** Veja o [SECURITY.md](SECURITY.md).
- Siga o [Código de Conduta](CODE_OF_CONDUCT.md).

## CLA

Todo autor de PR precisa aceitar o [Contrato de Licença de Contribuidor](CLA.md) uma vez. Você continua dono do que escreveu: o CLA só concede ao projeto as licenças necessárias para distribuir a contribuição, inclusive sob outras licenças. No primeiro PR, o bot do CLA comenta pedindo o aceite: basta responder com a frase que ele indicar. Sem o aceite, o PR não pode ser mergeado.

## Fluxo

1. Faça um fork e crie uma branch a partir de `dev`: `feat/<assunto>`, `fix/<assunto>`, `docs/<assunto>`.
2. Abra o PR contra a `dev`. A `main` só recebe merge da `dev`.
3. O CI precisa passar: formatação, lint, typecheck, testes unitários, testes de banco, build e build do Storybook.

Para rodar o projeto localmente, veja o [README](README.md#desenvolvimento).

## Convenções

### Commits

[Conventional Commits](https://www.conventionalcommits.org/pt-br/): `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`, `build:`, `ci:`, com escopo opcional (`fix(auth): …`). Mensagem curta, no imperativo, em inglês.

### Código

- **Código em inglês** (nomes, mensagens de commit, rotas); textos da interface em português.
- **Comentários só quando evitam um bug ou são indispensáveis**: o porquê de uma policy de RLS, uma armadilha de fuso horário, o contorno de um problema de biblioteca. Nada de comentário que repete o código, cabeçalho de arquivo ou `TODO` solto.
- Datas em ISO 8601.
- Antes de abrir o PR: `pnpm format`, `pnpm lint`, `pnpm typecheck`, `pnpm test`.

### Banco de dados

- Migrations só pelo Supabase CLI (`supabase migration new <descricao>`), em `supabase/migrations/`. Migration publicada não é editada: a correção vem numa migration nova.
- **Toda tabela de tenant tem `igreja_id`, RLS ligado e um teste de isolamento** em `tests/db/` (pgTAP, `pnpm test:db`) provando que uma igreja não enxerga dados de outra.
- Nada de chave `secret`/`service_role` em variável `NEXT_PUBLIC_*` ou em código que roda no navegador.

### Dados pessoais

- **Nunca use dados pessoais reais** em seed, teste, fixture, issue ou print. Use massa fictícia com domínios reservados (`@exemplo.test`).
- O sistema trata dados de menores e de filiação religiosa. Qualquer funcionalidade que colete, exiba ou exporte dados pessoais deve explicar no PR quem pode ver esses dados e por quê.

### Interface

- Tailwind + [shadcn/ui](https://ui.shadcn.com). Componente reutilizável novo vem com story no Storybook (`*.stories.tsx` ao lado do componente).
- Depois de `shadcn add`, rode `pnpm format`.

### Portabilidade

O Discipulu precisa rodar fora da Vercel (self-host com Docker). Não use recurso exclusivo de um provedor sem alternativa; recursos do serviço em nuvem ficam atrás de `EDITION=cloud`.
