# Discipulu

Gestão de Escola Bíblica Dominical para igrejas e congregações: turmas, alunos, professores, chamada pelo celular, relatórios dominicais e caderneta.

Disponível como serviço em [discipulu.com.br](https://discipulu.com.br) ou para instalação própria (self-host).

> **Status:** em desenvolvimento inicial. Ainda não há versão utilizável.

## Stack

- [Next.js](https://nextjs.org) (App Router) + TypeScript
- [Supabase](https://supabase.com) — Postgres, Auth, Row Level Security e Storage
- Tailwind CSS + [shadcn/ui](https://ui.shadcn.com), com componentes documentados no Storybook
- pnpm

## Desenvolvimento

Requisitos: Node.js 22 ou mais recente, pnpm (a versão está fixada em `packageManager`; `corepack enable` resolve), Docker e o [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started).

```bash
pnpm install
supabase start        # Postgres, Auth e Mailpit locais; aplica as migrations
cp .env.example .env.local
pnpm dev              # app em http://localhost:3000
pnpm storybook        # Storybook em http://localhost:6006
```

Preencha o `.env.local` com a `Project URL` e a chave `Publishable` que o `supabase status` mostra. Os e-mails de confirmação de cadastro chegam no Mailpit (http://127.0.0.1:54324). `supabase db reset` recria o banco local a partir de `supabase/migrations/` e `supabase/seed.sql`; `supabase stop` desliga a stack e mantém os dados.

| Script                 | O que faz                            |
| ---------------------- | ------------------------------------ |
| `pnpm lint`            | ESLint                               |
| `pnpm typecheck`       | Gera os tipos de rota e roda o `tsc` |
| `pnpm test`            | Testes unitários (Vitest)            |
| `pnpm test:db`         | Testes de banco e RLS (pgTAP)        |
| `pnpm db:types`        | Regera os tipos do banco local       |
| `pnpm format`          | Formata com Prettier                 |
| `pnpm format:check`    | Confere a formatação sem alterar     |
| `pnpm build`           | Build de produção do Next.js         |
| `pnpm build-storybook` | Build estático do Storybook          |

### Dados de desenvolvimento

O `supabase/seed.sql` cria massa fictícia no banco local (`supabase start` na primeira vez, ou `supabase db reset`): duas igrejas (Igreja Exemplo A, com Sede e Congregação Vila Nova; Igreja Exemplo B, só Sede), 65 pessoas, 8 turmas, professores e matrículas. Todos os usuários entram com a senha **`discipulu-dev`**, que só existe no ambiente local:

| E-mail                    | Papel                                                       |
| ------------------------- | ----------------------------------------------------------- |
| `dono@exemplo.test`       | `owner` da Igreja A                                         |
| `admin@exemplo.test`      | `admin` da Igreja A e `owner` da Igreja B (troca de igreja) |
| `secretaria@exemplo.test` | `secretary` da Igreja A, só na Congregação Vila Nova        |
| `professor@exemplo.test`  | `teacher` da Igreja A, com duas turmas (lê o roster)        |
| `leitor@exemplo.test`     | `viewer` da Igreja A, auxiliar de uma turma (sem roster)    |

Depois de mudar uma migration, rode `pnpm db:types` com o banco local no ar e faça commit do `src/lib/supabase/database.types.ts`: o CI regera os tipos e falha se o arquivo estiver desatualizado.

Estrutura de `src/`:

- `app/` — rotas (App Router)
- `features/<modulo>/` — domínio por módulo: queries, actions, schemas e componentes próprios
- `components/` — componentes compartilhados; `components/ui/` são os do shadcn/ui
- `lib/` — utilitários e clientes compartilhados; `lib/supabase/` tem os clientes de browser, servidor e proxy de sessão e os tipos gerados do banco; `lib/auth/` lê a igreja ativa, troca de igreja e consulta capacidades no servidor
- `proxy.ts` — renova a sessão a cada requisição e protege `/app`

Testes ficam em `tests/`: `unit/` (Vitest) e `db/` (pgTAP, rodados pelo `supabase test db` contra o banco local — precisa do `supabase start` ou `supabase db start`).

## Rodando em Docker

O app não depende da Vercel: a imagem roda `next start` em qualquer host com Docker.

```bash
docker build -t discipulu \
  --build-arg NEXT_PUBLIC_SUPABASE_URL=... \
  --build-arg NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=... .
docker run -p 3000:3000 \
  -e NEXT_PUBLIC_SUPABASE_URL=... \
  -e NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=... discipulu
```

As variáveis `NEXT_PUBLIC_*` entram no build (vão para o JavaScript do navegador) e também em tempo de execução (servidor). A URL do Supabase precisa ser alcançável de dentro do container: com o Supabase local, use `http://host.docker.internal:54321`. O endereço público do app precisa estar nos redirects do Auth do Supabase (`additional_redirect_urls`).

## Contribuindo

Leia o [CONTRIBUTING.md](CONTRIBUTING.md) antes de abrir um PR: abra uma issue primeiro e aceite o [CLA](CLA.md) no primeiro PR. Vulnerabilidades vão pelo reporte privado descrito no [SECURITY.md](SECURITY.md). O projeto segue o [Código de Conduta](CODE_OF_CONDUCT.md).

## Licença

[Functional Source License 1.1, ALv2 Future License](LICENSE.md) (`FSL-1.1-ALv2`). Cada versão passa a valer também sob a Apache 2.0 dois anos após a publicação.
