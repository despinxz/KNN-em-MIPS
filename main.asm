data

buffer: .space 20000        # Buffer para leitura dos arquivos
buffer_colunas: .space 1024 # Buffer para armazenar primeira linha de xtrain 

# Espaco reservado para os vetores
.align 3
v_xtrain: .space 40000
v_ytrain: .space 40000
v_xtest: .space 40000

# Constantes usadas ao longo do codigo
zero: .double 0.0       
dez: .double 10.0
fim: .double -1.0       # Valor que sera armazenado no fim de cada vetor
# Valor grande o suficiente que sera usado em comparacoes
valor_grande: .double 100000000000000000000.0		
   
# Strings de 0 e 1, que serao escritas em 'ytest'
zero_string: .asciiz "0.0"
um_string: .asciiz "1.0"
new_line_char: .asciiz "\n"
 
# Nome dos arquivos txt a serem lidos
xtrain: .asciiz "xtrain.txt"
ytrain: .asciiz "ytrain.txt"
xtest: .asciiz "xtest.txt"
ytest: .asciiz "ytest.txt"

.text
main:	
	# Inicia-se lendo os 3 arquivos: xtrain, ytrain e xtest
	la $a0, xtrain
	la $a3, v_xtrain
	jal ler_arq

	la $a0, ytrain
	la $a3, v_ytrain
	jal ler_arq

	la $a0, xtest
	la $a3, v_xtest
	jal ler_arq
	
	# Armazena a base de cada vetor em $s0, $s1 e $s2
	la $s0, v_xtest
	la $s1, v_xtrain
	la $s2, v_ytrain

	# Abre o arquivo 'ytest'
	li $v0, 13
	la $a0, ytest
	la $a1, 1	# Flag para abrir o arquivo no modo escrita
	syscall		# Abre o arquivo
	move $s3, $v0	# Salva descricao do arquivo em s3
	
	# Conta numero de colunas
	jal get_num_cols
	move $s4, $v0	# Salva numero de colunas em s4

	move $s5, $s0	# Armazena em $s5 o endereco base de xtest que sera iterado ponto a ponto

	# Loop que percorre o vetor xtest ponto a ponto chamando a funcao knn
	loop_xtest:
		l.d $f2, 0($s5)		# Armazena o valor do xtest atual p/ verificar se ainda ha dados para analisar
		l.d $f4, fim 		# Armazena o valor -1 para verificar se esta no fim
		c.eq.d $f2, $f4		# Compara se esta no fim do xtest (aka -1.0)
		bc1t end_of_program	# Se for, termina a chamada e volta pro main
		
		move $a0, $s4	# Primeiro parametro: $a0 o numero de coordenadas por ponto
		move $a1, $s1	# Segundo parametro: $a1 a base de xtrain
		move $a2, $s2	# Terceiro parametro: $a2 a base de ytrain
		move $a3, $s5	# Quarto parametro: $a3 o ponto atual de xtest
		
		# Estrutura de stack para salvar o valor de $s0-$s5 antes de chamar knn
		subi $sp, $sp, 32
		sw $ra 28($sp)
		sw $fp 24($sp)
		sw $s5 20($sp)
		sw $s4 16($sp)
		sw $s3 12($sp)
		sw $s2 8($sp)
		sw $s1 4($sp)
		sw $s0 0($sp)
		move $fp, $sp

		jal knn		# Chama-se a funcao knn
		
		# Estrutura de stack para recuperar o valor de $s0-$s5 apos chamar knn
		lw $s0 0($sp)
		lw $s1 4($sp)
		lw $s2 8($sp)
		lw $s3 12($sp)
		lw $s4 16($sp)
		lw $s5 20($sp)
		lw $fp 24($sp)
		lw $ra 28($sp)
		addi $sp, $sp, 32
		
		mul $t0, $s4, 8		# Multiplica numero de colunas pelo numero de bytes
		add $s5, $s5, $t0	# Avanca para o proximo ponto de xtest

		# Escreve o resultado em ytest
		move $a0, $s3		# Move a descricao de ytest para $a0
		move $a3, $s5		# Move o endereco atual de xtest para a3
		mov.d $f0, $f12		# Move o resultado da knn para f0

		# Estrutura de stack para salvar o valor de $s0-$s5 antes de chamar escreve_resultado
		subi $sp, $sp, 32
		sw $ra 28($sp)
		sw $fp 24($sp)
		sw $s5 20($sp)
		sw $s4 16($sp)
		sw $s3 12($sp)
		sw $s2 8($sp)
		sw $s1 4($sp)
		sw $s0 0($sp)
		move $fp, $sp
	
		jal escreve_resultado	# Pula para a funcao que escreve o valor em ytest

		# Estrutura de stack para recuperar o valor de $s0-$s5 apos chamar escreve_resultado
		lw $s0 0($sp)
		lw $s1 4($sp)
		lw $s2 8($sp)
		lw $s3 12($sp)
		lw $s4 16($sp)
		lw $s5 20($sp)
		lw $fp 24($sp)
		lw $ra 28($sp)
		addi $sp, $sp, 32

		j loop_xtest		# Volta ao loop do xtest para calcular novas distancias ou checar se acabou o vetor

	end_of_program:
		# Fecha o arquivo ytest
		li $v0, 16
		move $a0, $s3
		syscall

		# Syscall para o fim do programa
		li $v0, 10
		syscall


