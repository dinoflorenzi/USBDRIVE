
*------------------------------------------------------
* VETTORI IN RAM
*------------------------------------------------------
DK_OPC  EQU $2048   codice comando controller floppy
DK_DRV  EQU $2049   numero del lettore floppy
DK_TRK  EQU $204a   n° traccia (2 byte)
DK_SEC  EQU $204c   n° settore
DK_NUM  EQU $204d   interlacciamento
DK_STA  EQU $204e   stato corrente controller floppy
DK_BUF  EQU $204f   indirizzo buffer settore (2 byte)
* posizione testine    n° traccia + n° settore (2 byte)
SD_LBA  EQU $2051   posizione testina lettore 0 (non utilizzata)
*TRACK1  EQU $2053   posizione testina lettore 1 (non utilizzata)
*TRACK2  EQU $2055   posizione testina lettore 2 (non utilizzata)
*TRACK3  EQU $2057   posizione testina lettore 3 (non utilizzata)
* indicatori del controller di floppy
ROTAT   EQU $2058   indicatore di rotazione del motore (non utilizzata)
DKFLG   EQU $2080   indicatore presenza controller disco

* Aree di lavoro sulla pila di sistema per il driver della scheda SD
SNAP  EQU $208E   indirizzo dell'inizio del file .sd nella scheda SD
*SD_TYP  EQU $2092   tipo di scheda SD=0 SDHC=1
BLOCKS   EQU $2093   definizione del comando CMD17 o CMD24
*SD_LBA  EQU $2094   indirizzo del settore corrente nella scheda SD
FNAME   EQU $2310

DKWE5   EQU $20e5   codice errore
DKWE7   EQU $20e7   puntatore sul nome del file
DKWE9   EQU $20e9   puntatore sul buffer
DKWEB   EQU $20eb   tipo di file
DKWEC   EQU $20ec   flag di file
DKWED   EQU $20ed   blocco libero nella FAT
DKWF0   EQU $20f0   codice operazione logica
DKWF5   EQU $20f5   numero di settore
DKWF6   EQU $20f6   numero di blocco
DKWF7   EQU $20f7   numero di byte nell'ultimo settore del file
DKWF9   EQU $20f9   numero di blocco allocato
DKWFA   EQU $20fa   numero del primo settore del blocco
DKWFB   EQU $20fb   numero di traccia del blocco corrente
BUFFER  EQU $2200   buffer di lettura/scrittura settore

*------------------------------------------------------
* ROM DEL CONTROLLER
*------------------------------------------------------
  ORG $A000
  FCB $53        S  controller scheda SD
  FCB $54        T  fat di 160 byte
  FCB $44        D  doppia densità
  FCB $40        @  checksum $53+$54+$44+$55=$140

OPTABL
  LBRA  DKCONT   funzioni standard
  LBRA  DKBOOT   avvio del boot
  LBRA  DKFMT    formattazione
  LBRA  LECFA    caricamento della fat
  LBRA  RECFI    apertura di un file
  LBRA  RECUP    cancellazione di un file
  LBRA  ECRSE    scrittura di un settore
  LBRA  ALLOD    creazione di un file
  LBRA  ALLOB    allocazione di un blocco
  LBRA  MAJCL    aggiornamento cluster
  LBRA  FINTR    chiusura di scrittura
  LBRA  PLAYSOUND ;A025
  LBRA  PLAYVIDEO ;A028

*------------------------------------------------------
* DKBOOT = Avvio del boot
* Se la scheda SD non è inizializzata:
* - selezione di un floppy
* - se settore di boot valido avvio del boot
* - altrimenti salto al contenuto di $001e
* Se la scheda SD è inizializzata:
* - se settore di boot valido avvio del boot
* - altrimenti ritorno al programma chiamante
*------------------------------------------------------
DKBOOT
  LBSR  DPINIT         ; initialisation DP
  
  LDS   #$20CC
  LDA   DK_STA        ; status
  ANDA  #$FB           ; raz bit 2
  STA   DK_STA        ; curseur invisible       

; lecture secteur de boot
  LDA   #$02           ; code lecture secteur
  STA   DK_OPC         ; stockage code operation 
  CLR   DK_DRV         ; 0 dans le numero de lecteur
  CLR   DK_TRK         ; toujours zero
  CLR   DK_TRK+1       ; selection piste 0
  LDA   #$01           ; valeur pour secteur 1
  STA   DK_SEC         ; selection secteur 1
  LEAU  BUFFER,PCR     ; adresse du buffer secteur
  STU   DK_BUF         ; stockage adresse buffer
  BSR   DKCONT         ; appel fonction standard
  BCS   DKB9           ; erre
; decryptage 128 octets et controle checksum
  LEAU  BUFFER,PCR     ; adresse debut de buffer      
  LEAY  $7F,U          ; adresse de fin des 128 octets
  PSHS  Y              ; empilage adresse de fin
  LDA   #$55           ; pour calcul checksum de boot
DKB4
  DEC   ,U             ; octet - 1
  COM   ,U             ; complement
  ADDA  ,U+
  CMPU  ,S             ; test fin de buffer
  BNE   DKB4           ; octet suivant
  PULS  Y              ; pour retablir le pointeur de pile
  CMPA  ,U             ; test checksum boot
  BNE   DKB9           ; checksum fausse
; execution du boot
  JMP   BUFFER,PCR     ; execute le boot
; sortie en erreur
DKB9
  CLR   DKFLG         ; indicateur de presence controleur
  JMP   [$001e]        ; lancement application a froid


