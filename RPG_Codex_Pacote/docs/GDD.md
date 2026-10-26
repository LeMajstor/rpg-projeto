# Game Design Document (GDD) — RPG digital

**Versão:** 0.1 (documento de concepção)  
**Data:** 23/10/2026  
**Status:** consolidação de requisitos; sem engine, linguagem, plataformas, orçamento ou escopo de protótipo aprovados.

## 1. Visão e pilares

RPG digital de fantasia medieval, magia, raças e classes, inspirado na sensação de aventura de *Breath of Fire I* e *Chrono Trigger*; não será cópia das obras. A história existe como premissa inicial, mas seu conteúdo ainda será refinado.

**Pilares de experiência:**
1. Companheiros **fazem diferença na exploração**, abrindo caminhos a partir de capacidades próprias.
2. Elenco fixo recrutado ao longo da história, com motivações e importância narrativa próprias.
3. Batalhas por ATB com decisões significativas, posicionamento de inimigos e habilidades com alvos/áreas.
4. Gestão clássica de recursos (HP/MP), salvamentos limitados e encontros desenhados intencionalmente.
5. Mecânicas simples inicialmente, com espaço para expansão futura.

## 2. Mundo, elenco e progressão do grupo

### 2.1 Ambientação
- Fantasia medieval com magia e classes.
- Classes **mencionadas como possibilidades**, não confirmadas: guerreiro, ladino, mago e bárbaro.
- Raças **mencionadas como possibilidades**, não elenco definido: humano, elfo, anão e talvez orc.
- História, nomes, mundo, facções, mapa, arte e tamanho do elenco **não definidos**.

### 2.2 Protagonista
- Humano, com escolha de nome e gênero (homem ou mulher); sem criação livre de personagem.
- É o **líder narrativo** durante a história principal: cenas e diálogos importantes devem dar-lhe destaque, mesmo se outro estiver à frente no mapa.
- **Obrigatório na equipe ativa** durante a história principal na primeira versão.

### 2.3 Companheiros e equipe
- Companheiros são personagens fixos, recrutados gradualmente conforme a história.
- Equipe ativa tem **até quatro** membros; estes são os quatro que participam das batalhas.
- Os mesmos integrantes aparecem em fila na exploração: líder de exploração à frente; os demais atrás.
- Personagens fora da equipe ativa permanecem na reserva e **somente podem substituir ativos num local especial de reunião**, ainda sem identidade narrativa, aparência ou nome aprovado. A referência conceitual é o Fim dos Tempos de Chrono Trigger, sem copiá-lo.
- O protagonista pode futuramente deixar de ser obrigatório em um segmento final da história; **fora do escopo da primeira versão**.

## 3. Exploração e habilidades de cenário

- O jogador controla diretamente o **líder de exploração**, representado por seu próprio sprite à frente da fila.
- Os outros três sprites seguem atrás. Detalhes de algoritmo de seguimento ainda não definidos; registrar como implementação aberta.
- Troca de líder **apenas pelo menu**, não por botão rápido. Depois de escolhido, ele permanece à frente até outra troca.
- Para usar uma capacidade única que afeta o cenário, seu personagem precisa (a) estar entre os quatro ativos e (b) ser líder de exploração.
- Exemplo inspirador: Bo de *Breath of Fire I* consegue atravessar determinadas florestas. Não copiar literalmente esse personagem.
- Habilidades podem abrir caminhos, segredos e obstáculos; concretizações por classe/personagem ainda não aprovadas.
- Diferenciar ao projetar mapas o uso de habilidades para progresso obrigatório e para exploração opcional, de modo a reduzir retorno frustrante ao ponto de troca de equipe.

## 4. Estrutura de encontros

- **Não haverá encontros aleatórios** no mapa-múndi nem nas dungeons.
- Mapa-múndi: sem inimigos comuns, salvo conflitos iniciados por eventos narrativos.
- Dungeons e áreas exploráveis como florestas/cavernas: inimigos visíveis no cenário; podem estar imóveis ou se movimentar.
- O jogador em geral pode evitá-los, mas alguns podem bloquear passagens e confrontos narrativos podem ser obrigatórios.
- A transição leva a uma **tela de batalha separada** na primeira versão. Combate diretamente no mapa é desejo futuro, não compromisso atual.

