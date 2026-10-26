# Câmera seguindo o líder

## Comportamento confirmado

A exploração deve manter a distância visual anterior da casa também na dungeon, com a câmera acompanhando o líder da party. O ajuste anterior que encolhia cada mapa para mostrá-lo inteiro foi substituído. Exterior, casa e dungeon agora compartilham a mesma escala para uma mesma janela.

Não há alteração nos mapas, posições, colisões, fila, patrulhas, recursos, diálogos, transições ou combate. As entradas e o laboratório separado continuam funcionando.

## Executar e verificar

Abra `Executar exploracao.command` ou execute o projeto pelo Godot (F5).

1. No exterior, caminhe para cima/baixo e para os lados; o cenário acompanha o grupo quando há espaço para rolagem.
2. Entre na casa: os sprites mantêm seu tamanho anterior. Como ela cabe na janela, permanece centralizada.
3. Entre na dungeon: os sprites têm a mesma escala da casa. As salas que não cabem na altura aparecem conforme o líder avança.
4. No interior da dungeon, troque o líder pelo menu e caminhe verticalmente. A câmera acompanha o integrante da frente; não continua vinculada ao personagem anterior.
5. Aproxime-se das bordas: o enquadramento para no limite do mapa e o grupo pode sair do centro da janela. Um eixo que já cabe inteiro permanece centralizado.
6. Use E para conversar ou combater. HUD, botões e diálogos ficam fixos; após a luta, o mapa e a câmera retornam à mesma posição.
7. Use F3 para ver posição do líder, centro da câmera e escala. As rotas, sólidos e trilha continuam alinhados aos sprites.

Os controles existentes são preservados. Movimento/menu/diálogo e transições continuam respeitando as pausas anteriores. Não há tecla de zoom ou nova movimentação de combate.

## Escolhas técnicas provisórias

- Referência comum `camera_reference_size: [720, 480]` em `data/areas.json`, correspondente às dimensões anteriores da casa.
- Escala = menor razão entre espaço disponível da vista e referência. A escala varia com o tamanho da janela, igualmente para todas as áreas; não depende mais das dimensões do mapa ativo. Na vista padrão de 1392×594, equivale a 1,2375 pixel da UI por unidade lógica.
- Centro acompanha a posição lógica do líder, limitado por eixo para manter o mapa enquadrado. Quando um eixo inteiro cabe, usa o centro desse eixo. Seguimento imediato, sem atraso, inércia ou suavização.
- Transformação somente na apresentação: `screen_point` e `world_point` compartilham escala e origem. NPCs, objetos, rotas, sólidos, regiões e integrantes usam essa projeção.
- `map_frame` recorta seu filho de desenho: partes do mapa fora da janela não invadem botões ou cartões. Instruções e dados de F3 são desenhados em coordenadas de tela, fixos dentro da vista.
- Na transição, a projeção consulta o destino quando a troca ocorre sob o fade preto. Não há estado de câmera antigo a restaurar; ela deriva do mapa e do líder atuais. Reinício recarrega a referência comum do catálogo.

Limites, enquadramento em janelas de outras proporções e escala de referência são escolhas de teste. Arte, resolução definitiva e eventuais efeitos/suavização continuam pendentes.

## Arquivos

| Arquivo | Responsabilidade/alteração |
| --- | --- |
| `scripts/exploration/exploration_camera.gd` | Novo cálculo puro de escala, centro limitado e origem da projeção. |
| `scripts/exploration/exploration_view.gd` | Câmera aplicada ao desenho, conversão reversa e rodapé/F3 fixos. |
| `scripts/exploration/exploration_test.gd` | Carrega referência comum e coloca a vista dentro de um Control com recorte. |
| `data/areas.json` | Referência comum da escala. |
| `tests/camera_tests.gd` | Escala da casa anterior, limites, eixos curtos, projeção, tamanhos de janela e ausência de mutações do modelo. |
| `tests/camera_ui_smoke.gd` | Seguimento do novo líder, troca de áreas sob fade, NPCs, retorno do combate, reinício, capturas e verificação gráfica de recorte. |

Modelos, mapas individuais, dados e scripts do combate, cenas e configuração do projeto permanecem preservados.

## Testes

```sh
godot --headless --path . --script res://tests/camera_tests.gd
godot --headless --path . --script res://tests/camera_ui_smoke.gd
```

As quatorze regressões anteriores estão no README. Para as capturas opcionais, execute a suíte de UI com renderização gráfica e acrescente `-- --visual-captures=/caminho/absoluto/existente`. Resultados executados em [VALIDACAO.md](VALIDACAO.md).
