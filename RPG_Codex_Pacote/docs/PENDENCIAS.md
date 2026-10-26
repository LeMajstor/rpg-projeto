# Pendências e limites de escopo

Esta lista impede que o Codex transforme lacunas em decisões arbitrárias.

## Antes de criar um projeto jogável

- Engine e linguagem (ex.: Godot, Unity etc.) — **não escolhidas**.
- Plataformas (PC, consoles, mobile) — **não escolhidas**.
- 2D/pixel art, resolução, controles, câmera e direção de arte — **não fechadas**, apesar das referências SNES.
- Escopo de um primeiro protótipo testável — **precisa de aprovação**.
- Organização de assets, saves, versões, convenções e ferramentas — dependem da engine.

## Regras de combate ainda abertas

- Fórmula precisa de preenchimento da ATB em função da INI efetiva; caps e limites de buffs.
- Quanto dura uma ação e em que instante a barra é zerada.
- Ordem de resolução de eventos simultâneos e de múltiplos inimigos prontos.
- Detalhes de modo Wait/Active para mira de área, seleção de alvo e animações.
- Como selecionar ações inimigas e suas respectivas probabilidades; pesos de perfis.
- Quem são alvos válidos com personagem incapacitado e habilidades de cura/ressurreição.
- Geometria das áreas, visualização de mira, tamanho do campo, distâncias e efeitos de alvo.
- Dano, atributos além de INI, fórmulas, efeitos de status, equipamentos, progressão e níveis.
- Probabilidade de fuga, exceções de chefes, efeitos colaterais da fuga.
- Itens, custos de MP, economia, recuperação em pousadas e condições de salvamento.
- Política de encontro já derrotado ao retornar ao mapa (respawn/persistência); identidade de encontros fixa está definida, mas o respawn não.

## Exploração e narrativa ainda abertas

- História principal e evento que no futuro libera o protagonista da equipe.
- Número, nomes, classes e raças dos companheiros.
- Habilidades individuais no cenário e mapas necessários para utilizá-las.
- Identidade/nome/regras de acesso ao local especial de troca de membros.
- Como o grupo de quatro segue o líder em corredores e durante transições entre mapas.
- Quais cenas exigem formação específica ou presença do protagonista.

## Proposta de sequência de implementação (NÃO autorizada automaticamente)

1. Escolher engine/plataforma e aprovar um recorte minúsculo da primeira versão.
2. Montar cena de dungeon provisória, com quatro sprites em fila e troca de líder pelo menu.
3. Configurar um encontro visível que carrega tela separada com preset fixo.
4. Montar ATB e escolha entre personagens prontos, com INI fixa configurável.
5. Implementar um inimigo estático e um móvel com rota determinada; separar posição lógica e animação.
6. Adicionar uma habilidade de área e a seleção de alvos.
7. Adicionar comportamento programático ponderado a pelo menos dois perfis de teste.
8. Só então estender comandos, recursos, save, game over e múltiplos encontros conforme decisão do usuário.

Cada etapa depende de aprovação do plano; não significa que toda a lista caiba num único ciclo de desenvolvimento.