*------------------------------------------------------
* DKCONT = Funzioni standard
*------------------------------------------------------
DKCONT
  PSHS  U,Y,X,DP,B,A,CC ; push dei registri
  LBSR  DPINIT         ; inizializzazione DP $20 o $60
  CLR   DK_STA         ; reset del codice di errore
  BSR   STDOP          ; esecuzione dell'operazione
  PULS  A              ; pop vecchio CC in A
  EXG   A,CC           ; ripristina il CC salvato
  LSRA                 ; sostituisce il bit carry di CC
  PULS  A,B,DP,X,Y,U,PC ; ritorno

*------------------------------------------------------
* Esecuzione funzione standard
*------------------------------------------------------
STDOP
  LDA   DK_OPC       Codice operazione
  LEAY  RESET,PCR     Reset controller
  BITA  #$01          Bit reset
  BNE   STDOP2        Esecuzione reset
  LEAY  RS256,PCR     Lettura settore logico
  BITA  #$02          Bit lettura settore
  BNE   STDOP2        Esegue lettura settore
  LEAY  SWRITE,PCR    Scrittura settore logico
  BITA  #$08          Bit scrittura settore
  BNE   STDOP2        Esegue lettura settore
  LEAY  FIND0,PCR     Ricerca traccia 0
  BITA  #$20          Bit ricerca traccia 0
  BNE   STDOP2        Esegue ricerca traccia 0
  LEAY  FINDT,PCR     Ricerca traccia
  BITA  #$40          Bit ricerca traccia x
  BNE   STDOP2        Esegue ricerca traccia x
  BITA  #$04          Bit passaggio semplice densità
  BNE   STDOP1        Non fare nulla
  BITA  #$10          Bit passaggio doppia densità
  BNE   STDOP1        Non fare nulla
  COMB                Set Carry = funzione sconosciuta
STDOP1
  RTS                 Ritorno
STDOP2
  JMP   ,Y            Esecuzione della funzione

*------------------------------------------------------
* INIZIALIZZAZIONE DP PER ACCESSO ALLA SCHEDA SD
*------------------------------------------------------
SDCONF
  ORCC  #$50          disattiva le interruzioni
  LDA   #$A7		
  TFR   A,DP
  RTS

*------------------------------------------------------
* INIZIALIZZAZIONE DP $20 (MO)
*------------------------------------------------------
DPINIT
  LDA   #$20           ; DP=$20 
  TFR   A,DP           ; DP=$20
  RTS                 

*------------------------------------------------------
* INIZIALIZZAZIONE 
*------------------------------------------------------
RESET
  PSHS X,D,DP
  BSR   SDCONF
  
    LDA #$EA           ;tasto CTRL
	STA   <$C1
	LDA   <$C1
	ANDA #$80
	BNE  RS268
	LDX  #$FFFF
	LDY  #8
RS270
	LEAY -1,Y
	BEQ DISABLE_CONTROLLER
RS269
    LEAX -1,X
	BEQ RS270
	LDA #$EA           ;tasto CTRL
	STA   <$C1
	LDA   <$C1
	ANDA #$80
	BEQ  RS269
	LDA #$36
	STA  <$BF
	CLR  <$BE
	LBSR  CH376_WAIT_INT
	BSR PAL_REST
	CLR $2300
	LDU #$A7C0
	LDX #$F65C
	LDS #$20BE
	LDA #$20
	TFR A,DP
	LDD #$3601
	JMP $F1b8
RS268
  
    LDA   #$30
    LBSR   COMMAND
    LBSR DELAY
    CMPB #$14
    BNE RESET5
		
    LDA   #$31
    LBSR	COMMAND
    LBSR DELAY
    CMPB #$14
    BNE  RESET5  
	
  LDA  #1
  STA  BLOCKS
  
    
*------------------------------------------------------
* RESET termina senza errore
*------------------------------------------------------
RESET3
  PULS D,X,DP
  CLRA                clear carry
  RTS                 ritorno senza errore
DISABLE_CONTROLLER
  CLR $A000
  PULS D,X,DP
  RTS   
RESET5
  CLR $2055
  LBSR CH376S_RESET
  PULS D,X,DP
  CLRA
  COMA
  RTS                 ritorno senza errore

PAL_REST
   PSHS X,Y,D
   LDY #16
   LEAX SYSPALETTE,PCR
   CLR <$DB
PAL_REST1
   LDD ,X++
   STB <$DA
   STA <$DA
   LEAY -1,Y
   BNE PAL_REST1
   PULS X,Y,D,PC
   
   
GETSIZE
   LDD  #$0C68
   STA  <$BF
   STB  <$BE
   LDB  <$BE
   LDA  <$BE
   LDA  <$BE
   LDA  <$BE
   RTS
   
COMMAND
        STA $A7BF
CH376_WAIT_INT
		PSHS X
		LDX #$2FFF
CH376_WAIT_INT1
		LEAX -1,X
		CMPX #0
		BEQ CH376_WAIT_INT2
		LDA	$A7BF
		BITA #$10
		BNE CH376_WAIT_INT1
CH376_WAIT_INT2
        BITA #$80
        BNE    CH376_WAIT_INT3
		LDA #$22
		STA $A7BF
CH376_WAIT_INT3
		LDB $A7BE
		PULS X
		RTS
*------------------------------------------------------
* RESET termina senza errore
*------------------------------------------------------
RESET4
  PULS D,X,DP
  ORCC #$01
  RTS                 ritorno senza errore
  
DELAY
  PSHS X
  LDX #$1fff
DELAY1
  LEAX -1,X
  CMPX #0
  BNE DELAY1
  PULS X,PC


