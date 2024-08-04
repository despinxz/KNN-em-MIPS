# KNN em MIPS
Este repositório contém a implementação do algoritmo KNN na linguagem Assembly MIPS. O programa recebe como entrada um arquivo contendo as coordenadas dos pontos já conhecidos, e outro arquivo com suas respectivas classificações (sendo elas 0 ou 1). O terceiro arquivo passado como entrada contém as coordenadas dos pontos a serem classificados pelo algoritmo. O arquivo de saída conterá a classificação de cada ponto respectivamente.

## Autores
- Eloisa Antero Guisse
- Rafael Varago de Castro

## Arquivos do repositório
- **main.asm:** Código do programa MIPS;
- **x_train.txt:** Coordenada de pontos já conhecidos;
- **y_train.txt:** Classificação de cada ponto listado no arquivo `x_train.txt`;
- **x_test.txt:** Pontos com classificação ainda não conhecida, geradas após a execução do programa.
  
## Como executar
Para executar o código, é necessário usar um emulador MIPS, como o MARS. Após a execução, será gerado um arquivo `y_test.txt`, com a classificação de todos os pontos do arquivo `x_test.txt`.
