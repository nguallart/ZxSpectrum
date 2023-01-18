;;;; Version 0.001. Jan 2023
;;;; ZX Spectrum Assembly routines
;;;; Just for fun.


;;;; Subroutine spritebyrow: 
;;;; What it does: it shows a sprite that must be stored in a buffer by rows.
;;;; Weakness: We do not check anything (whether we are printing within limits, for example), so errors are possible.
;;;; Strengths: We can print beginning in any line (no need to be the first line of a cell),
;;;; and the height can be arbitrary (no need to be 8*n).
;;;; INPUT: HL, address of the (first byte of) the buffer; DE, absolute address of the screen memory (not coordinates).
;;;;        B, height in pixels, C, width in blocks of eight bits (bytes).
;;;; DESTROYED: A, A', BC, HL.

spritebyrow:
	ex af,af'  ; We store C (width) in A'. Faster than PUSHing and PULLing several times, you'll see.
	ld a,c
	ex af,af' 

theloop:			; "The" loop. Actually, outer loop, each row per cicle.
	ld a,b
	ld b,0   ;;; Now BC = C (width)
	ldir  ;;;; We print a whole row of C bytes
	ld b,a  ; B restore its original value
	
	ex af,af' ; We restore C (width) and we place DE to the beginning of the line
	ld c,a    ; Just L minus C, so there we are again.
	ex af,af' ; If we had done PUSH and POP, it would be slightly more time-consuming each time.
	ld a,e    ; This four lines take 16 t-states, whereas PUSH and POP take 11 each one.
	sub c     ; However, we should PUSH and POP each cycle, 22 t-states instead of 16.
	ld e,a

	ld a,d  ; 	;;;;; Now we need to check: Are we in the last line of a cell? (Line 7 if we start by 0).
	and 7 ;  
	cp 7
	jp z,$+7  ; If we are in line 7, we jump to the corresponding corrections.
	inc d   	; If not, the next DE is DE+256, that is, D=D+1.	  
	djnz theloop ; Back to the loop
	ret				 ; Ending of the routine

	ld a,e      ;;;; Ok, line 7. But, are we at the last line of a "third" of the screen? 
	add a,32      ; 
	jp nc, notsobad ; If we are not, we jump.

	ld a,e 	; We are at the last line of a third.
	add a,32  ; Incredibly easy. The next line begins at DE+32, so...
	ld e,a    ;;; 
	inc d     ;;; 
	djnz theloop  ;;; The loop
	ret

	notsobad: 	; We are in a line 7 but not at the end of a "third".
	ld a,32     ;;; We have to substract 1760 from DE. Why?
	add a,e     ; We go 7 lines up to line 0 (the first one of the cell), that is 7*256 = 1732
	ld e,a	    ; and then to the line 0 of the cell right down (that is +32).
	ld a,-7     ; So D-7 and E+32, that is DE - 1760
	add a,d   
	ld d,a    			
	djnz theloop  ; The loop
	ret 
;;;;;; End of the subroutine spritebyrow
