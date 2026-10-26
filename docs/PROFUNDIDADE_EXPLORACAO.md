# Profundidade e oclusão na exploração

## Comportamento confirmado

O cenário deve ter profundidade visual: personagens atrás de árvores, casas, paredes e outras estruturas podem ficar encobertos; ao passar pela frente, aparecem sobre elas. Cada integrante da fila é considerado individualmente, assim como NPCs, monstros e objetos locais.

A base física no chão e o desenho elevado são separados. Folhagem e telhado não viram automaticamente volumes sólidos. Colisão, câmera e animação visual continuam sendo responsabilidades distintas. Nenhum sistema de combate foi alterado.

## Executar e verificar

Abra `Executar exploracao.command` ou execute o projeto no Godot (F5).

- Contorne uma árvore pelo norte: o tronco/copa podem encobrir integrantes. Passe pelo sul: o grupo aparece na frente.
- Faça uma curva junto da árvore para que alguns integrantes ainda estejam atrás e outros já à frente. Cada um deve ser desenhado na profundidade correta.
- Passe atrás e depois à frente da casa, das pedras e das paredes. Observe as partes elevadas e a oclusão, mantendo a colisão com a base.
- Entre na casa/dungeon e teste NPCs, monstros, baú, alavanca e porta. Atores/objetos compartilham profundidade com o cenário. Porta aberta é apenas uma marca no chão.
- Use F3: vermelho mostra a colisão real; azul marca a base usada para ordenação. Esses contornos de depuração ficam deliberadamente sobre o desenho. A copa não corresponde ao retângulo sólido.

A câmera continua seguindo o líder, na escala da casa. WASD/setas, E, liderança pelo menu, pausas, viagens e persistência mantêm os controles existentes. As formas continuam provisórias; não há arte definitiva ou transparência automática de estruturas.

## Dados e escolhas técnicas provisórias

| Campo | Responsabilidade |
| --- | --- |
| `rect` | Base sólida no chão, usada pelo modelo para colisão e visibilidade de interação. |
| `visual_height` | Elevação do desenho em relação ao chão. Não aumenta o volume físico. |
| `canopy_width` | Largura visual da copa, usada por árvores; não afeta colisão. |
| `sort_y` opcional | Base vertical explícita para ordenação. Por padrão, usa a borda inferior do `rect`. |
| `ground_only` opcional | Desenha o sólido no chão, sem participar da oclusão dos corpos; usado pelo mar no mundo aberto. Não desativa a colisão. |

Os retângulos dos troncos atuais foram ajustados para **20×16**, conservando o centro horizontal e o limite inferior dos volumes anteriores. As copas usam largura/altura provisórias de 96 unidades. As fundações de casas, paredes, móveis, pedras e portas conservaram seus retângulos físicos; receberam alturas visuais de teste. Posições de entradas, NPCs, monstros e rotas não mudaram.

O cenário ganha faces superiores/frontais simples, telhado, tronco/copa e sombras. O corpo dos integrantes está ancorado pelos pés na posição lógica; o balanço provisório durante caminhada continua apenas visual. As alturas e proporções não são direção artística definitiva.

## Renderização

1. Chão, regiões, sombras, marcadores dos acessos, porta aberta e anel do líder.
2. Uma fila comum de corpos de obstáculos, NPCs, monstros, objetos e integrantes, ordenada pela base vertical no chão.
3. Indicações dos acessos, depuração explícita e HUD fixo.

Atores usam sua posição de chão; obstáculos usam a base inferior ou `sort_y`; porta fechada usa a base de seu retângulo. Empates são determinísticos, mantendo a ordem dos dados e desenhando o ator depois da estrutura. A porta aberta deixa a fila de corpos e não oculta o grupo. Sombras não são pintadas sobre os sprites.

`exploration_depth.gd` calcula a ordem sem modificar modelo ou coordenadas. A vista usa a mesma projeção da câmera em todas as camadas. Validação do catálogo rejeita valores visuais não numéricos, não finitos ou dimensões inválidas. Não há física nova, navegação, alteração do seguimento ou conversão para um mundo 3D.

## Arquivos

| Arquivo | Alteração |
| --- | --- |
| `scripts/exploration/exploration_depth.gd` | Novo cálculo puro de base, altura e ordem de desenho estável. |
| `scripts/exploration/exploration_view.gd` | Camadas de chão/corpos/debug; desenho elevado provisório e sprites ancorados pelos pés. |
| `scripts/exploration/area_catalog.gd` | Validação dos metadados visuais opcionais. |
| `data/exploration.json` | Bases dos troncos, copas e alturas de estruturas. |
| `data/house.json`, `data/dungeon.json` | Alturas visuais de obstáculos/porta; volumes físicos preservados. |
| `tests/depth_tests.gd` | Ordenação, empates, bases físicas, integrantes em lados diferentes, entidades e pureza do cálculo. |
| `tests/depth_ui_smoke.gd` | Oclusão renderizada de árvore/casa/parede, frente/atrás, fila, câmera, transições e porta. |
| Documentação | Regra confirmada, escolhas provisórias, configuração e validação. |

## Testes

```sh
godot --headless --path . --script res://tests/depth_tests.gd
godot --headless --path . --script res://tests/depth_ui_smoke.gd
```

As dezesseis suítes anteriores continuam no README. Em execução gráfica, a suíte de UI muda temporariamente a cor do personagem e compara pixels em pontos de sobreposição: atrás, o cenário mantém o pixel; na frente, o pixel muda com o personagem. A cor original é restaurada. Isso comprova o resultado renderizado além da ordem calculada. Esses testes usam somente a sessão automatizada.

Para salvar capturas, acrescente `-- --visual-captures=/caminho/absoluto/existente` ao executar a suíte de UI com renderização gráfica. Resultados reais em [VALIDACAO.md](VALIDACAO.md).
