# Longevus

Aplicação front-end para gestão de rotina e cuidado familiar do idoso.

## Visão geral

Este projeto foi estruturado como a base de interface do painel administrativo de cuidador/família. O objetivo é manter a camada visual pronta para integração com backend real, sem dados artificiais nem registros fictícios.

A autenticação, banco de dados, APIs e persistência real não fazem parte desta etapa. O foco é preparar a arquitetura do frontend para receber dados externos em uma próxima implementação.

## Stack

- Vite
- JavaScript vanilla
- HTML5
- CSS3

## Estrutura

```bash
longevus/
├── index.html
├── package.json
├── .env.example
├── .gitignore
├── README.md
├── src/
│   ├── data/
│   │   ├── backend-contract.js
│   │   ├── emptyState.js
│   │   └── readme.md
│   ├── main.js
│   ├── styles.css
│   └── mockData.js
└── public/
```

## Instalação

```bash
npm install
```

## Execução

```bash
npm run dev
```

A aplicação ficará disponível no endereço padrão do Vite, normalmente:

```bash
http://localhost:5173
```

## Variáveis de ambiente

Crie um arquivo `.env` com base no `.env.example`:

```bash
cp .env.example .env
```

Essas variáveis são para uso do front-end e integração futura com ambientes de deploy ou APIs.

## Observação

Este repositório foi montado com a camada visual e a arquitetura do projeto, em estado pronto para receber dados reais do backend. Não há dados fictícios de paciente, terapia, família ou equipe neste código.
