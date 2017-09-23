	.data
msg_wejscie:	.asciiz "Podaj sciezke do pliku wejsciowego\n"
msg_wyjscie:	.asciiz	"Podaj sciezke do pliku wyjsciowego\n"
msg_ramka:	.asciiz "Podaj rozmiar ramki\n"
obraz:		.space 	1000000
nzw_wejscie:	.space 	128
nzw_wyjscie:	.space 	128
naglowek:	.space 	54
bufor:		.space 	64
nowy_obraz:	.space 	64
ramka:		.byte	0						 
rozmiar:	.word	0
szerokosc:	.word	0
wysokosc:	.word	0



	.text	
	.globl main
	
main:
	li	$v0, 4
	la	$a0, msg_ramka		#zczytywanie ramki
	syscall
	
	li	$v0, 5
	syscall
	
	sb	$v0, ramka			#zapis ramki do pamieci

	li 	$v0, 4
	la 	$a0, msg_wejscie  #pytanie o sciezke do wejscia
	syscall
	
	li 	$v0, 8
	la 	$a0, nzw_wejscie	#pobranie sciezki wejscia
	li	$a1, 128
	syscall
	
	li 	$v0, 4
	la 	$a0, msg_wyjscie	#pytanie o sciezke do wyjscia
	syscall
	
	li 	$v0, 8
	la 	$a0, nzw_wyjscie	#pobranie sciezki wyjscia
	li	$a1, 128
	syscall
	
	
	
	
###Przygotowanie nazw plikow ############
	li 	$t0, 10
	la 	$t1, nzw_wejscie		#W t1 jest nazwa pliku wejsciowego
	
	
zamiana_nowej_linii:
	lbu	$t2, ($t1)
	addi	$t1, $t1, 1
	beq 	$t2, $t0, podmien		# jesli znak nowej linii to zamien go na zero
	b 	zamiana_nowej_linii
	
podmien:
	sb	$zero, -1($t1)
	la	$t1, nzw_wyjscie		# zaladowanie wyjscia zeby usunac znak nowej linii
	
zamiana_nowej_linii2:
	lbu	$t2, ($t1)
	addi	$t1, $t1, 1
	beq	$t2, $t0, podmien2		#jak znajdzie nowa linie to zamienia
	b zamiana_nowej_linii2
	
podmien2:
	sb	$zero, -1($t1)
	
############## Otwieranie pliku do odczytu #####################	

	li	$v0, 13			#systemcall do otworzenia pliku
	la	$a0, nzw_wejscie	
	li	$a1, 0			#otworzenie tylko do odczytu
	li	$a2, 0
	syscall	
	
#### zapis file describtion w s0

	move	$s0, $v0


##### Zapis BITEMAPHEADER'a
	li	$v0, 14			#systemcall do czytania z pliku
	move	$a0, $s0		
	la	$a1, naglowek		#adres bufora do ktorego ma czytac
	li	$a2, 54			#dlugosc ile ma przeczytac
	syscall
	
	
########################Odczytanie rozmiaru pliku ############

	la	$t0, naglowek
	la	$t2, rozmiar
	
	lbu 	$t9, 2($t0)
	sb	$t9, ($t2)
		
	lbu	$t9, 3($t0)
	sb	$t9, 1($t2)
	
	lbu	$t9, 4($t0)
	sb	$t9, 2($t2)
	
	lbu	$t9, 5($t0)
	sb	$t9, 3($t2)	
	
	lw	$t2, rozmiar
	sub	$t2, $t2, 54

	
	
###### Odczyt szerokosci i wysokosci obrazka ############
	la	$t3, szerokosc
	lbu	$t9, 18($t0)
	sb	$t9, ($t3)	
	lbu	$t9, 19($t0)
	sb	$t9, 1($t3)
	lbu	$t9, 20($t0)
	sb	$t9, 2($t3)
	lbu	$t9, 21($t0)
	sb	$t9, 3($t3)
	lw	$t3, szerokosc
	
	la	$t4, wysokosc
	lbu	$t9, 22($t0)
	sb	$t9, ($t4)	
	lbu	$t9, 23($t0)
	sb	$t9, 1($t4)
	lbu	$t9, 24($t0)
	sb	$t9, 2($t4)
	lbu	$t9, 25($t0)
	sb	$t9, 3($t4)
	lw	$t4, wysokosc	
	
		
