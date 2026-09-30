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

Requisitos: Node.js 22 ou mais recente e pnpm (a versão está fixada em `packageManager`; `corepack enable` resolve).

```bash
pnpm install
pnpm dev              # app em http://localhost:3000
pnpm storybook        # Storybook em http://localhost:6006
```

| Script                 | O que faz                            |
| ---------------------- | ------------------------------------ |
| `pnpm lint`            | ESLint                               |
| `pnpm typecheck`       | Gera os tipos de rota e roda o `tsc` |
| `pnpm format`          | Formata com Prettier                 |
| `pnpm format:check`    | Confere a formatação sem alterar     |
| `pnpm build`           | Build de produção do Next.js         |
| `pnpm build-storybook` | Build estático do Storybook          |

Estrutura de `src/`:

- `app/` — rotas (App Router)
- `features/<modulo>/` — domínio por módulo: queries, actions, schemas e componentes próprios
- `components/` — componentes compartilhados; `components/ui/` são os do shadcn/ui
- `lib/` — utilitários e clientes compartilhados

## Contribuindo

Contribuições externas ainda não estão abertas. Quando estiverem, o processo (incluindo o CLA) será descrito em `CONTRIBUTING.md`. Até lá, bugs e sugestões são bem-vindos como issues.

## Licença

[Functional Source License 1.1, ALv2 Future License](LICENSE.md) (`FSL-1.1-ALv2`). Cada versão passa a valer também sob a Apache 2.0 dois anos após a publicação.
