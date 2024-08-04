# KNN em MIPS
Este repositório contém a implementação do algoritmo KNN na linguagem Assembly MIPS. Ele primeiramente armazena uma lista de pontos já classificados (sendo a classificação de cada ponto 0 ou 1), depois ele lê um arquivo com pontos a serem classificados, retornando a criação de um arquivo com a classificação de todos os respectivos pontos, calculada com base da classificação do vizinho mais próximo.

## Arquivos do repositório
- **main.asm:** Código do programa MIPS;
- **x_train.txt:** Coordenada de pontos já conhecidos;
- **y_train.txt:** Classificação de cada ponto listado no arquivo `x_train.txt`;
- **x_test.txt:** Pontos com classificação ainda não conhecida, geradas após a execução do programa.
  
## Como executar
Para executar o código, é necessário usar um emulador MIPS, como o MARS. Após a execução, será gerado um arquivo `y_test.txt`, com a classificação de todos os pontos do arquivo `x_test.txt`.
