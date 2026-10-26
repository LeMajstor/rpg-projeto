# RPG Digital — Documento de Contexto para o Codex

## Objetivo
Desenvolver um RPG digital original inspirado na sensação de aventura dos RPGs de SNES, especialmente **Breath of Fire I** e **Chrono Trigger**, sem copiar suas histórias, personagens ou sistemas.

## Decisões confirmadas
- Gênero: RPG digital de fantasia medieval, com magia, raças e classes.
- Referências principais: Breath of Fire **I** (não II) e Chrono Trigger.
- Combate: por turnos; detalhes do ritmo e das ações ainda não definidos.
- Protagonista: humano; jogador escolhe nome e gênero (homem ou mulher). Não há criação livre de personagem.
- Elenco: companheiros fixos, recrutados gradualmente pela história.
- Equipe ativa: **até quatro integrantes**.
- Apenas os quatro integrantes ativos participam das batalhas.
- Durante a exploração, os quatro integrantes aparecem no mapa **em fila**.
- O **líder** aparece na frente, com os outros três seguindo atrás.
- Trocar o líder troca também o sprite controlado/visível à frente da fila.
- Habilidades especiais de exploração exigem que o personagem esteja **na equipe ativa e seja o líder**.
- Personagens reservas podem ser trocados com membros ativos **somente em um local especial de reunião**, conceitualmente comparável ao Fim dos Tempos de Chrono Trigger. Nome, aparência e justificativa desse local ainda não foram definidos.
- Ponto de admiração central de Breath of Fire I: habilidades únicas de companheiros abrem caminhos no cenário, como Bo atravessando florestas.
- Meta narrativa: criar personagens marcantes com objetivos e agência, não apenas adversários feitos para serem derrotados.

## Ideias mencionadas, mas NÃO decididas
- Classes possíveis: guerreiro, ladino, mago, bárbaro.
- Raças possíveis: humano, elfo, anão e talvez orc.
- Classes, raças e poderes individuais definitivos de cada companheiro.
- Sistema de combate detalhado, ordem dos turnos e progressão.
- Técnicas combinadas, interações entre habilidades e estados de batalha.
- Habilidades passivas de exploração sem liderança: foram discutidas como possibilidade, mas não aprovadas.
- Formação exata da fila e algoritmo de seguimento. Reprodução atrasada do caminho do líder foi sugerida, não decidida.
- Identidade, mapa e funcionamento do local de reunião.
- História, mundo, personagens, estilo de arte, motor de jogo e plataformas-alvo.
- Obrigatoriedade de manter o protagonista na equipe ativa: **pergunta ainda em aberto**.

## Princípios de design
1. **Personagens transformam a exploração.** Novos companheiros mudam o que o jogador pode alcançar e descobrir.
2. **Identidade além do combate.** Buscar papéis de exploração e narrativa para os personagens, sem presumir que cada detalhe já está definido.
3. **Composição do grupo importa.** Trocar integrantes requer retornar ao local especial; trocar o líder entre os quatro ativos deve ser possível durante a exploração.
4. **Evitar bloqueios frustrantes.** Planejar obstáculos essenciais e opcionais levando em conta as limitações de troca da equipe.
5. **Inspiração, não reprodução.** As referências clássicas informam objetivos de experiência; as implementações e histórias devem ser originais.

## Orientações ao Codex
- Este é um projeto em **fase de concepção**, ainda sem engine, linguagem ou repositório especificados.
- **Não invente decisões como se estivessem aprovadas**; distinga fatos confirmados, sugestões e perguntas abertas.
- Antes de implementar sistemas substanciais, alinhe engine/plataforma/escopo com o usuário.
- Se solicitado a começar um protótipo, priorize um vertical slice mínimo: mapa explorável, quatro sprites em fila, troca de líder e obstáculo interativo que exige habilidade do líder.
- Registre novas decisões em arquivo próprio para manter o ChatGPT e o Codex sincronizados.

## Próxima questão de design em aberto
O protagonista precisa obrigatoriamente ocupar uma das quatro vagas da equipe ativa ou pode ficar na reserva?
