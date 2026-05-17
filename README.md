# USBDRIVE
## Interfaccia USB per PC 128 OLIVETTI PRODEST
L'USBDRIVE è la nuova interfaccia USB per PC128 in grado di emulare il floppy drive e montare le immagini FD dei floppy contenute in una pen drive. L'USBDRIVE è in grado di ripristinare anche le snapshot dell'emulatore DCOMOTO e molte altre funzionalità aggiuntive.
E' possibile inoltre avviare in file K7 patchati con il programma k7patcher.exe scaricabile dalla cartella UTILITY. Basta montare il file .k7 con il comando MOUNT e avviarlo seguendo le istruzioni descritte nel manuale del software da avviare.
Supporta pendrive formattate FAT e FAT32 ma non tutte sono compatibili. In caso di ripetuti errori di montaggio provare a formattare la pendrive con l'utility FAT32FORMAT.EXE.

I nuovi comandi di gestione del file system della PENDRIVE (firmware 3.4) sono disponibili soli da BASIC 128.
Il comando INFO restituisce la versione del firmware del controller che può essere aggiornata, la versione del firmware del CH376S non aggiornabile se non sostituendo il CH376S, la lista dei comandi disponibili e l'immagine selezionata (vedi screenshot).

<img width="674" height="464" alt="image" src="https://github.com/user-attachments/assets/3356f71d-54f7-432f-b0bc-2847da06f716" />


Il comando MOUNT"NOME.EST" monta qualsiasi file presente nella pendrive. Solo il formato compatibile .FD sarà visto come floppy disk e quindi sarà gestito come tale. Se il file immagine è di tipo autoboot, per evitare la partenza ad ogni reset, premere il tasto CTRL con il tasto 1 dal menù di selezione del basic per un secondo, ed il file verrà smontato.
Lo stesso comando può essere utilizzato per caricare un qualsiasi file nella memoria del PC128 aggiungendo ulteriori parametri:
MOUNT"IMAGE.BIN",&H6000,0 caricherà il file a partire dall'indirizzo $6000 banco 0. Se il file è più grande del banco (> $9FFF) il caricamento poseguirà al banco 1 dall'indirizzo $6000 e così via.

Il comando CREATE"NOME.EST" crea un disco vuoto non formattato. Dopo la creazione bisogna montarlo e formattarlo con DSKINI.
Il comando CREATE può essere utilizzato per salvare porzioni di memoria aggiungemdo dei parametri dopo il nome del file con la seguente sintassi:
CREATE"NOME.EST",&H6000,&H1000,0 crea un file nella pendrive salvando la memoria dall'indirizzo &H6000, di grandezza &H1000 bytes dal banco 0.

Il comando LAUNCH"NOME.EST" ripristina sul PC128 la snapshot precedentemente salvata dall'emulatore DCMOTO.

Il comando UDIR elenca i file contenuti nella pendrive. Premere un qualsiasi tasto per interrompere lo scorrimento dei file.

<img width="674" height="464" alt="image" src="https://github.com/user-attachments/assets/5083020a-df3a-4d63-9496-f5a177446f62" />

Il comando DEL"NOME.EST" cancella il file indicato.

## AGGIORNAMENTO DEL FIRMWARE USBDRIVE
Per aggiornare il firmware dell'USBDRIVE seguire i seguenti passaggi:
- prelevare l'ultima versione del firmware scaricando il file UPDATE.FD da git FIRMWARE e copiarlo nella chiavetta USB utilizzata
- da computer spento inserire il JUMPER nella parte posteriore dell'USBDRIVE in modo da chiudere il contatto. Nel caso delle USBDRIVE munite di switch spostarlo verso sinistra.
  
  <img width="200" height="300" alt="IMG20260517150634" src="https://github.com/user-attachments/assets/dbb1bca6-62c1-4a4c-b567-11386b873425" />
- inserire la USSBDRIVE nel PC128 con la chiavetta USB e accendere il PC128.
- da BASIC 128 selezionare il file UPDATE.FD con il comando MOUNT"UPDATE.FD"
- eseguire il file UPDATE.BAS digitando RUN"UPDATE.BAS"
  <img width="823" height="523" alt="image" src="https://github.com/user-attachments/assets/fd6c6355-f1bc-4cae-9797-524b97195a28" />
- ha inizio l'aggiornamneto
  <img width="828" height="526" alt="image" src="https://github.com/user-attachments/assets/74c7a79e-f085-4fff-8896-d7fbc8a0419c" />
- alla fine dell'aggiornamento spegnere immediatamente il PC128 e rimuovere il jumper o nel caso dello switch spostarlo verso destra.
- accendere di nuovo il PC128 e digitare il comando INFO per verificare la nuova versione del firmware. 
## FAT32FORMAT
E' un' utility in grado di formattare la pendrive in compatibile con la USBDRIVE.
Di seguito la modalità di utilizzo.

<img width="1103" height="639" alt="image" src="https://github.com/user-attachments/assets/3e55cf60-58e3-4862-9661-33fea2a94a2b" />
