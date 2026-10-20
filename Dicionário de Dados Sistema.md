# Dicionário de Dados — Sistema de Gestão de Cuidados

## 1. Tabela `longevo`

Armazena os dados cadastrais das pessoas idosas acompanhadas pelo sistema.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id_longevo` | `bigint` | Sim (PK) | Identificador único, gerado automaticamente. |
| `criada_em` | `timestamp with time zone` | Sim | Data e hora de criação do cadastro. Padrão: `now()`. |
| `nome_completo` | `character varying` | Sim | Nome completo. Padrão: string vazia. |
| `idade` | `smallint` | Não | Idade em anos. |
| `cpf` | `character varying` | Sim | CPF da pessoa idosa. |

## 2. Tabela `cuidador`

Armazena os dados cadastrais e de contato dos cuidadores.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id_cuidador` | `bigint` | Sim (PK) | Identificador único, gerado automaticamente. |
| `criada_em` | `timestamp with time zone` | Sim | Data e hora de criação. Padrão: `now()`. |
| `nome_completo` | `character varying` | Sim | Nome completo. Padrão: string vazia. |
| `abreviatura` | `character varying` | Sim | Abreviatura do cuidador. Padrão: string vazia. |
| `cpf` | `character varying` | Sim | CPF. Padrão: string vazia. |
| `email` | `character varying` | Sim | E-mail. Padrão: string vazia. |
| `senha` | `character varying` | Sim | Credencial de acesso; deve ser armazenada com hash seguro. |
| `telefone` | `character varying` | Sim | Telefone de contato. Padrão: string vazia. |

## 3. Tabela `longevo_cuidador`

Relaciona pessoas idosas e cuidadores.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id_longevo_cuidador` | `bigint` | Sim (PK) | Identificador único do vínculo. |
| `id_longevo` | `bigint` | Sim (FK) | Referencia `longevo.id_longevo`. |
| `id_cuidador` | `bigint` | Sim (FK) | Referencia `cuidador.id_cuidador`. |
| `admin` | `boolean` | Sim | Indica perfil administrativo. Padrão: `false`. |
| `apelido_longevo` | `character varying` | Sim | Apelido da pessoa idosa no vínculo. Padrão: string vazia. |
| `relacionamento` | `character varying` | Sim | Relação entre cuidador e pessoa idosa. Padrão: string vazia. |

## 4. Tabela `prescricao`

Registra medicamentos associados a uma pessoa idosa e informações de uso.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id_prescricao` | `bigint` | Sim (PK) | Identificador único da prescrição. |
| `id_longevo` | `bigint` | Sim (FK) | Referencia `longevo.id_longevo`. |
| `id_medicamento` | `bigint` | Sim (FK) | Referencia `medicamento.id_medicamento`. |
| `id_categoria_medicamento_ocasional` | `bigint` | Não (FK) | Referencia `categoria_remedio_ocasional.id_categoria_medicamento_ocasional`. |
| `continuo` | `boolean` | Sim | Indica uso contínuo. Padrão: `false`. |
| `inicio_uso_continuo` | `timestamp without time zone` | Não | Início do uso contínuo. |
| `fim_uso_continuo` | `timestamp without time zone` | Não | Fim do uso contínuo. |
| `frequencia` | `smallint` | Sim | Frequência de uso conforme as regras da aplicação. Padrão: `0`. |
| `ultimo_uso_continuo` | `timestamp without time zone` | Não | Data e hora do último uso registrado. |

## 5. Tabela `administracao_prescricao`

Registra a confirmação da administração ou não administração de medicamentos.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id_administracao_prescricao` | `bigint` | Sim (PK) | Identificador único do registro. |
| `id_prescricao` | `bigint` | Sim (FK) | Referencia `prescricao.id_prescricao`. |
| `id_cuidador` | `bigint` | Sim (FK) | Referencia `cuidador.id_cuidador`. |
| `administrado` | `boolean` | Sim | `true` se administrado; `false` caso contrário. |
| `horario_confirmacao` | `timestamp without time zone` | Sim | Data e hora da confirmação. Padrão: `now()`. |

## 6. Tabela `medicamento`

Mantém o catálogo de medicamentos.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id_medicamento` | `bigint` | Sim (PK) | Identificador único do medicamento. |
| `nome` | `character varying` | Sim | Nome do medicamento. Padrão: string vazia. |
| `foto_url` | `character varying` | Não | URL da imagem do medicamento. |
| `bula` | `character varying` | Não | Bula ou referência para acesso à bula. |
| `descricao` | `text` | Não | Descrição complementar. |