*------------------------------------------------------
* Lettura di un settore di 256 byte
* LBA in funzione di: unità, traccia, settore, tipo scheda
* Indirizzo del buffer in DK_BUF
* Scrittura del buffer indicizzata dal registro Y
*------------------------------------------------------
RS256
  PSHS D,U,X,Y,DP
  LDA   #6
  CMPA  $277A
  BEQ   RS263
  STA   $277A
  LEAX  COMMANDS,PCR
  STX   $277B
  LEAX  START,PCR
  STX   $277D
RS263
  LBSR  DPINIT     inizializzazione DP $20
  LBSR  SETLBA
  LDY   DK_BUF
  BRA   RS266
RS265
  PSHS D,U,X,Y,DP
RS266
  LBSR   SDCONF
  LDA  #$3A	       ;BYTE READ (BLOCKS)
  STA  <$BF
  CLR  <$BE
  LDA   BLOCKS
  STA  <$BE
RS257
  LBSR	CH376_WAIT_INT
  CMPB #$1D
  BNE  RS267
RS258
  LDA #$27          ;BYTE REQUEST
  STA  <$BF
  LDB  <$BE
  BEQ RS264
RS260
  LDA <$BE        lettura di un byte
  STA   ,Y+        memorizzazione nel buffer
  
  DECB
  BNE   RS260      nuova lettura
  LDA #$3B         ;BYTE READ GO
  LBSR	COMMAND
  BRA   RS258      nuova lettura
RS264
  PULS X,Y,D,U,DP
  CLRA             clear Carry
  RTS
RS267
  PULS X,Y,D,U,DP
  LDA #$50
  STA $204E
  CLRA
  COMA
  RTS

*------------------------------------------------------
* Nuove funzioni Basic gestione USB DRIVE
* UDIR
* SELECT
* INFO
* LAUNCH
*------------------------------------------------------

START
  PSHS  D,X,Y,DP
  CMPA  #$FA
  BEQ   SETFILE
  CMPA  #$F9
  LBEQ   UDIR
  CMPA  #$FB
  LBEQ  RESTORE
  CMPA  #$FC
  LBEQ  CREATE
  CMPA  #$FD
  LBEQ  INFO
  CMPA  #$FE
  LBEQ  REMOVE
  PULS  D,X,Y,DP,PC


CH376S_RESET
    LDA   #$15
    STA   <$BF
	LDA   #$05
    STA   <$BE
    LBSR	CH376_WAIT_INT
    LBSR DELAY
    
    LDA   #$15
    STA   <$BF
	LDA   #$07
    STA   <$BE
    LBSR	CH376_WAIT_INT
    LBSR DELAY
    
    LDA   #$15
    STA   <$BF
	LDA   #$06
    STA   <$BE
    LBSR	CH376_WAIT_INT
    LBSR DELAY
    
    LDA   #$30
    LBSR   COMMAND
    LBSR DELAY
		
    LDA   #$31
    LBSR	COMMAND
    LBSR DELAY    
    RTS

*------------------------------------------------------
* REMOVE
*------------------------------------------------------ 
    
REMOVE
	BSR ULOAD
    LDA   #$35
    LBSR  COMMAND
    PULS  D,X,Y,DP,PC
   

*------------------------------------------------------
* SELECT
*------------------------------------------------------ 
SETFILE
  BSR   ULOAD
  PULS  D,X,Y,DP,PC
  
ULOAD
  LEAY  FNAME,PCR
ULOAD5
  JSR  $21C0
  STA ,Y+
  BNE  ULOAD5
  CLRB
  LEAY  FNAME,PCR
ULOAD1
  LDA  ,Y+
  CMPA  #$22
  BEQ   ULOAD13
  CMPA  #0
  BEQ  ULOAD14
  BRA ULOAD1
ULOAD13
  LBSR  SDCONF
  LDA   #$2F			;SET FILE NAME
  STA   <$BF
  STA   <$BE
ULOAD2
  LDA  ,Y+
  CMPA  #0
  BEQ   ULOAD3
  CMPA  #$22
  BEQ   ULOAD3
  STA   -2,Y
  STA   <$BE
  INCB
  BNE   ULOAD2
ULOAD3
  CLR   -1,Y
  CLR   <$BE
  LEAY FNAME,PCR
  INCB
  STB -1,Y
  LBSR	CH376_WAIT_INT 
  LEAY CREATE3,PCR
  CMPY ,S
  BEQ   ULOAD16
  LDA   #$32             ;OPEN FILE
  LBSR	COMMAND
  CMPB  #$41
  BEQ   ULOAD14
  CMPB  #$42
  BEQ   ULOAD14
  CMPB   #$14
  BNE   ULOAD15
  ;CLR $2300
  LDA $204E
  ANDA #$EF
  STA $204E
ULOAD16
  RTS
ULOAD14  
  LEAY  FNF_ERR,PCR
  LBSR  PRINT
  RTS
ULOAD15
  LBSR CH376S_RESET
  RTS
  
 

*------------------------------------------------------
* UDIR
*------------------------------------------------------  
  
UDIR
  JSR   $21C0 
  LBSR  SDCONF
  LDA   #$2F            ;SET FILENAME /*
  STA   <$BF
  STA   <$BE
  LDA   #$2A
  STA   <$BE
  CLR   <$BE
  LBSR	CH376_WAIT_INT
  LDA   #$32            ;OPEN
  LBSR	COMMAND
  CMPB #$14
  BEQ USBMAN2
  CMPB #$1D
  BNE USBMAN8
USBMAN2
  LDA   #$33           ;FILE ENUM GO
  LBSR	COMMAND
  LDA   #$27           ;BYTE REQUEST
  STA   <$BF
  LDA   <$BE
  CMPA  #$20        ;stampa punto estenzione
  BNE   USBMAN5
USBMAN1
  LDB   <$BE
  CMPA  #24
  BNE   USBMAN3
  PSHS  B
  LDB   #$2E
  SWI
  FCB   2
  PULS  B
