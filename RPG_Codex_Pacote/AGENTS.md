# Instruções permanentes para o Codex — projeto RPG digital

## Papel

Trabalhe como parceiro de implementação e arquitetura de um RPG digital de fantasia medieval. O usuário é o diretor criativo e valida as decisões de design. Não converta sugestões em requisitos definitivos.

## Fontes do projeto

Antes de propor ou alterar sistemas, leia:
- `docs/GDD.md` — regras de jogo e comportamento esperado.
- `docs/DECISOES.md` — status das decisões.
- `docs/PENDENCIAS.md` — escolhas não resolvidas e ideias adiadas.

Ao receber novas decisões do usuário, atualize os documentos afetados junto com o código relevante. Em caso de conflito, explique o conflito e solicite uma decisão antes de implementar comportamento incompatível.

## Regras de trabalho

1. **Não comece a programar um jogo inteiro por conta própria.** Primeiro examine o repositório. Se for novo, proponha uma estrutura mínima e peça uma decisão sobre engine/linguagem, plataforma-alvo e escopo do primeiro protótipo.
2. Distinga sempre: **confirmado**, **recomendação**, **exemplo**, **pendente** e **futuro/fora de escopo**.
3. Priorize separação entre dados e lógica: personagens, inimigos, perfis de seleção de alvos, encontros, presets de batalha e trajetórias devem ser preferencialmente configuráveis em dados.
4. Prefira código determinístico/testável para presets de encontro. Para sorteios ponderados de comportamento, use uma fonte de aleatoriedade controlável por semente durante testes.
5. Evite complexidade extra: sem agentes de IA, aprendizado de máquina, redes, geração procedural, simuladores de física ou sistemas de combate tático por grade, salvo decisão posterior expressa.
6. Não inclua mecânicas de versões futuras como requisito da primeira versão (técnicas conjuntas, arcos finais de companheiros, equipe sem protagonista etc.).
7. Para cada sistema implementado, produza testes úteis e descreva como executar/verificar. Não afirme que testes passaram se não foram executados.
8. Quando surgir uma lacuna essencial, apresente opções curtas com consequências. Não assuma números definitivos de atributos, custos de MP, fórmulas, duração, coordenadas ou porcentagens.
9. Preserve a distinção entre **posição lógica da batalha**, **posição visual durante animação** e **progresso em trajetória**.
10. Use assets originais/provisórios licenciados; não copie sprites, mapas, músicas ou conteúdo de jogos de referência.

## Invariantes aprovados

- Equipe ativa: até 4 integrantes; são os mesmos que combatem e aparecem na exploração.
- Protagonista humano, nome e gênero escolhidos, obrigatório na equipe durante a história principal nesta primeira versão.
- Companheiros fixos recrutados pela história; reservas só são trocadas no local especial de reunião.
- Exploração em fila; troca de líder de exploração **somente pelo menu**, persistente até nova escolha; troca o sprite da frente. Para executar habilidade de cenário, personagem deve estar ativo e ser líder da exploração.
- Protagonista permanece foco narrativo das cenas principais, mesmo que outro personagem lidere o mapa.
- Sem encontros aleatórios. Mapa-múndi não tem inimigos comuns; áreas exploráveis/masmorras têm inimigos visíveis, alguns móveis, alguns parados; batalhas narrativas podem ser obrigatórias.
- Primeira versão: combate em **tela separada**, com cenário coerente com a dungeon e **preset determinístico por encontro**. Um reencontro com o mesmo encontro reproduz cenário e posições iniciais.
- Aliados têm posições lógicas fixas por batalha, definidas pelo preset. Podem orientar-se visualmente para inimigos e deslocar sprites durante animações, mas devem voltar à mesma posição lógica/idle. Nenhuma ação ou efeito do cenário muda a posição lógica dos aliados.
- Inimigos móveis seguem rotas definidas pelo preset enquanto ATB enche, sem movimentação aleatória. Movimentos podem ser estáticos, terrestres curtos ou mais amplos (ex.: voadores). Ações pausam a rota, preservam segmento e progresso exatos, permitem animação e retornam ao ponto para retomada.
- ATB individual, velocidade derivada da INI efetiva. INI base fixa por personagem, **não cresce com nível**; equipamentos/acessórios e efeitos temporários podem alterá-la. Barra para em 100%; sem múltiplas ações acumuladas; jogador escolhe entre aliados prontos. ATB de inimigos oculto.
- Configuração Wait/Active alterável no menu. Wait pausa progressão temporal e movimento durante seleção de comandos; Active mantém progressão e movimento durante a seleção. Detalhes finos ainda carecem de desenho.
- Comandos: Atacar, Habilidades, Itens e Fugir. **Não há comando Defender** na primeira versão.
- HP e MP persistem entre batalhas. Habilidades mágicas **e físicas especiais** consomem MP; ataques básicos não. Com 0 HP, personagem fica incapacitado e continua assim após a vitória até ser revivido/recuperado.
- Fugir: ação individual que tenta retirar o grupo inteiro; falha consome ação do personagem. Certas batalhas impedem fuga. Probabilidade ainda indefinida.
- Equipe toda em 0 HP: Game Over tradicional, recarregar salvamento. Salvar só em pousadas e pontos específicos de progresso, eventualmente antes de chefes, não obrigatoriamente.
- IA de inimigos **programática baseada em regras/pesos**, sem agentes de IA. Preferências de alvo não são escolhas absolutas. Perfis candidatos em `docs/GDD.md`; pesos/fórmulas não definidos.

## Escopo excluído agora

- Grupo ativo sem protagonista, desbloqueado apenas perto do fim narrativo; missões pessoais opcionais dos companheiros, recompensas especiais e técnicas combinadas em dupla/grupo são ideias para depois, não parte da primeira entrega.
- Não inventar classes, raças, inimigos definitivos, história, balanceamento ou regras de progressão não discutidas.
