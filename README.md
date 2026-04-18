# USBDRIVE
## Interfaccia USB per PC 128 OLIVETTI PRODEST
L'USBDRIVE è la nuova interfaccia USB per PC128 in grado di emulare il floppy drive e montare le immagini FD dei floppy contenute in una pen drive. L'USBDRIVE è in grado di ripristinare anche le snapshot dell'emulatore DCOMOTO e molte altre aggiuntive-
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