USBMAN3
  CMPA  #5
  BHS    USBMAN10
  PSHS  B
USBMAN10
  CMPA  #22
  BLO   USBMAN6
  CMPB  #32
  BHS   USBMAN4
  LDB   #32
USBMAN4
  CMPB  #126
  BLS   USBMAN7
  LDB  #32
USBMAN7
  SWI
  FCB   2
USBMAN6
  DECA
  BNE   USBMAN1
  LDB  #29
  STB  $201C
  LEAS -12,S     
  LBSR U32TOA
  TFR S,Y
  CLR 12,Y
  LBSR PRINT
  LEAS 16,S
USBMAN11
  LDB   #10
  SWI
  FCB   2
  LDB   #13
  SWI
  FCB   2
USBMAN9
  	ANDCC #$AF
	SWI
	FCB $0A
	BNE USBMAN5
	BRA USBMAN2
USBMAN8
	LEAY  FNF_ERR,PCR
	LBSR  PRINT
USBMAN5
  PULS  D,X,Y,DP,PC
 


*------------------------------------------------------
* LAUNCH
*------------------------------------------------------ 

RESTORE
	LBSR  ULOAD
	ORCC #$d0
	LDS #$5FFF
	LDA #$39            ;BYTE LOCATE
	STA <$BF
	CLR <$BE
	LDA #$04
	STA <$BE
	CLR <$BE
	CLR <$BE
	LBSR	CH376_WAIT_INT
	
	LDA <$C0
	ANDA #$FE
	STA <$C0
	
	LDA #$20	;VIDEO RAM 0
	STA BLOCKS
	LDY  #0
	LBSR RS265
	
	LDD $1F40
	STD <$DC
	LDX #$1F42
	CLR <$DB
	LDY #$10
LOOP2
	LDD ,X++
	STA <$DA
	STB <$DA
	LEAY -1,Y
	BNE LOOP2
	
	INC <$C0
	
	LDA #$5E	;VIDEO RAM 1 + BANK 1(<5E00)
	STA BLOCKS
	LDY  #0
	LBSR RS265
	
	LDB #2        ; setta il banco 2
LOOP	
	STB <$E5
	LDA #$40	;BANK 2 - 7     $6000 - $9FFF
	STA BLOCKS
	LDY  #$6000
	LBSR RS265
	INCB
	CMPB #8
	BNE  LOOP
	
	LDS #$1FFF

	
	LDA #$10	;BANK 1
	STA BLOCKS
	LDY  #$5E00
	LBSR RS265
	JMP $1F70

PRINT
    LDB ,Y+
	BEQ  PRINT2
	SWI
	FCB  $02
	BRA  PRINT
PRINT2
    RTS
	

COMMANDS
  FCB 'U','D','I',0xD2
  FCB 'M','O','U','N','T'|0x80
  FCC "LAUNC"
  FCB 0xC8
  FCC "CREAT"
  FCB 0xC5
  FCC "INF"
  FCB 0xCF
  FCB 'D','E','L'|0x80
FNF_ERR
  FCC "ERROR"
  FCB 7,0

*------------------------------------------------------
* Calcolo del LBA scheda SD: SD_LBA =
* SD_LBA0+(512-511*SD_TYP)*(1280*DK_DRV+16*DK_TRK+DK_SEC-1)
* DK_DRV  n° lettore floppy
* DK_TRK  n° traccia (2 byte)
* DK_SEC  n° settore
* SD_TYP  tipo SD/SDHC
* (adattamento del codice originale di Samuel Devulder)
*------------------------------------------------------

SETLBA
  PSHS  U,X,D       empilage des registres utilise
  LBSR  DPINIT     inizializzazione DP $20
  LDB   <$4B     numero de piste
  BMI   SETLB8        erreur secteur
  CMPB  #$50          test piste 80
  BHS   SETLB8        erreur secteur
  LDA   #16           nombre de secteurs par piste 
  MUL                 multiplie par numero de piste
  TFR   D,X           X=DK_TRK*16
  LDB   <$4C       numero du secteur
  BEQ   SETLB8        erreur secteur=0
  CMPB  #$10          test secteur 16
  BHI   SETLB8        erreur secteur>16
  DECB                ramene intervalle [0-15]  
  ABX                 X=DK_TRK*16+DK_SEC-1
  TFR   X,D
  TST   <$49        A=numero d'unite
  BEQ   SETLB2
  LSLB
  ROLA
SETLB2
  STD  <$52
  CLR  <$54
  CLR  <$51
  CLRA                raz bit carry
  LBSR SDCONF
  LDA   #$39
  STA   <$BF
  LDD   $2053
  STB   <$BE
  STA   <$BE
  LDD   $2051
  STB   <$BE
  STA   <$BE
  LBSR	CH376_WAIT_INT
SETLB10
  PULS  D,X,U,PC    retour
SETLB7  
  LBSR  ERR10         erreur unite  
  BRA   SETLB10
SETLB8  
  LBSR  ERR04   
  BRA   SETLB10


*------------------------------------------------------
* Scrittura di un settore floppy
* nel settore SD completato a 512
*------------------------------------------------------
SWRITE
  LBSR  SETLBA      calcolo SD_LBA
  BCS  SWRITE9     errore unità/traccia/settore
SWRITE5
  LDY   DK_BUF    indirizzo del buffer
  LDA   #$3C
  STA	<$BF
  CLR   <$BE
  LDA   #$01
  STA   <$BE
SWRITE1
  LBSR	CH376_WAIT_INT
  CMPB #$1E
  BNE   SWRITE9
