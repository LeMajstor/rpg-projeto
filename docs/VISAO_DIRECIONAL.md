# Visão frontal e periférica na exploração

**D159 — autorizado e implementado em 15/11/2026 para testar.** O usuário solicitou aprimorar a percepção e autorizou visão frontal e periférica orientadas pelo olhar, recortadas pelas paredes. Substitui os círculos de percepção D158; representação dos 18 participantes, seis encontros, layouts e parâmetros de movimento continuam os mesmos.

## Funcionamento confirmado

Todos os monstros do mapa usam dois campos simultâneos: frontal longo e periférico curto. Ambos respeitam a orientação e a visão livre até o **líder atual**. Seguidores não são detectados nem iniciam encontros. Cada representante percebe individualmente, sem alerta coletivo.

| Campo | Alcance do teste | Abertura total | Função |
| --- | ---: | ---: | --- |
| Frontal |180 unidades |90° |Percepção adiante do olhar |
| Periférico |60 unidades |180° |Laterais próximas, sem visão para trás |

**Escolhas técnicas experimentais, configuráveis**, preservando os alcances anteriores para avaliar a mudança de formato. Não são números definitivos de balanceamento. O periférico é um semicírculo à frente: cobre até 90° para cada lado do olhar. Aproximação pelas costas não gera percepção, mesmo dentro do antigo raio 60.

**Contato físico continua valendo em qualquer direção**, inclusive por trás dos estáticos. Mantém o alcance de contato 24 do protótipo, derivado da dimensão lógica dos corpos. A forma circular dessa colisão física permanece independente do campo de visão; não é uma área de percepção.

Nos móveis, olhar inicial segue o primeiro trecho válido da rota e depois acompanha o deslocamento real, inclusive perseguição/retorno. Quando param, conservam a última direção. Tentativa de movimento bloqueada não vira o olhar; o monstro não gira automaticamente para um líder que ainda não enxerga. Estáticos mantêm a orientação nos dados. Rotação gradual/varredura de cabeça e perfis específicos de visão por espécie continuam futuros.

Móveis detectam o líder dentro da união dos campos e do território fixo da rota, com linha de visão livre. Perder o campo, a linha de visão ou o território encerra a perseguição e inicia retomada pelo trecho acessível próximo. Durante a perseguição, o deslocamento naturalmente orienta o monstro para onde está seguindo. Não há memória da posição escondida, busca geral de caminho ou intervalo de tolerância novo.

**Estáticos não se movem:** entrar em qualquer campo visível ou tocar o corpo inicia imediatamente a mesma batalha completa do encontro. A verificação varre o caminho do líder para não pular áreas, inclusive ao sair da sombra de uma parede. Vitória/fuga bem-sucedida remove os três representantes do grupo; M2 continua impedindo fuga na batalha. Recursos e estados por piso permanecem.

## Visualização e teste jogável

Abra a exploração, entre na dungeon pelo mundo e use **F3**:

- **Dourado:** visão frontal.
- **Azul:** visão periférica.
- **Verde:** território fixo da rota, separado da percepção.

Os contornos dourados/azuis são recortados nas paredes e portas, formando áreas irregulares conforme o cenário. Setas nos monstros indicam o olhar mesmo sem F3. Os arcos verdes do território continuam representando distâncias da rota; não significam que o inimigo enxerga em todas as direções.

Para avaliar: aproxime-se por trás de um estático sem tocá-lo; contorne até sua lateral próxima para ativar a periférica. Observe um móvel mudar o olhar numa curva e mantê-lo quando para. Use uma quina para quebrar visão. Teste abrir/fechar a porta e compare o recorte. A luta continua sendo o grupo inteiro, independente de qual representante a iniciou.

## Dados, custo e separação de responsabilidades

`data/exploration_enemy_behaviors.json.vision` centraliza os quatro parâmetros; o roster injeta cópias nos perfis de todos os participantes, sem copiar fichas ou alterar dados de combate. `AreaCatalog` rejeita valores não positivos/não finitos, periférico mais longo que frontal, aberturas invertidas ou visão acima de 180° que retiraria a regra das costas livres.

`encounter_perception.gd` testa ângulos/distâncias e a linha de visão exata do modelo. `look_direction` pertence ao estado local do móvel; estáticos usam `vision_direction`. Colisão, posição lógica, apresentação/pairar e progressão da rota continuam separados. Menu/diálogo/transição/batalha e pisos inativos conservam todo esse estado.

`vision_geometry.gd` produz apenas os contornos de F3: amostras no arco e raios junto às quinas dos sólidos próximos. A detecção não depende da aproximação visual do arco. O desenho reaproveita contornos enquanto posição, olhar, geometria e configuração não mudam; portas invalidam pelo contador de geometria e trocar área/sessão limpa o cache. Sem F3, esses polígonos não são calculados. Monstros fora da câmera continuam ativos e as paredes fora da câmera continuam descartadas antes de reconstruir o desenho, preservando a correção de desempenho anterior.

Compatibilidade circular existe somente para fixtures históricas sem configuração `vision`. O catálogo jogável tem configuração direcional para os 18 participantes. Nenhuma regra de dano/ATB/aflições, ficha ou laboratório foi duplicada ou alterada por esta mudança exclusiva da exploração.

## Validação executada

**76 suítes headless, 353.355 verificações, zero falhas.** `directional_vision_tests.gd`: 165 verificações, incluindo casos frontais/laterais/traseiros nos quatro perfis, contato por trás, varredura lateral, direção/pausa/movimento bloqueado, perda de perseguição, paredes retas/inclinadas, portas/cache e dados inválidos. Uma auditoria adicional nessa suíte compara milhares de posições com os contornos de F3, preservando RNG/estado. `individual_enemies_tests.gd` foi atualizada às regras novas:289 verificações; antigas expectativas de círculo traseiro foram substituídas por aproximação furtiva até o contato.

Cena principal: 29 verificações headless / 39 gráficas, com dez capturas dos dois pisos e aproximação traseira real sem iniciar combate. `render_performance.gd`: 91 verificações gráficas, incluindo 19 comparações exatas de pixels com vista sem descarte, janelas diferentes, F3 e topo alto de parede na borda.

Medição local com monstros em movimento no piso2: custo mediano do desenho 0,784–0,834 ms sem F3 e 1,153–1,202 ms com F3, Godot 4.7.2/Compatibility/Apple M3 Pro. São medições locais da CPU, não garantia universal de FPS. Relatório, executor, logs, métricas e capturas em `artifacts/directional-vision-2026-11-15/`.

```sh
godot --headless --path . --script res://tests/directional_vision_tests.gd
godot --headless --path . --script res://tests/individual_enemies_tests.gd
godot --path . --rendering-method gl_compatibility --script res://tests/render_performance.gd
python3 artifacts/directional-vision-2026-11-15/run_regressions.py
```

**Avaliar jogando:** abertura, alcance, legibilidade e naturalidade do olhar. **Futuro:** varredura/rotação de cabeça, diferentes visões por espécie, encontros obrigatórios próprios e fuga por diferença de nível. Sem progressão, ruído/audição, furtividade por atributo ou novo sistema de navegação.