###### Zapis obrazu do pamieci ########					

	li	$v0, 14			#czytanie z pliku
	move	$a0, $s0
	la	$a1, obraz		#zaladowanie bajtow z pikselami do obraz
	move	$a2, $t2
	syscall	
	
### Zamykanie pliku oryginalnego ########################
	li	$v0, 16
	move	$a0, $s0		# zamykanie pliku oryginalnego
	syscall
	

########Otworzenie pliku do zapisu#############################
	li	$v0, 13
	la	$a0, nzw_wyjscie
	li	$a1, 1			# flaga = 1 do edycji
	li	$a2, 0
	syscall
	
	move $s5, $v0	#zapis file describtion w s1
	
	########### Zapis naglowka do pliku ########
	li	$v0, 15
	move	$a0, $s5
	la	$t0, naglowek
	move	$a1, $t0
	li	$a2, 54	
	syscall
	
	
####Dopelnienie zerami################
	mul	$s7, $t3, 3
	li	$t9, 4
	div	$s7, $t9
	mfhi	$s7		#reszta z dzielenia	
	beq	$s7, $zero, dalej
	sub	$s7, $t9, $s7

dalej:	
	
	
	
	
	
#########Kopiowanie bitmapy#############		t0- naglowek 	t2 - rozmiar w bajtach,t3- szerokosc, t4- wysokosc, t5 - oryginal, t6 - kopia 

	la	$t5, obraz			#pod t5 mam oryginalny obraz
	la	$t6, nowy_obraz			# do t6 mam zapisywac zmieniony obraz
	
#################################
start_kopiowania:
	lbu	$t7, ramka	#t7 wielkosc ramki
	lbu	$t8, ramka	#t8 szerokosc od srodka ramki  w pixelach
	srl	$t8, $t8, 1
	li	$s1, 0		#licznik pozycji w wierszu
	li	$s0, 0		#licznik pozycji w wysokosci

	
kopiowanie_poczatku:			#pierwsze wiersze w obrazku dla ktorych nie mozna stowrzyc macierzy

	lw	$t0, szerokosc
	mul	$t0, $t0, 3
	add	$t9, $t0, $s7
	mul	$t9, $t9, $t8
					
	li	$v0, 15
	move	$a0, $s5
	move	$a1, $t5
	move 	$a2, $t9
	syscall
	
	add	$s0, $s0, $t8
	add	$t5, $t5, $t9	
	
skok:
	add	$t0, $t0, $s7
	mul	$t1, $t0, $t8	
	
kopiowanie_wierszy:				#poczatki wierszy dla ktorych nie da sie stworzyc macierzy

	
	li	$s1, 0	
	mul	$s2, $t8, 3
		
	li	$v0, 15
	move	$a0, $s5
	move	$a1, $t5
	move	$a2, $s2
	syscall
	

	
	add	$t5, $t5, $s2
	add	$s1, $s1, $t8
			
		
macierze:
	li	$t2, 0		#szerokosc macierzy
	li	$t4, 0		#wysokosc macierzy
	la	$s6, bufor
	li	$t9, 0
	
	
	lbu	$s3, ($t5)
	add	$t9, $t9, $s3
	sb	$s3, ($s6)
	
	
	lbu	$s3, 1($t5)
	add	$t9, $t9, $s3
	sb	$s3, 1($s6)
	
	
	lbu	$s3, 2($t5)
	add	$t9, $t9, $s3
	sb	$s3, 2($s6)
	
	move 	$s4, $t9
	
	
	
	add	$t5, $t5, $t1	#do gory o kilka wierszy zalezne od ramki
	sub	$t5, $t5, $s2	#przesuniecie na poczatek macierzy
########################################	
chodzenie_wiersz:
	li	$t9, 0
	lbu	$s3, ($t5)
	add 	$t9, $zero, $s3

	lbu	$s3, 1($t5)
	add	$t9, $t9, $s3

	
	lbu	$s3, 2($t5)
	add	$t9, $t9, $s3
	

	bge 	$t9, $s4, continue		