SWRITE3
  LDA   #$2D
  STA   <$BF
  LDA   <$BE
  LDB   <$BE
  BEQ   SWRITE4
SWRITE2
  LDA   ,Y+
  STA   <$BE
  DECB
  BNE   SWRITE2
  LDA   #$3D
  STA   <$BF
  LBSR	CH376_WAIT_INT
  BRA   SWRITE3
SWRITE4
  CLRA             clear Carry
  RTS
SWRITE9
  LDA #$50
  STA $204E
  CLRA
  COMA
  RTS

*------------------------------------------------------
* Ritorno di un codice errore
*------------------------------------------------------
ERRSET
  STA   DK_STA
  COMA
  COMA
  RTS

*------------------------------------------------------
* Errore di settore
*------------------------------------------------------
ERR04
  LDA   #$04
  BRA   ERRSET

*------------------------------------------------------
* Errore unità
*------------------------------------------------------
ERR10
  LDA   #$10
  BRA   ERRSET

*------------------------------------------------------
* Ricerca traccia
* Ricerca traccia 
*------------------------------------------------------
FINDT
FIND0
  CLRA             clear CC
  RTS              ritorno

*------------------------------------------------------
* DKFMT = formattazione del floppy
*------------------------------------------------------
DKFMT
  PSHS  U,Y,X,DP,B,A,CC
  ORCC  #$50       disattiva le interruzioni
  LBSR  DPINIT     inizializzazione DP $20 o $60
  CLR   DK_TRK
  CLR   DK_TRK+1  traccia 0
  LBSR  FMTRK      formattazione traccia 0
  LBSR  INIT20     inizializzazione traccia 20
  PULS  CC,A,B,DP,X,Y,U,PC

*------------------------------------------------------
* Formattazione di una traccia
*------------------------------------------------------
FMTRK
  LDA   #$E5       carattere di riempimento
  BSR   INIBUF     riempimento buffer
  LDA   #$01       numero primo settore
  STA   DK_SEC    memorizzazione numero settore
FMTRK1
  LBSR  SWRITE     scrittura di un settore
  LDA   DK_SEC    numero di settore
  CMPA  #$10       settore 16
  BEQ   FMTRK9     fine traccia
  INCA             incremento settore
  STA   DK_SEC    memorizzazione numero settore
  BRA   FMTRK1     settore successivo
FMTRK9
  RTS              ritorno

*------------------------------------------------------
* Riempimento del buffer di settore
*------------------------------------------------------
INIBUF
  LDY   DK_BUF    inizializzazione indirizzo
  CLRB             numero byte settore
INIB1
  STA   ,Y+        memorizzazione byte riempimento
  DECB             decremento contatore
  BNE   INIB1      byte successivo
  RTS              ritorno

*------------------------------------------------------
* Inizializzazione traccia 20
*------------------------------------------------------
INIT20
  LDX   #$0014     traccia 20
  STX   DK_TRK
  LDA   #$FF       valore di riempimento
  BSR   INIBUF     riempimento buffer
  LDA   #$08
  ORA   DK_OPC
  STA   DK_OPC
  CLRB             inizializzazione n° settore
INIT21
  INCB             settore successivo
  STB   DK_SEC
  LBSR  DKCONT     scrittura del settore
  BLO   INIT29
  CMPB  #$10       settore 16
  BNE   INIT21
  LDX   DK_BUF
  CLR   ,X         primo byte FAT = 0
  LDD   #$FEFE     blocchi riservati
  STD   $29,X      per traccia 20
  LDA   #$02
  STA   DK_SEC
  LBSR  DKCONT     scrittura del settore
  BLO   INIT29     ritorno in errore
  CLRA             nessun errore
INIT29
  RTS

*------------------------------------------------------
* SCRATCH DOS
*------------------------------------------------------
SCRDOS
  FCC   "SCRATCH"
  FCC   " DOS"

*------------------------------------------------------
* FINTR = chiusura di scrittura
*------------------------------------------------------
FINTR
  LDB   DKWF0     codice operazione logica
  CMPB  #$02
  BEQ   FINTR3
  DEC   DKWF0     codice operazione logica
  BSR   RECFI      apertura file
  BLO   FINTR9
  TSTB
  BEQ   FINTR1
  LBSR  RECUP
  BLO   FINTR9
FINTR1
  INC   DKWF0     codice operazione logica
  BSR   RECFI
  BLO   FINTR9
  LDB   #$0a
  LDX   DKWE7
FINTR2
  LDA   B,X
  STA   B,Y
  DECB
  BGE   FINTR2
  BSR   ECRSE      scrittura settore
  BLO   FINTR9
****************** salvataggio della FAT
FINTR3
  LDA   #$02
  STA   DK_SEC    settore 2
  LDB   #$14
  CLRA
  STD   DK_TRK    traccia 20
  LDD   DKWED     indirizzo della FAT
  STD   DK_BUF    indirizzo del buffer settore
  BSR   ECRSE      scrittura settore
  BLO   FINTR9     errore scrittura
  CLR   $20f0       indicatore chiusura file
FINTR9
  RTS

*------------------------------------------------------
* LECFA = Lettura della FAT
*------------------------------------------------------
LECFA
  LDX   DKWED     indirizzo della FAT
  STX   DK_BUF    indirizzo del buffer settore
  LDA   #$02       numero settore da leggere
  BRA   LSEC20     lettura settore traccia 20

*------------------------------------------------------
* Uscita in errore
*------------------------------------------------------
RETERR
  STA   DKWE5
  COMA
  COMA
  RTS

*------------------------------------------------------
* Caricamento 1° settore catalogo
*------------------------------------------------------
LDIR0
  LDA   #$03
  LDX   DKWE9     puntatore sul buffer
  STX   DK_BUF