## 7. Tabela `categoria_remedio_ocasional`

Armazena categorias de medicamentos de uso ocasional.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id_categoria_medicamento_ocasional` | `bigint` | Sim (PK) | Identificador único da categoria. |
| `nome` | `character varying` | Sim | Nome da categoria. Padrão: string vazia. |

## 8. Tabela `agenda_cuidado`

Define horários de cuidado associados ao vínculo entre pessoa idosa e cuidador.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id_agenda_cuidado` | `bigint` | Sim (PK) | Identificador único da agenda. |
| `dia_semana` | `smallint` | Não | Número que representa o dia da semana; convenção não especificada. |
| `horario_inicio` | `time without time zone` | Não | Horário de início do cuidado. |
| `horaio_fim` | `time without time zone` | Não | Horário de término do cuidado; nome mantido conforme o SQL original. |
| `id_longevo_cuidador` | `bigint` | Não (FK) | Referencia `longevo_cuidador.id_longevo_cuidador`. |

## 9. Tabela `activity_log`

Registra atividades relacionadas ao acompanhamento da pessoa idosa.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id_activity_log` | `bigint` | Sim (PK) | Identificador único do registro. |
| `created_at` | `timestamp with time zone` | Sim | Data e hora de criação. Padrão: `now()`. |
| `id_longevo` | `bigint` | Sim (FK) | Referencia `longevo.id_longevo`. |
| `id_cuidador` | `bigint` | Sim (FK) | Referencia `cuidador.id_cuidador`. |
| `activity` | `text` | Sim | Descrição textual da atividade. Padrão: string vazia. |

## 10. Resumo dos relacionamentos

| Origem | Campo FK | Destino |
|---|---|---|
| `longevo_cuidador` | `id_longevo` | `longevo.id_longevo` |
| `longevo_cuidador` | `id_cuidador` | `cuidador.id_cuidador` |
| `prescricao` | `id_longevo` | `longevo.id_longevo` |
| `prescricao` | `id_medicamento` | `medicamento.id_medicamento` |
| `prescricao` | `id_categoria_medicamento_ocasional` | `categoria_remedio_ocasional.id_categoria_medicamento_ocasional` |
| `administracao_prescricao` | `id_prescricao` | `prescricao.id_prescricao` |
| `administracao_prescricao` | `id_cuidador` | `cuidador.id_cuidador` |
| `agenda_cuidado` | `id_longevo_cuidador` | `longevo_cuidador.id_longevo_cuidador` |
| `activity_log` | `id_longevo` | `longevo.id_longevo` |
| `activity_log` | `id_cuidador` | `cuidador.id_cuidador` |

## 11. Recomendações técnicas

1. Avaliar restrições de unicidade e validação de formato para CPF e e-mail.
2. Definir limites válidos para idade, frequência e dia da semana.
3. Documentar a semântica dos campos `frequencia`, `continuo` e `id_categoria_medicamento_ocasional`.
4. Armazenar senhas com hash seguro e restringir o acesso a dados pessoais.
5. Padronizar o tratamento de datas e horários com e sem fuso horário.
6. Avaliar a correção de `horaio_fim` para `horario_fim`, considerando as dependências existentes.
7. Definir se o campo `bula` armazenará o conteúdo da bula ou apenas uma URL.

## 12. Convenções

- **PK:** chave primária.
- **FK:** chave estrangeira.
- **NOT NULL:** campo obrigatório.
- **DEFAULT:** valor padrão.
- **IDENTITY:** geração automática de identificadores.
- **NULL permitido:** campo que pode não ter valor informado.

**Nota:** as descrições funcionais foram inferidas a partir do SQL fornecido. Regras de negócio não expressas no esquema devem ser confirmadas com a aplicação.