podmien1:
	
	lbu	$s3, ($t5)
	sb	$s3, ($s6)
		
	lbu	$s3, 1($t5)
	sb	$s3, 1($s6)
	
	lbu	$s3, 2($t5)
	sb	$s3, 2($s6)
	move	$s4, $t9
	b	chodzenie_wiersz		
	
continue:
	addi	$t2, $t2, 1
	beq	$t2, $t7, nast_wiersz
	addi	$t5, $t5, 3
	b	chodzenie_wiersz

nast_wiersz:
	addi	$t4, $t4, 1
	li	$t2, 0
	beq	$t4, $t7, nast_pix
	sub	$t5, $t5, $t0
	mul	$t9, $t7 , 3
	sub	$t5, $t5, $t9
	addi	$t5, $t5, 3
	b	chodzenie_wiersz	
	
nast_pix:					#nastepny pixel ktoremu chcemy stowrzyc macierz
	add	$t5, $t5, $t1		## tu tylko dla wierszowych
	sub	$t5, $t5, $s2
	addi	$t5, $t5, 3
	addi	$s1, $s1, 1		#zwiekszamy licznik szerokosci bo przechodzimy na nast pixel
	
	lbu	$s3, ($s6)		# zapisujemy do pliku minimalny pixel z bufora
	sb	$s3, ($t6)
	
	lbu	$s3, 1($s6)
	sb	$s3, 1($t6)
	
	lbu	$s3, 2($s6)
	sb	$s3, 2($t6)
	
	li	$v0, 15
	move	$a0, $s5
	la	$t6, nowy_obraz
	move	$a1, $t6
	li	$a2, 3
	syscall					#wynik z macierzy zapisujemy do pliku i patrzymy czy dalej w wierszu cos jest
	
czy_koniec_wiersza:
	lw	$t4, szerokosc
	sub	$t4, $t4, $t8
	bne	$t4, $s1, macierze
	

kop_koncowka:					#koncowe pixele w wierszu		
	li	$v0, 15
	move	$a0, $s5
	move	$a1, $t5
	move	$a2, $s2
	syscall
	
	add	$t5, $t5, $s2
	add	$s0, $s0 , 1
	
	
prev_dopelnienie2:
	beq	$s7, $zero, czy_koniec_tworzenia_macierzy
	li	$s1, 0	
dopelnienie2:
	
	sb	$zero, 	($t6)
	li	$v0, 15
	move	$a0, $s5
	la	$t6, nowy_obraz			#zapis pixela do pilku
	move	$a1, $t6
	li	$a2, 1
	syscall
	addi	$s1, $s1 , 1
	addi	$t5, $t5, 1
	bne	$s1, $s7, dopelnienie2
			
czy_koniec_tworzenia_macierzy:
	li	$s1, 0				#zerowanie licznika pozycji w wierszu
	lw	$t4, wysokosc
	sub	$t4, $t4, $t8
	bne	$t4, $s0, kopiowanie_wierszy				#wracamy na poczatek wiersza i kopiujemy	    
	
koncowka:
	lw	$t9, szerokosc
	mul	$t9, $t9, 3
	add	$t9, $t9, $s7
	mul	$t9, $t9, $t8
					
	li	$v0, 15
	move	$a0, $s5					#zapis pixela do pilku
	move	$a1, $t5
	move	$a2, $t9
	syscall
	
			
prev_dopelnienie_last:
	beq	$s7, $zero, koniec
	li	$s1, 0	
dopelnienie_last:
	
	sb	$zero, 	($t6)
	li	$v0, 15
	move	$a0, $s5
	la	$t6, nowy_obraz			#zapis pixela do pilku
	move	$a1, $t6
	li	$a2, 1
	syscall
	addi	$s1, $s1 , 1
	addi	$t5, $t5, 1
	bne	$s1, $s7, dopelnienie_last
			
###Zapis i  Zamykanie plikow ########################
koniec:
	li	$v0, 16
	move	$a0, $s5		# zamykanie pliku skopiowanego
	syscall
	
	
	li	$v0, 10			# zamkniecie programu
	syscall		
	
	
	
	
	
	
	