*------------------------------------------------------
* Caricamento settore traccia 20
*------------------------------------------------------
LSEC20
  STA   DK_SEC
  LDB   #$14
  CLRA
  STD   DK_TRK
  LDA   #$02
  BRA   SECTIO

*------------------------------------------------------
* ECRSE = Scrittura di un settore
*------------------------------------------------------
ECRSE
  LDA   #$08

*------------------------------------------------------
* Operazione su settore
*------------------------------------------------------
SECTIO
  STA   DK_OPC
  LDY   DKWE9     puntatore sul buffer
  LBSR  OPTABL
  LDA   #$03
  RTS

*------------------------------------------------------
* RECFI = Apertura di un file
*------------------------------------------------------
RECFI
  CLR   $FFF0
  BSR   LDIR0      carica 1° settore catalogo
RECFI1
  BLO   RETERR     esce se errore
  LDX   #$0008     contatore di nomi in X
  LDY   DKWE9     puntatore sul buffer
RECFI2
  LDU   DKWE7
  LDB   DKWF0     codice operazione logica
  CMPB  #$03
  BNE   RECFI3
  LEAU  SCRDOS,PCR indirizzo del nome del file
RECFI3
  CLRB
RECFI4
  CMPB  #$0b
  BHS   RECFI8
  LDA   B,Y
  CMPA  #$ff
  BEQ   RECFI7
  INCB
  CMPA  ,U+
  BEQ   RECFI4
  LEAY  $20,Y
  LEAX  -$01,X
  CMPX #0
  BNE   RECFI2
  INC   DK_SEC
  LDA   DK_SEC
  CMPA  #$10
  BHI   RECFI7
  LBSR  OPTABL
  LDA   #$03          errore I/O
  BRA   RECFI1
RECFI7
  CLRB
  BRA   RECFI9
RECFI8
  LDB   $0b,Y
  CMPB  DKWEB
  BNE   RECFI7
  LDB   $0c,Y
  CMPB  DKWEC
  BNE   RECFI7
  LDB   DK_SEC
  LDA   $0d,Y
  STA   DKWF6
  CLR   DKWF5
  LDX   $0e,Y
  STX   DKWF7
  STY   DKWFA
RECFI9
  STB   DKWF9     numero di blocco allocato
  CLRA
  RTS

*------------------------------------------------------
* ALLOD = allocazione di un file
*------------------------------------------------------
ALLOD
  LDY   DKWED     indirizzo della FAT
  BSR   ALLOB4     test posto libero
ALLOD1
  BLO   RECFI1     errore più spazio
  STB   DKWF6     numero di blocco
  LBSR  LDIR0      carica inizio directory
ALLOD2
  BLO   ALLOD1     uscita in errore
  LDY   DKWE9     puntatore sul buffer
  LDX   #$0008     contatore di nomi in X
ALLOD3
  LDB   ,Y         primo byte del nome
  BEQ   ALLOD6     0=file cancellato
  LDA   #$05
  CMPB  #$ff
  BEQ   ALLOD6
  LEAY  $20,Y
  LEAX  -$01,X
  CMPX #0
  BNE   ALLOD3
  INC   DK_SEC
  LDA   DK_SEC
  CMPA  #$10
  BHI   ALLOD4
  LBSR  OPTABL     carica il settore successivo
  LDA   #$03
  BRA   ALLOD2
ALLOD4
  LDA   #$05       codice "disco pieno"
ALLOD5
  BRA   ALLOD1     esce con errore
ALLOD6
  LDX   DKWE7
  LDB   DKWF0     codice operazione logica
  CMPB  #$03
  BNE   ALLOD7
  LEAX  SCRDOS,PCR indirizzo nome del file
ALLOD7
  LDB   #$0a
ALLOD8
  LDA   B,X        copia il nome del file
  STA   B,Y        nel catalogo
  DECB
  BGE   ALLOD8
  LDA   DKWEB     tipo di file
  STA   $0b,Y
  LDA   DKWEC     copia il numero di blocco
  LDB   DKWF6     nel catalogo
  STD   $0c,Y
  LBRA  ECRSE      scrittura del repertorio

*------------------------------------------------------
* ALLOB = allocazione di un blocco
*------------------------------------------------------
ALLOB
  LDB   DKWF6     numero di blocco
  CMPB  #$50
  BHI   ALLOB3
ALLOB1
  TSTB
ALLOB2
  BEQ   ALLOB4
  LDA   B,Y
  CMPA  #$ff
  BEQ   ALLOB8
  DECB
  CMPB  #$50
  BLS   ALLOB1
ALLOB3
  ADDB  #$02
  CMPB  #$A1
  BRA   ALLOB2
ALLOB4
  LDB   #$50
ALLOB5
  LDA   #$05
  CMPB  #$A0
  LBHI  RETERR
  LDA   B,Y
  CMPA  #$ff
  BEQ   ALLOB8
  PSHS  B
  SUBB  #$50
  NEGB
  ADDB  #$50
  LDA   B,Y
  CMPA  #$ff
  BEQ   ALLOB6
  PULS  B
  INCB
  BRA   ALLOB5
ALLOB6
  LEAS  $01,S
ALLOB8
  CLR   B,Y
  DECB
  STB   DKWF9     numero di blocco allocato
ALLOB9
  CLRA
  RTS

*------------------------------------------------------
* RECUP = liberazione di un blocco
*------------------------------------------------------
RECUP
  LDA   $0d,Y
  STA   DKWF6     numero di blocco
  CLR   ,Y
  LBSR  ECRSE
  BLO   ALLOD5
  LDY   DKWED
  LDB   DKWF6     numero di blocco