### 4.1 Cenários e presets por encontro

- Cada dungeon tem identidade ambiental. Deseja-se **aproximadamente 3 a 4 variações visuais** de cenário de batalha por dungeon, idealmente coerentes com suas subáreas. Esse número é uma meta aproximada, não obrigação universal.
- Cada encontro no mapa aponta para um **preset específico**, que determina cenário e posições iniciais de aliados e inimigos, além da composição inimiga.
- **Determinismo:** ao retornar e repetir o mesmo encontro, o cenário e a formação inicial são os mesmos. Não sortear um preset novo nesse caso.
- Um preset pode ser reutilizado em múltiplos encontros. Nenhuma distribuição aleatória de posições iniciais é necessária.
- As posições dos quatro aliados **podem variar entre diferentes presets**, mas ficam fixas durante **aquela batalha**.
- Preset também pode incluir trajetórias dos inimigos e outros dados próprios do encontro.

**Exemplo de modelo de dados (proposta técnica, não contrato de engine):**

```yaml
encounter_id: dungeon_a_enemy_group_b
battle_preset_id: dungeon_a_corridor_02
battle_scene: dungeon_a_corridor
allied_slots: # coordenadas de idle próprias deste encontro
  - {slot: 1, x: 10, y: 30}
  - {slot: 2, x: 15, y: 45}
  - {slot: 3, x: 9, y: 60}
  - {slot: 4, x: 18, y: 75}
enemies:
  - {enemy_type: wolf, spawn: [75, 35], movement_path_id: wolf_short_patrol}
  - {enemy_type: wolf, spawn: [82, 58], movement_path_id: wolf_short_patrol_2}
```

As coordenadas e nomes acima são **fictícios**, incluídos apenas para ilustrar a associação encontro→preset.

## 5. Campo de batalha, movimento e animação

### 5.1 Personagens jogáveis

- Cada aliado tem uma **posição lógica de repouso (idle) fixa** durante aquela batalha, definida pelo preset.
- Nenhum inimigo, ataque ou cenário pode alterar as coordenadas lógicas x/y de um aliado.
- O sprite pode deslocar-se **visualmente durante uma animação** (por exemplo, ataque corpo a corpo), mas deve retornar à posição original ao final.
- Sprites aliados podem **girar/virar** para acompanhar o inimigo mais próximo; isso não altera sua coordenada lógica.
- Não haverá movimentação livre dos personagens do jogador durante o combate nesta versão.

### 5.2 Inimigos

- Alguns imóveis, outros móveis conforme o tipo e o preset. Chefes podem ficar estáticos.
- Enquanto a barra ATB enche, um inimigo móvel pode seguir continuamente uma **rota programada em loop no preset**.
- **Não usar deslocamento aleatório de navegação**: não queremos inimigos terrestres circulando desordenadamente entre os aliados.
- Exemplos de padrões possíveis: terrestre com percurso curto/coerente, voador com arcos ou círculos maiores, estático com idle e animações.
- Quando o inimigo vai executar ação, a progressão na rota é pausada e guardada exatamente — segmento, fator interpolado/posição e demais dados necessários. A animação pode deslocar o sprite temporariamente. Depois, o sprite volta ao ponto e retoma a rota de onde parou.
- Essa regra vale tanto para ataque em alvo único quanto em múltiplos alvos.

### 5.3 Separação técnica desejada

Separar:
1. `logical_position` — posição usada em distância/área e estado de combate;
2. `visual_offset` / posição de animação — transformação temporária do sprite;
3. `route_state` — caminho, segmento atual, progresso no segmento e sentido;
4. `facing` — direção visual do sprite.

Para personagens aliados, o valor lógico de posição é fixo enquanto a batalha durar; para inimigos, pode evoluir ao longo da rota e congela durante suas animações de ação.

## 6. ATB e Iniciativa (INI)

