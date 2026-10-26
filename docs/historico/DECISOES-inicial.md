# Registro de decisões

> Registro histórico da organização inicial. As decisões vigentes estão em [../DECISOES.md](../DECISOES.md).

Este arquivo distingue requisitos já confirmados, propostas e perguntas abertas. A fonte das confirmações iniciais é [RPG_contexto_para_Codex.md](../../RPG_contexto_para_Codex.md); a data de organização deste registro não representa uma nova aprovação.

## Estados

- **Confirmada:** aprovada explicitamente pelo usuário ou identificada como confirmada no contexto original.
- **Proposta:** apresentada para discussão, sem aprovação.
- **Em aberto:** há uma pergunta ou definição pendente, sem resposta escolhida.
- **Substituída:** uma decisão posterior alterou a anterior; manter a referência entre elas.

## Requisitos confirmados herdados do contexto

| ID | Requisito |
| --- | --- |
| R01 | RPG digital original de fantasia medieval, com magia, raças e classes. |
| R02 | Inspiração na experiência de Breath of Fire I e Chrono Trigger, preservando histórias, personagens e sistemas originais. |
| R03 | Combate por turnos, com detalhes ainda abertos. |
| R04 | Protagonista humano; jogador escolhe nome e gênero, homem ou mulher; sem criação livre de personagem. |
| R05 | Companheiros fixos recrutados gradualmente pela história. |
| R06 | Até quatro integrantes ativos; somente os ativos participam das batalhas. |
| R07 | Equipe em fila durante a exploração, com o líder à frente. |
| R08 | Trocar o líder muda o sprite controlado e visível à frente; essa troca deve ser possível entre os ativos durante a exploração. |
| R09 | Habilidades especiais de exploração exigem que o personagem esteja ativo e seja o líder. |
| R10 | Trocas entre ativos e reservas somente no local especial de reunião, cuja identidade permanece aberta. |
| R11 | Companheiros devem transformar a exploração e abrir possibilidades de acesso no cenário. |
| R12 | Buscar personagens marcantes, com objetivos, agência e identidade além do combate. |
| R13 | Planejar obstáculos essenciais e opcionais evitando bloqueios frustrantes decorrentes das limitações de troca. |

## Propostas apresentadas nesta organização

| ID | Proposta | Estado | Detalhamento |
| --- | --- | --- | --- |
| P01 | Dividir responsabilidades entre personagens, equipe, exploração, combate, narrativa, fluxo e apresentação; prever persistência caso adotada. | Proposta | [Arquitetura, seções 1–3](../ARQUITETURA.md) |
| P02 | Centralizar as regras de composição e liderança em um sistema consultado pelos demais. | Proposta | [Arquitetura, seções 3 e 6](../ARQUITETURA.md) |
| P03 | Separar conceitualmente definições de conteúdo do estado da partida. | Proposta | [Arquitetura, seção 4](../ARQUITETURA.md) |
| P04 | Resolver plataforma e escopo antes da engine e da estrutura de código. | Proposta | [Arquitetura, seções 8 e 9](../ARQUITETURA.md) |

Nenhuma decisão técnica nova foi registrada como confirmada.

## Perguntas e ideias ainda abertas

- O protagonista precisa ocupar uma vaga ativa ou pode ficar na reserva?
- Quais são as plataformas-alvo, a dimensão gráfica, o escopo inicial, a engine e a linguagem?
- Como serão ritmo, ações, ordem dos turnos e progressão no combate?
- Haverá técnicas combinadas, interações entre habilidades ou estados de batalha? Como funcionarão?
- Quais serão as classes, raças e habilidades de cada companheiro? Guerreiro, ladino, mago, bárbaro, humano, elfo, anão e talvez orc são possibilidades mencionadas, não escolhas finais.
- Haverá habilidades passivas de exploração sem liderança? A possibilidade discutida não foi aprovada e não altera R09.
- Como serão formação da fila, seguimento e comportamento com menos de quatro integrantes? Reproduzir o caminho do líder com atraso continua sendo apenas uma sugestão.
- Como funcionarão identidade, mapa, acesso e narrativa do local de reunião?
- Qual será a história, o mundo, o elenco e o estilo de arte?

Perguntas adicionais levantadas pela proposta de arquitetura, também sem decisão:

- Como tratar uma solicitação de troca que retire o líder da equipe?
- Quais restrições de troca de liderança existirão durante interações ou transições?
- Haverá salvamento e, se houver, como funcionará?

## Histórico de organização

- **23/10/2026:** contexto lido e preservado; criada uma proposta documental de arquitetura e este registro. Nenhum código, escolha de engine ou aprovação de proposta foi acrescentado.

## Formato para futuras decisões

Ao confirmar uma nova decisão, registrar: identificador, data, decisão, origem da aprovação do usuário, motivo quando conhecido, impacto nos sistemas e decisão anterior substituída, se houver.

Uma sugestão do assistente ou uma necessidade de implementação não conta como aprovação do usuário.