RECUP1
  INCB
  LDA   B,Y
  CLR   B,Y
  DEC   B,Y
  TFR   A,B
  CMPA  #$c0
  BLO   RECUP1
  BRA   ALLOB9

*------------------------------------------------------
* MAJCL = Aggiornamento cluster
*------------------------------------------------------
MAJCL
  LDB   DKWF6       numero blocco
  CLRA
  LSRB               dividi per 2
  STD   DKWFB       numero traccia
  INCA
  STA   DKWF5
  BHS   MAJCL9
  LDA   #$09
MAJCL9
  STA   DKWFA
  RTS
  
  FILL 0,$A800-*
		ORG $A800


* ---------------------------------------------------------------------------
* SUBROUTINE: U32TOA_SAFE
* Input:  X = Puntatore al numero 32-bit unsigned
* U = Puntatore al buffer destinazione (min 12 byte)
* Output: Stringa ASCII scritta nel buffer.
* Preserva: U, X, Y, D (A,B), CC
* ---------------------------------------------------------------------------
U32TOA
        * 1. Salva lo stato di tutti i registri sullo Stack
        PSHS U,Y,X,D,CC
        * 4. Setup del buffer temporaneo locale
        LEAY 22,S         ; Y punta alla fine del buffer locale
        CLR ,Y            ; Mette il terminatore NULL (00) alla fine
		LDB #21
		LDA #32
U32TOA1
		STA B,S
		DECB
		CMPB #10
		BNE U32TOA1

CONV_LOOP
        * 5. Dividiamo il numero locale per 10
        LEAX 23,S         ; X punta al nostro numero locale
        BSR DIV32_10_LOC  ; Chiama la divisione. Restituisce il resto in B.

        * 6. Convertiamo in ASCII e salviamo
        ADDB #'0'         ; ASCII '0' = $30
        LEAY -1,Y         ; Sposta il puntatore locale indietro
        STB ,Y            ; Salva il carattere

        * 7. Controlliamo se il numero a 32 bit (il quoziente) è arrivato a 0
        LDA 23,S
        ORA 24,S
        ORA 25,S
        ORA 26,S
        BNE CONV_LOOP     ; Se non è 0, ripeti

        * 8. Trasferiamo la stringa locale al buffer del chiamante (U)
        * Nota: Modifichiamo il registro U temporaneamente (U+), ma il
        * vero valore di U è salvo nello stack e verrà ripristinato dopo!
        
        * La magia del 6809: ripristina tutti i registri esattamente come 
        * erano prima della chiamata, ignorando le modifiche fatte dentro.
        PULS CC,D,X,Y,U,PC

* ---------------------------------------------------------------------------
* SUBROUTINE INTERNA: DIV32_10_LOC
* Input: X = Puntatore al numero 32-bit (garantito locale allo stack)
* Output: B = Resto (0-9), [X] diviso per 10
* Preserva: A, X
* ---------------------------------------------------------------------------
DIV32_10_LOC
        PSHS A,X          ; Salva A e X (B non lo salviamo, conterrà il resto)
        LDB #0            
        PSHS B            ; Usa un byte sullo stack (0,S) come "Resto" locale
        LDA #32           ; A = Contatore dei 32 bit

BIT_LOOP
        * Shift globale a 32 bit verso sinistra
        ASL 3,X
        ROL 2,X
        ROL 1,X
        ROL 0,X           ; Il bit più alto esce nel Carry

        ROL ,S           ; Il Carry entra nel Resto (0,S)

        LDB ,S
        CMPB #10
        BLO SKIP_SUB      ; Se Resto < 10, salta
        
        * Se Resto >= 10
        SUBB #10          ; Sottrai 10
        STB ,S
        INC 3,X           ; Metti a 1 il bit meno significativo del quoziente

SKIP_SUB
        DECA
        BNE BIT_LOOP

        PULS B             ; Prendi il resto finale da 0,S e mettilo in B
        PULS X,A           ; Ripristina X e A
        RTS               ; Ritorno
		
*------------------------------------------------------
* CREATE
*------------------------------------------------------ 
CREATE
  LBSR   ULOAD
CREATE3
  LDA #$34
  LBSR COMMAND
  LDY DK_BUF
  LDA #$E5
  CLRB
CREATE1
  STA ,Y+
  DECB
  BNE CREATE1
  LDX #$500
CREATE2
   LBSR SWRITE5
   LEAX -1,X
   CMPX #0
   BNE CREATE2
   LDA #$36
   STA <$BF
   LDA #$01
   STA <$BE
   LBSR CH376_WAIT_INT
   LDA #$32
   LBSR COMMAND
   PULS  D,X,Y,DP,PC


INFO
  JSR   $21C0
  LBSR  SDCONF
  BSR VERSION
  LEAY HELP,PCR
  LBSR PRINT
  LDA   #$37
  STA   <$BF
  LDA   #$FF
  STA   <$BE
  LBSR CH376_WAIT_INT
  CMPB #$B4
  BEQ INFO2
  LDA #$27
  STA <$BF
  LDA <$BE
  BEQ INFO2
INFO3
  LDB <$BE
  CMPA #22
  BLO  INFO4
  CMPA #24
  BNE INFO1
  PSHS B
  LDB #$2E
  SWI
  FCB $02
  PULS B
INFO1
  SWI
  FCB $02
INFO4
  DECA
  BNE INFO3
INFO2
  PULS  D,X,Y,DP,PC
 
VERSION
  LEAY VERSION_LAB,PCR
  LBSR PRINT
  LDA #1
  STA <$BF
  LDB <$BE
  PSHS B
  LSRB
  LSRB
  LSRB
  LSRB
  BSR  NIBBLE2HEX
  PULS B
  ANDB #$0F
  BSR  NIBBLE2HEX 
  PULS  PC