- Cada combatente (aliado e inimigo) tem barra ATB e atributo **INI**.
- A **INI base do personagem é fixa**: não sobe a cada nível.
- **INI efetiva** pode variar com equipamentos/acessórios e buffs/debuffs temporários.
- A velocidade de preenchimento depende da INI efetiva. Fórmula, escala e limites **não definidos**.
- Ao atingir 100%, a barra **para**: nenhuma segunda carga ou ação é acumulada.
- Quando há mais de um aliado pronto, o jogador pode escolher **qual utilizar primeiro**; aliado pronto pode aguardar.
- Após executar uma ação, o ATB volta a zero e retoma novo ciclo. A definição fina de quando a ação passa a ser considerada executada ainda poderá ser refinada na implementação.
- Inimigos seguem ATB, mas suas barras ficam **ocultas** para o jogador.
- INI não define automaticamente probabilidade de fuga.

### 6.1 Modos de tempo

- **Wait/Espera:** pausa progressão do combate e movimentação dos inimigos **durante a seleção de comandos** quando um personagem está pronto. Fora da seleção, o combate avança normalmente.
- **Active/Ativo:** progressão de ATB e movimento dos inimigos continua enquanto o jogador seleciona comandos.
- Jogador pode configurar o modo no início e alterá-lo mais tarde pelo menu. São estilos de combate; não há decisão de chamá-los formalmente de Fácil/Difícil.
- Pontos finos — como resolver comandos simultâneos e o momento de congelar/descongelar áreas visadas — permanecem pendentes.

## 7. Comandos e recursos

### 7.1 Comandos básicos (confirmados)

| Comando | Efeito |
|---|---|
| **Atacar** | Ataque básico com arma; sem custo de MP. |
| **Habilidades** | Magias e técnicas especiais, físicas ou mágicas; **consomem MP**. |
| **Itens** | Uso de itens do inventário; não consomem MP por padrão. |
| **Fugir** | Tentativa de escapar com **todo o grupo** usando a ação de um aliado pronto. |

**Defender NÃO é um comando da primeira versão.** Habilidades defensivas específicas podem existir futuramente.

### 7.2 Fuga

- Um aliado pronto escolhe Fugir, valendo para toda a equipe.
- Sucesso: termina o combate com a equipe escapando.
- Falha: consome aquela ação, ATB do personagem volta a zero, combate continua.
- Algumas lutas narrativas/chefes podem bloquear fuga.
- Cálculo de chance, mensagens, regras de experiência/loot e estados associados ainda não definidos.

### 7.3 HP / MP

- HP e MP clássicos; permanecem entre batalhas (sem recuperação automática por vitória).
- Técnicas especiais físicas **também gastam MP**, não apenas magias.
- Itens, magias e repouso em locais apropriados poderão restaurar recursos. Valores e economia pendentes.
- Ao chegar a 0 HP, personagem fica incapacitado, não age e sua barra deixa de avançar.
- Ao vencer, continua incapacitado até recuperação por item, magia apropriada ou descanso. Não volta automaticamente com 1 HP.

## 8. Tipos de alvo e área (direção funcional)

Habilidades podem afetar:
- **Um alvo** (aliado ou inimigo, conforme efeito);
- **Área localizada** (ex.: circular);
- **Linha/faixa**, se vier a ser adotada;
- **Todos** os alvos de um lado (ou outra regra de alvo de cada habilidade).

O posicionamento atual dos **inimigos móveis** importa na seleção das áreas de efeito. Interface exata de mira, geometrias e se há movimento durante confirmação no modo Active não estão fechadas. **Habilidades conjuntas/duplas/de grupo ficam para o futuro.**

## 9. IA programática — personalidade dos inimigos

### 9.1 Abordagem aprovada

- Implementar **sem LLM, sem agente de IA e sem ML**. Usar regras programáticas, estados simples e **seleção aleatória ponderada** (*weighted random selection*).
- Perfil do inimigo determina **preferências**, não escolhas absolutas. Inimigos podem escolher outros alvos válidos.
- IA de decisão (ações/alvos) é independente do sistema de movimento e do preset.
- Não é preciso decidir alvos a cada frame: a seleção pode ocorrer quando o inimigo está pronto para executar uma ação.
- Evitar mudanças de personalidade ou reações de fase durante a batalha na primeira versão. Mudanças reativas complexas foram consideradas interessantes para o futuro.
- Todos os alvos incapazes/inelegíveis devem ser excluídos do sorteio e o algoritmo precisa de fallback seguro.

