# Estudo original de personagem e caminhada

Prévia visual criada a pedido do usuário. Não define o visual definitivo do protagonista e não foi integrada ao jogo.

- `character.png`: sprite-base em repouso, 96 × 112, transparência.
- `walk-original.gif`: oito quadros de 96 × 112, 100 ms cada, ciclo infinito de 800 ms.
- `walk-preview.gif`: mesma animação ampliada 3× com vizinho mais próximo.
- `walk-spritesheet.png`: grade 4 × 2, células 96 × 112, ordem por linhas.
- `character-base-source.png` e `walk-sheet-source.png`: gerações originais preservadas.
- `prompts.md`: prompts completos usados na ferramenta image_gen integrada.
- `alignment.json`: translações para alinhar cabeça e apoio dos pés; nenhuma pose foi deformada individualmente.
- `validation.json`: dimensões, duração, quadros e configurações conferidos.

A arte e as poses foram geradas; ImageMagick recortou/alinhou as células, reduziu com vizinho mais próximo e codificou o GIF. O formato GIF usa alpha binário com limiar de 90% para remover o halo semitransparente da exportação. As fontes PNG preservam o alpha recebido.

Conferência: oito poses com pernas estendidas, apoio e passagem; comparação visual dos contatos e folha completa. Contagem, dimensões, duração, repetição infinita e grade final verificadas por leitura dos arquivos exportados. Arte gerada ainda pode precisar de acabamento manual para produção.

Para conferir os quadros: `magick identify -format '%wx%h %T %D\n' walk-original.gif`.