NIBBLE2HEX
  CMPB #10
  BLO NIBBLE2HEX1
  ADDB #7
NIBBLE2HEX1
  ADDB #48
  SWI
  FCB 2
  RTS

HELP
  FCB 13,10,13,10
  FCC "USB INSTRUCTIONS:"
  FCB 13,10
  FCC "MOUNT"
  FCB 34
  FCC  "FILE.EST"
  FCB 34
  FCB 13,10
  FCC "LAUNCH"
  FCB 34
  FCC  "FILE.EST"
  FCB 34
  FCB 13,10
  FCC "CREATE"
  FCB 34
  FCC  "FILE.EST"
  FCB 34
  FCB 13,10
  FCC "DEL"
  FCB 34
  FCC  "FILE.EST"
  FCB 34
  FCB 13,10
  FCC "UDIR"
  FCB 13,10
  FCC "EXEC &HA025 TO STREAM AUDIO"
  FCB 13,10
  FCC "EXEC &HA028 TO STREAM VIDEO"
  FCB 13,10,13,10
  FCC "FILE IMAGE MOUNTED: "
  FCB 0
  
PLAYSOUND
    PSHS X,Y,D,DP
  	ORCC #$50
	LDA #$A7
	TFR A,DP
	LDA <$C0
	ANDA #$FB
	STA <$C0
	LDA <$CF
	ANDA #$FB
	STA <$CF
	LDB #$3F
	STB <$CD
	ORA #$04
	STA <$CF
LOOP13	
  LDA  #$3A
  STA  <$BF
  LDD  #$FFFF
  STB  <$BE
  STA  <$BE
LOOP14
  LDA  <$BF
  ANDA #$10
  BNE  LOOP14
  LDA #$22
  STA <$BF
  LDA <$BE
  CMPA #$1D
  BNE EXIT4
LOOP15
  LDA #$27          ;BYTE REQUEST
  STA  <$BF
  LDB  <$BE
  BEQ EXIT5
LOOP16
  LDX #5
LOOP18
  LEAX -1,X
  BNE LOOP18
  LDA <$BE
  STA <$CD
  DECB
  BNE LOOP16
  LDA #$3B
  STA <$BF
LOOP17
  LDA  <$BF
  ANDA #$10
  BNE  LOOP17
  BRA  LOOP15
EXIT5
  BRA LOOP13
EXIT4
  PULS X,Y,D,DP,PC
	
	
	
PLAYVIDEO
    PSHS X,Y,D,DP
  	ORCC #$50
	LDA #$A7
	TFR A,DP
	LDA <$C0
	ANDA #$FB
	STA <$C0
	LDA <$CF
	ANDA #$FB
	STA <$CF
	LDB #$3F
	STB <$CD
	ORA #$04
	STA <$CF
	
	LDA <$E7
	ORA #$10
	STA <$E7
	
	LDA <$E4
	ORA #$C0
	STA <$DD
	LDA <$E5
	PSHS A
	LDA #2
	STA <$E5
LOOP5
  BSR PALETTE
  LDA <$E4
  EORA #$40
  STA <$DD
  LDA <$E5
  EORA #$01
  STA <$E5
  LDY #$8000
  BSR SCREEN
  LDY #$6000
  BSR SCREEN
LOOP7
  BRA LOOP5
PALETTE
  LDA  #$3A
  STA  <$BF
  LDB  #32
  STB  <$BE
  CLR  <$BE
LOOP1
  LDA  <$BF
  ANDA #$10
  BNE  LOOP1
  LDA #$27          ;BYTE REQUEST
  STA  <$BF
  LDB  <$BE 
  BEQ  EXIT3
  LDX  #16
  CLR  <$DB
LOOP6
  LDA <$BE
  LDB <$BE
  STA <$DA
  STB <$DA
  LEAX -1,X
  BNE LOOP6
  LDA #$3B
  STA <$BF
LOOP3
  LDA  <$BF
  ANDA #$10
  BNE  LOOP3
EXIT2
  RTS
SCREEN
  LDX #1
  LDA  #$3A
  STA  <$BF
  LDD  #$2328
  STB  <$BE
  STA  <$BE
LOOP9
  LDA  <$BF
  ANDA #$10
  BNE  LOOP9
LOOP4
  LDA #$27          ;BYTE REQUEST
  STA  <$BF
  LDB  <$BE
  BEQ EXIT
LOOP12
  LEAX -1,X
  BNE SKIP
  LDA <$BE
  STA <$CD
  LDX #9
  BRA SKIP2
SKIP
  LDA <$BE
  STA ,Y+
SKIP2
  DECB
  BNE LOOP12
  LDA #$3B
  STA <$BF
LOOP10
  LDA  <$BF
  ANDA #$10
  BNE  LOOP10
  BRA  LOOP4
EXIT
  RTS
EXIT3
  LEAS 2,S
  PULS A
  STA <$E5
  LDA <$E4
  ANDA #$3F
  STA <$DD
  PULS X,Y,D,DP,PC
  
SYSPALETTE  
  FCB $00,$00,$10,$0F,$10,$F0,$10,$FF,$1F,$00,$1F,$0F,$1F,$F0,$1F,$FF
  FCB $17,$77,$13,$3A,$13,$A3,$13,$AA,$1A,$33,$1A,$3A,$1E,$E7,$10,$7B



  FILL 0,$AF80-*
  ORG $AF80
  
VERSION_LAB
  FCC "CONTROLLER VERSION 3.1"
  FCB 13,10
  FCC "CH376S FIRMWARE VERSION 0x"
  FCB 0
	
		
		FILL 0,$AFFF-*