### 9.2 Perfis propostos para uso inicial

Os nomes e comportamentos abaixo foram discutidos como **conjunto-base proposto**, com concordância explícita com a arquitetura probabilística, mas **sem pesos definitivos** ou decisão de quais tipos de inimigos os usarão:

| Perfil | Prioridade ponderada de alvo |
|---|---|
| **Instintivo** | Probabilidade uniforme entre alvos válidos. |
| **Predador** | Prefere alvos com menor porcentagem de HP. |
| **Implacável** | Favorece um alvo escolhido antes; pode trocar conforme probabilidade e validade. |
| **Retaliador** | Favorece quem lhe causou dano mais recentemente. |
| **Caçador de Magos** | Favorece alvos de maior MP máximo. |
| **Tático** | Pode ponderar alvos conforme habilidade/efeito escolhido; é mais complexo e pode ser adiado. |

Os exemplos (slime, lobo, soldado etc.) são **ilustrativos**, não bestiário ou classes definitivas.

### 9.3 Exemplo de seleção ponderada (pseudocódigo)

```text
quando_inimigo_esta_pronto:
    acao = escolher_acao_valida(inimigo, contexto_da_batalha)
    alvos = alvos_validos(acao, contexto_da_batalha)
    se alvos vazios: tratar_com_segurança_sem_travar
    para cada alvo:
        peso[alvo] = peso_base_positivo * modificador_de_perfil(inimigo, acao, alvo)
    alvo = sorteio_ponderado(alvos, peso, gerador_aleatorio_injetavel)
    executar_acao(inimigo, acao, alvo)
```

- Perfis não devem depender de LLM e não requerem custo de rede.
- A escolha do alvo e da ação são distintas. Para habilidades de área, a escolha pode ser de centro/ponto/região em vez de uma unidade, exigindo regra específica ainda a desenhar.
- Percentuais exatos, fórmulas, seleção de ações e tratamento de ameaças ainda estão pendentes.

## 10. Derrota e salvamento

- Game Over tradicional se **todos os integrantes ativos** ficarem com 0 HP; jogador carrega salvamento anterior.
- Não há retorno automático a pousada ou outro local após derrota.
- **Salvamento somente em locais específicos**: pousadas e pontos especiais em trechos relevantes da história, frequentemente perto de chefes, mas não necessariamente antes de cada um.
- Descanso em pousadas/pontos apropriados pode recuperar HP e MP; custos/regras precisas ainda não definidos.

## 11. Evoluções FUTURAS — não incluir no escopo inicial

- Em um momento avançado/final da história, protagonista poderá deixar de ser obrigatório no grupo ativo.
- Conteúdo de final de jogo com **missão pessoal opcional para cada companheiro**, ativada somente se o personagem estiver na equipe ativa; encerra seu arco e dá recompensa mecânica (poder, item) e/ou narrativa.
- Técnicas/magias de dupla e grupo, exigindo dois ou mais aliados prontos.
- Combate diretamente no cenário da dungeon em vez de tela separada.
- Possíveis reações avançadas de IA (medo, fuga, fúria, desespero etc.) conforme a batalha evolui.

## 12. Regras para especificar novos sistemas

Para cada funcionalidade nova, registrar:
- Objetivo na experiência do jogador;
- Regras confirmadas versus hipóteses;
- Dados necessários e interfaces entre sistemas;
- Casos de teste e situações de borda;
- Custo de implementação/risco de escopo.

**Não assumir:** fórmula de INI/ATB, tempo de barras, classes/raças definitivas, mapa, motor, ordem de ações simultâneas, quantidade de inimigos por encontro, números de HP/MP, coeficientes de probabilidades, colisões de animação ou custo de qualquer habilidade.
