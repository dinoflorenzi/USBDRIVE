/*
 * ====================================================================================
 * Filename: USBDRIVE_ITA3_PAR_FORMATTED.ASM
 * Author: dinoflorenzi
 * Date: 2026-03-30
 * Description: This file contains the ASM code for the USBDRIVE project.
 * ====================================================================================
 */

;
; ==========================
; Section: Initialization
; ==========================
START:
    ; Initialize data
    MOV     R0, #0          ; Clear R0
    STR     R0, [R1]       ; Store R0 in address R1

;
; ==========================
; Section: Main Loop
; ==========================
LOOP:
    LDR     R2, [R3]       ; Load value from address R3 to R2
    ADD     R4, R4, R2     ; Increment R4 by R2
    CMP     R4, #10        ; Compare R4 with 10
    BNE     LOOP           ; Branch if not equal

;
; ==========================
; Section: End
; ==========================
    B       END            ; Go to end
END:
    B       END            ; Infinite loop to end execution

; End of file