knn:
	l.d $f2, zero		# Carrega 0.0 em $f2 para calcular a distancia do ponto
	l.d $f4, valor_grande	# $f4 recebe um valor grande o suficiente para fazer comparacoes
	mul $s0, $a0, 8		# Armazena em $s0 o valor para voltar ao inicio do ponto de xtest (n coordenadas x 8 bytes)

	new_point:
		l.d $f16, 0($a1)	# Armazena em $f16 o valor do xtrain atual p/ verificar se ainda ha dados para analisar
		l.d $f18, fim		# Armazena -1.0 em $f18
		c.eq.d $f18, $f16	# Compara se esta no fim do xtrain (aka $f18 = -1.0)
		bc1t end_for_query	# Se for, termina a chamada e volta pro main

		li $t0, 0		# Reinicia o contador utilizado para cada ponto de xtrain

	calc_distance:
    		# Calculando a distancia Euclideana
    		l.d $f8, 0($a1)			# $f8 recebe o valor atual do xtrain
    		l.d $f6, 0($a3)			# $f6 recebe o valor atual do xtest
    		sub.d $f6, $f6, $f8		# Diferenca entre $f6 e $f8
   		mul.d $f6, $f6, $f6		# O quadrado da diferenca
    		add.d $f2, $f2, $f6  		# Adiciona a $f2, que e o registrador que armazena o quadrado da diferenca de cada ponto

    		# Passa para as proximas coordenadas de xtrain e xtest
    		addi $a1, $a1, 8		# Incrementa $a1 em 8 (valor de double)
    		addi $a3, $a3, 8		# Incrementa $a3 em 8 (valor de double)
    
    		# Verifica se ainda ha coordenadas a serem calculadas no ponto (n coordenadas por ponto) do xtrain
    		addi $t0, $t0, 1		# Incrementa o contador $t0
    		beq $t0, $a0, end_for_point	# Se $t0 = $a0, ja nao ha mais coordenadas para calcular no ponto
    		j calc_distance			# Jump para calc_distance, caso contrario
    
		end_for_point:
			l.d $f10, 0($a2)	# Carrega em $f10 o valor do ytrain no momento
			addi $a2, $a2, 8	# Atualiza a posicao do ytrain atual para a próxima iteracao
			c.lt.d $f2, $f4		# Compara se a distancia calculada no final desta iteracao e menor que a menor distancia encontrada ate agora
    			bc1t get_value		# Se for menor, altera os valores
	
			# Senao, simplesmente vai para uma iteracao e nao altera nada			
			sub $a3, $a3, $s0	# Volta para o inicio do ponto atual do xtest para calcular a nova distancia em outro ponto de xtrain
			l.d $f2, zero		# Zera o $f2 para calcular a nova distancia para o outro ponto de xtrain
			j new_point 		# Executa o calculo de novo para o novo ponto de xtrain
    	
		get_value:
			mov.d $f4, $f2		# Armazena em $f4 a distancia calculada agora (a menor ate entao)
			l.d $f2, zero		# Zera o $f2 para calcular a nova distancia para o outro ponto de xtrain
			mov.d $f14, $f10	# Armazena em $f14 o valor da classe
			sub $a3, $a3, $s0 	# Volta para o inicio do xtest para calcular a nova distancia em outro ponto
			j new_point		# Executa o calculo de novo para o novo ponto de xtrain

	end_for_query:
		mov.d $f12, $f14		# Armazena o valor de retorno
		jr $ra				# Volta para a funcao principal

# Calcula numero de colunas de xtrain
get_num_cols:
	la $a0, xtrain
	li $a1, 0
	li $a2, 0
	
	li $v0, 13
	syscall	# Abre o arquivo

	move $a0, $v0
	la $a1, buffer_colunas
	li $a2, 1024
	
	li $v0, 14
	syscall	# Move o arquivo para buffer_colunas
	
	li $v0, 16
	syscall	# Fecha arquivo
		
	la $t0, buffer_colunas	# Carrega o endereco de inicio do buffer em t0
	li $t1, 1		# t0 sera o contador de números numa linha, inicializado como 1
	
	le_linha:
		lb $t2, 0($t0)	# Carrega primeiro byte em t1
		beq, $t2, ',', add_num_col	# Caso o caractere seja uma virgula, pula para a funcao que incrementa o contador de colunas
		beq, $t2, '\r', fim_get_num_col	# Caso seja uma quebra de linha, conclui a funcao
		
		addi $t0, $t0, 1	# Avanca o byte
		j le_linha		# Retorna loop
		
		add_num_col:
			addi $t1, $t1, 1	# Incrementa contador
			addi $t0, $t0, 1	# Avanca o byte
			j le_linha		# Retorna loop
		
		fim_get_num_col:
			move $v0, $t1		# Retorna valor de t0 em v0
			jr $ra			# Retorna ao main

