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
;;;; DESTROYED: A, A', BC, HL, DE.

spritebyrow:
	ex af,af'  ; We store C (width) in A'. Faster than PUSHing and PULLing several times, you'll see.
	ld a,c
	ex af,af' 
theloop:			; "The" loop. Actually, outer loop, each row per cicle.
	ld a,b
	ld b,0   ;;; Now BC = C (width)
	ldir  ;;;; We print a whole row of C bytes
	ld b,a  ; B restores its original value
	
	ex af,af' ; We restore C (width) and we place DE to the beginning of the line
	ld c,a    ; Just E minus C, so there we are again.
	ex af,af' ; If we had done PUSH and POP, it would be slightly more time-consuming each time.
	ld a,e    ; We must not worry about D. Horizontal displacement only affects E.
	sub c     
	ld e,a

	ld a,d     ; Now we need to check: Are we in the last line of a cell? (Line 7 if we start by 0).
	and 7 ;  
	cp 7
	jp z,$+7  ; If we are in line 7, we jump to the corresponding corrections.
	inc d   	; If not, the next DE is DE+256, that is, D=D+1.	  
	djnz theloop ; Back to the loop
	ret				 ; Ending of the routine

	ld a,e      ;;;; Ok, line 7. But, are we at the last line of a "third" of the screen? 
	add a,32      ; 
	jp c, sobad ; If we not, we jump.
		 	    
	ld a,32    ; If not, we are in a line 7 but not at the end of a "third". 
	add a,e    ;;; We have to substract 1760 from DE. Why?
	ld e,a	   ; We go 7 lines up to line 0 (the first one of the cell), that is 7*256 = 1732  
	ld a,-7   ; and then to the line 0 of the cell right down (that is +32).  
	add a,d   ; So D-7 and E+32, that is DE - 1760
	ld d,a    			
	djnz theloop  ; The loop
	ret 

	sobad:
	ld a,e 	; We are at the last line of a third.
	add a,32  ; Incredibly easy. The next line begins at DE+32, so...
	ld e,a    ;;; 
	inc d     ;;; 
	djnz theloop  ;;; The loop
	ret
;;;;;; End of the subroutine spritebyrow





;;;; Subroutine copy_background_byrow: It does the opposite of spritebyrow.
;;;; What it does: It stores a rectangle from the video memory, and stores it in a buffer by rows.
;;;; Weakness: No previous checks. Possible faliure if inadequate input.
;;;; Strengths: The same as spritbyrow. 
;;;; INPUT: HL, origin (top left byte of the square); DE, destination (first byte),
;;;;        B, height in pixels, C, width in bytes.
;;;; DESTROYED: HL, DE, BC, A, A'.

copy_background_byrow:	

	ex af,af'
	ld a,c
	ex af,af'   ; We store C in A'. We will need to restore it again and again. 
copyrow:
	ld a,b
	ld b,0   ;;; BC = C (width of a row)
	ldir  ;;;; We store a row of C bytes in the buffer
	ld b,a  ; We retrieve B (number of lines) 
	
	ex af,af'
	ld c,a
	ex af,af' ;; We restore the original C

	ld a,l
	sub c
	ld l,a    ;;; Return to the beginning of the current line in the video memory 

	ld a,h 	; Are we in a 7th line in the video memory?
	and 7
	cp 7
	jp z, correct   ;;; If we are, we jump to the corrections
	inc h           ;;;; If not, next line is HL+256
	djnz copyrow    ;;;; We keep on with the loop
	ret  ;;; Eventual ending of the subroutine
	
	correct: ;;; We are in a 7th line
	ld a,l        
	add a,32      
	jp c,sobad_;  ; We jumo to this section if we are also at the last line of a "third"

	ld a,32 	; Otherwise, we do the same thing that we did in spritebyrow.
	add a,l
	ld l,a	
	ld a,-7    
	add a,h  ; 
	ld h,a    	   		
	djnz copyrow   ; Loop and eventual ending
	ret  
		
	sobad_:	; End of a third
	ld a,l
	add a,32
	ld l,a    ;;; Again, just HL+32
	inc h     ;;;
	djnz copyrow  ;;; Loop and eventual end
	ret  
;;;;;; End of subroutine copy_background_byrow