# Leitura do arquivo	
ler_arq:
	# Abre arquivo
	li $a1, 0
	li $a2, 0
	
	li $v0, 13
	syscall		

	# Carrega arquivo no buffer
	load:		
		move $a0, $v0
		la $a1, buffer
		li $a2, 17408
	
		li $v0, 14	# Move conteudo do arquivo para o buffer
		syscall
	
		li $v0, 16
		syscall		# Fecha o arquivo

	ler_num:
		la $s0, ($a3)	# Carrega o endereco do vetor passado como parametro em s0
		la $s1, buffer	# Carrega o buffer em s1
		l.d $f10, dez	# Carrega 10.0 em f10, que sera usado como uma constante
		la $s2, fim_copia
	
	copia_num:
		lb $t0, 0($s1)		# Carrega o byte em t0
		
		bne, $t0, '.', pula	# Se o caractere NAO for um ponto, pula as proximas linhas
		
		# Tratamento caso o caractere seja um ponto:
		li $t2, 1		# Se for um ponto, t2 e setado para 1 (como se fosse True)
		addiu $s1, $s1, 1
		lb $t0, 0($s1)		# Avanca para o proximo byte
		
		pula:
			beq $t0, ',', fim_num
			beq $t0, '\r', fim_num
			beq $t0, '\n', fim_copia	# Se o caractere for uma virgula ou quebra de linha, termina de copiar o numero atual
			beq $t0, 0, fim_arq		# Se o arquivo tiver terminado, vai para fim_arq
		
			subu $t0, $t0, 48		# Transforma ascii em int
		
			beq $t2, 1, le_double		# Se t2 for True, pula para le_double
		
			le_int:
				mul $t1, $t1, 10	# Multiplica o int armazenado anteriormente por 10
				add $t1, $t1, $t0	# Adiciona o caracter atual	
				j fim_copia
		
			le_double:
				mtc1 $t0, $f0
				cvt.d.w $f0, $f0	# Converte para double
			
				addiu $t3, $t3, 1	# Contador de divisoes por 10
			
				# Loop para dividir o número por 10^t3
				loop_double:
					div.d $f0, $f0, $f10
					addiu $t4, $t4, 1
					blt $t4, $t3, loop_double
			
			add.d $f2, $f2, $f0	# Soma resultado a parte decimal salva anteriormente
			li $t4, 0		# Zera contador do loop
			
			j fim_copia
			
		fim_arq:
			la $s2, fim_ler
			
		fim_num:
			mtc1 $t1, $f4
			cvt.d.w $f4, $f4	# Converte numero armazenado para double
			
			add.d $f4, $f4, $f2	# Soma parte decimal
			
			s.d $f4, 0($s0)		# Armazena no vetor
			
			li $t1, 0		# Reinicia acumulador inteiro
			li $t2, 0		# Parte decimal = False
			li $t3, 0		# Reinicia contador de casas decimais
			
			l.d $f0, zero		# Reinicia f0
			l.d $f2, zero		# Reinicia acumulador decimal
			
			addiu $s0, $s0, 8	# Avanca posicao no vetor
			jr $s2
			
		fim_copia:
			addiu $s1, $s1, 1	# Avanca um byte
			j copia_num

	fim_ler:
		l.d $f0, fim
		s.d $f0, 0($s0)		# Carrega -1.0 no fim do vetor
	
		la $t0, buffer
		li $t1, 17408
	
		zerar_buffer:
			sb $zero, 0($t0)    		# Armazena o valor zero no byte atual do buffer
    			addiu $t0, $t0, 1   		# Incrementa o endereco do buffer
    			addiu $t1, $t1, -1		# Decrementa o contador
    			bnez $t1, zerar_buffer      	# Se o contador nao for zero, continua o loop
    	
    jr $ra


escreve_resultado:
	l.d $f2, zero		# Carrega 0 em f2 para comparar o valor retornado
	c.eq.d $f0, $f2		# Compara o valor passado como parametro com 0
	bc1f escreve_um		# Caso seja diferente de 0 (ou seja, 1), vai para a funcao de escrever a string 1.0

	# Caso seja igual a 0, escreve a  string 0.0
	escreve_zero:	
		la $a1, zero_string
		j cont_escrita		# Pula para a continuacao
	
	# Escreve a string 1.0
	escreve_um:	
		la $a1, um_string

	# Faz a syscall para escrita no arquivo
	cont_escrita:	
		li $a2, 3	# Tamanho da string que vai ser escrita
		li $v0, 15	# Valor da syscall para escrita de arquivos
		syscall
	
	nova_linha:
		l.d $f2, 0($a3)		# Carrega em $f2 o valor atual de xtest
		l.d $f4, fim
		c.eq.d $f2, $f4		# Compara o valor passado com -1.0
		bc1t fim_escrita	# Caso seja igual a -1.0, nao coloque new_line_char
		
		# Escreve a quebra de linha
		add_nova_linha:
			la $a1, new_line_char
			li $a2, 1	# Tamanho da string que vai ser escrita
			li $v0, 15	# Valor da syscall para escrita de arquivos
			syscall
			
	fim_escrita:
		jr $ra