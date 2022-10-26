;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Busy soft ;; DecLzx02 Universal depacker for 8080 ;; 12.09.2021 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	OPT	listact	;; Exclude not compiled branches IF/ENDIF from listing

;; Compilation:  SjASMPlus --i8080 DecLzx02-8080.a80

;; Setting user parameters - addresses of depacker, source and destinaton data, and optimization.
;; There are two possibilities how the setting can be provided:
;;
;;  1. Assign these labes elsewhere (i.e. in some other source code what includes this depacker)
;;     In this case, comment out these definitions, or define symbol "declzx_user_params" in your source.
;;
;;  2. Set all following values here manually

  IFNDEF declzx_user_params ;; Skip next assigns if all user data are already defined elsewhere

;; Executable address of depacker

	ORG	#8000

;; User settings of data addresses
;; (used for data overlay check too)

srcadd	=	#6000	;; Begin of source packed data
dstadd	=	#4000	;; Begin of destination area for depacked data

;; User setting optimization of depacker

lzxspd	=	0

;; Possible values of lzxspd:
;;  0 ... optimized for length - short but slow
;;  1+ .. optimized for speed  - but longer code

  ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Setting pack parameters = compression identification and data overlay check
;;
;; Next setting are generated by LzxPack and depends on used compression.
;; There are two possibilities how the setting can be provided:
;;  1. Read from *.inc file directly generated by LzxPack with option -i
;;  2. Manual setting according to compression identification and parameters

;; 1st possibility - read setting from *.inc file:
;; It is enough to uncomment following two lines
;; with include and define directives and fill
;; corresponding file name in this directive:

;	INCLUDE	filename.inc
;	DEFINE	declzx_pack_params

;; 2nd possiblity - manual setting:
;; It is needed to set proper values for following 10 labels:
;;
;;   Setting compression identification -tnXYcNoAoB (mandatory)
;;   (If some parameter is not present in identification, it does not matter)

  IFNDEF declzx_pack_params ;; If parameters are already defined (i.e. by previous include), this IF skips following definitions

revers	=	0	; n/r = Direction: 0 = normal -tn, 1 = reversed -tr
typcom	=	8	;; X = Compress type: 1=COMBLX 2=COMBLC 3=COMZX9 4=COMZX8 5=COMBS2 6=COMBX1 7=COMBX2 8=COMBX3 9=COMSX1
typpos	=	9	;; Y = Offset coding: 1=POSOF1 2=POSOF2 3=POSOF3 4=POSOF4 5=(none) 6=POSOV1 7=POSOV2 8=POSOV3 9=POSOV4
bytcop	=	2	;; N = Number of bits of copied byte - needed for BLX ZX9 BS2 BX1 BX2 BX3 SX1
ofset1	=	4	;; A = Number of bits for 1st offset - needed for OF1 OF2 OF3 OF4 OV2 OV3 OV4
ofset2	=	6	;; B = Number of bits for 1st offset - needed for OF2 OV3

;;   Setting for data overlay check (optional)

mindst	=	10	;; Minimal distance between block ends of source packed and destination unpacked data
pcklen	=	256	;; Length of source packed data
totlen	=	512	;; Length of dest unpacked data

;; LzxPack can produce two additional parameters:
;;   maxdct
;;   deplen
;; but they are not used in this depacker.

  ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Internal definitions

;; Systems for coding unpacked data and sequence lengths (values of label typcom)

COMBLX	=	1	;; Simple block compression - Elias-gamma length for both sequence and unpacked block (real sequence 1+ length supports compress simple bytes)
COMBLC	=	2	;; Simple block compression - Elias-gamma length for both sequence and unpacked block (real sequence 2+ length has width more 1 bit: EG+1)
COMZX9	=	3	;; Similar to ZX7 compression - 1 bit for each unpacked byte and 1 bit + Elias-gamma length for sequence 1+ bytes (supports packing of simple bytes)
COMZX8	=	4	;; Similar to ZX7 compression - 1 bit for each unpacked byte and 1 bit + Elias-gamma length for sequence 2+ bytes (length EG+1 bit)
COMBS2	=	5	;; Bitstream 1:unpack byte, 01:seq 2 bytes, 001:seq 3 bytes, 0001:seq 4+ bytes, 00000:1 unpack + rep offset, 00000:unpacked block 10+ bytes
COMBX1	=	6	;; Bitstream 1:unpack, 01:seq2, 001:seq3, 0001:copied, 00001:seq4+, 000001:unpack + rep.offset, 0000001:copied + rep.offs, 0000000:block 12+
COMBX2	=	7	;; Bitstream 1:unpack, 01:seq2, 001:copied, 0001:seq3, 00001:seq4+, 000001:unpack + rep.offset, 0000001:copied + rep.offs, 0000000:block 12+
COMBX3	=	8	;; Bitstream 1:unpack, 01:copied, 001:seq2, 0001:seq3, 00001:seq4+, 000001:unpack + rep.offset, 0000001:copied + rep.offs, 0000000:block 12+
COMSX1	=	9	;; Bitstream 1:seq 2+, 01:unpack, 001:copied, 0001:unpack + rep offset, 00001:copied + rep offset, 00000:unpack block 5+ bytes

;; Systems for coding offsets in sequences (values of label typpos)

POSOF1	=	1	;; One fixed offset used for all sequences
POSOF2	=	2	;; Two fixed offsets (similar to ZX7)
POSOF3	=	3	;; Three fixed step offsets (1,2,3 or 2,4,6 or 3,6,9 or 4,8,12 or 5,10,15)
POSOF4	=	4	;; Four fixed step offsets (1,2,3,4 or 2,4,6,8 or 3,6,9,12 or 4,8,12,16 bits)
;;;;;;	=	5	;; (not used)
POSOV1	=	6	;; Simple variable Elias-gamma coding offset
POSOV2	=	7	;; One fixed offset and one variable offset
POSOV3	=	8	;; Two fixed offsets A,B and one variable Elias-gamma offset EG+B bits and +A addition
POSOV4	=	9	;; Three fixed step offsets (1,2,3 or 2,4,6 or 3,6,9 or 4,8,12) and one variable offset

;; You can use these constants to define labels "typcom" and "typpos" in definition of compress type -tnXYcNoAoB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Macro definitions

LDX	MACRO
	IF revers
	  ld	a,(hl)	;; ldd
	  ld	(de),a
	  dec	hl
	  dec	de
	ELSE
	  ld	a,(hl)	;; ldi
	  ld	(de),a
	  inc	hl
	  inc	de
	ENDIF
	ENDM


PSALDX	MACRO
	  push af
	  LDX
	  pop af
	ENDM

LDXR	MACRO
	IF revers
.lddr	  ld	a,(hl)	;; lddr
	  ld	(de),a
	  dec	hl
	  dec	de
	  dec	bc
	  ld	a,b
	  or	c
	  jp	nz,.lddr
	ELSE
.ldir	  ld	a,(hl)	;; ldir
	  ld	(de),a
	  inc	hl
	  inc	de
	  dec	bc
	  ld	a,b
	  or	c
	  jp	nz,.ldir
	ENDIF
	ENDM

PSALDXR	MACRO
	  push af
	  LDXR
	  pop af
	ENDM

INCHL	MACRO
	IF revers
	  dec	hl
	ELSE
	  inc	hl
	ENDIF
	ENDM

INCOFS	MACRO
	  inc	bc
	ENDM

GETBIT	MACRO			;; Get one bit from bitstream

    IF lzxspd			;; Speed optimized variant
	add	a,a		;; Reading bit from buffer (A = temporary buffer for bits)
	jp	nz,.end		;; If there were some bits in buffer then return
	ld	a,(hl)		;; Buffer is empty so we must read next byte from bitstream
	adc	a,a		;; MSB bit will be returned reading bit
	INCHL			;; Move to next byte in packed data
.end
    ELSE
	call	declzx_getbit	;; Length optimized variant
    ENDIF

	ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Validation of parameters 'typcom' and 'typpos'
;; to make sure they contain only supported values

	ASSERT	typcom=COMBLX or typcom=COMBLC or typcom=COMZX9 or typcom=COMZX8 or typcom=COMBS2 or typcom=COMBX1 or typcom=COMBX2 or typcom=COMBX3 or typcom=COMSX1
	ASSERT	typpos=POSOF1 or typpos=POSOF2 or typpos=POSOF3 or typpos=POSOF4 or                  typpos=POSOV1 or typpos=POSOV2 or typpos=POSOV3 or typpos=POSOV4

;; Data overlay check
;; to make sure destination depacked data does not overwrite source packed data not used yet

	IF revers
	  ASSERT  srcadd + mindst <= dstadd  OR  dstadd + totlen <= srcadd
	ELSE
	  ASSERT  dstadd + totlen + mindst <= srcadd + pcklen  OR  srcadd + pcklen <= dstadd
	ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Start of depacker

;; Set input and output addresses.
;; If addresses are set into HL and DE from calling program,
;; define the symbol "declzx_init_addres" to skip these settings.

declzx_start	IFNDEF declzx_init_addres	;; Skip next setting HL,DE if they are set from calling program.

		  IF revers
		    ld	hl,srcadd+pcklen-1	;; In case of reversed unpacking,
		    ld	de,dstadd+totlen-1	;; it is need to set address of last byte
		  ELSE
		    ld	hl,srcadd
		    ld	de,dstadd
		  ENDIF

		ENDIF

;; Input:
;;   HL = address of source packed data
;;   DE = address of destination to depack data
;; When reversed direction (revers=1) is used, HL and DE must point to last byte of data.

		ld	a,#80		;; Initial value what means there are no bits from bitstream in A

;; Processing compression types and lengths

	    IF typcom=COMBLX

		jp	declzx_main	;; Skip following LDIR / LDDR
declzx_ldx	PSALDXR
declzx_main	push	de
		call	declzx_getegv0	;; Get length of next block             *** BLX compression ***
		pop	de
		ret	c		;; Return if end mark occured
		GETBIT
		jp	c,declzx_ldx	;; 1 ... unpacked block
		push	bc		;; 0 ... sequence
		dec	c
		jp	nz,declzx_sek	;; Jump if length > 1
		inc	b
		dec	b
		jp	nz,declzx_sek
		push	de
		ld	e,bytcop	;; Sequence length = 1 means copying one standalone byte
		call	declzx_getnum	;; Read offset for copying byte from bitstream
		pop	de
		inc	c		;; Increment offset
		jp	declzx_copy	;; Jump copying sequence (in this case only one byte)

declzx_sek				;; Continue to read sequence offset

	    ENDIF


	    IF typcom=COMBLC

declzx_main	GETBIT			;; Get ID of next block                *** BLC compression ***
		jp	nc,declzx_blc	;; 1 = unpacked block, 0 = sequence
		push	de
		call	declzx_getegv0	;; Get length of unpacked block
		pop	de
		PSALDXR			;; Copy unpacked block
		jp	declzx_main

declzx_blc	push	de
		ld	e,#01		;; Get Elias-Gamma with one addtional bit
		call	declzx_getegvx	;; Read length of sequence from bitstream
		pop	de
		ret	c		;; Return if end mark occured
		push	bc		;; Continue to read sequence offset
	    ENDIF


	    IF typcom=COMZX9

declzx_ldx	PSALDX			;; Copy one unpacked byte                 *** ZX9 compression ***
declzx_main	GETBIT
		jp	c,declzx_ldx	;; 1 ... one unpacked byte, 0 ... sequence
		push	de
		call	declzx_getegv0	;; Get length of sequence
		pop	de
		ret	c		;; Return if end mark occured
		push	bc
		dec	c
		jp	nz,declzx_sek	;; Jump if length > 1
		inc	b
		dec	b
		jp	nz,declzx_sek
		push	de
		ld	e,bytcop	;; Sequence length = 1 means copying one standalone byte
		call	declzx_getnum	;; Read offset for copying byte from bitstream
		pop	de
		inc	c		;; Increment offset
		jp	declzx_copy	;; Jump copying sequence (in this case only one byte)

declzx_sek				;; Continue to read sequence offset

	    ENDIF


	    IF typcom=COMZX8

declzx_ldx	PSALDX			;; Copy one unpacked byte                 *** ZX8 compression ***
declzx_main	GETBIT
		jp	c,declzx_ldx	;; 1 ... one unpacked byte
		push	de
		ld	e,#01		;; 0 ... sequence 2+ bytes
		call	declzx_getegvx	;; Read sequence length from bitstream
		pop	de
		ret	c		;; If length > 65535 then end of data (end mark)
		push	bc		;; Continue to read sequence offset

	    ENDIF


	    IF typcom=COMBS2

declzx_ldx	PSALDX			;; Copy one unpacked byte                 *** BS2 compression ***
declzx_main	GETBIT
		jp	c,declzx_ldx	;; 1 ... next unpacked byte follows
		ld	bc,#02		;; Set length to 2
		GETBIT
		jp	c,declzx_push	;; 01 ... sequence (length=2) follows
		inc	c		;; Set length to 3
		GETBIT
		jp	c,declzx_push	;; 001 ... sequence (length=3) follows
		GETBIT
		jp	c,declzx_sek	;; 0001 ... sequence (length=4+) follows
		GETBIT
		jp	c,declzx_reuse	;; 00001 ... one unpack byte + reused offset
		push	de
		ld	e,c
		call	declzx_getegvx	;; 00000 ... get length of unpacked block (length = EG+3)
		pop	de
		ret	c		;; If length > 65535 then end of data (end mark)
		inc	bc		;; Length >= 9
		PSALDXR			;; Copy unpacked data
		jp	declzx_ldx	;; Copy one additional unpacked byte for length >= 10

declzx_reuse	PSALDX			;; Copy one byte
		push	de
		ld	e,#01
		call	declzx_getegvx	;; Sequence length EG+1
		pop	de
		push	bc
declzx_last	ld	bc,#5555	;; Previous used offset
		jp	declzx_copy

declzx_sek	push	de		;; C=2
		ld	e,#02
		call	declzx_getegvx	;; Get length of packed sequence EG+2 (length >= 4)
		pop	de
declzx_push	push	bc		;; Continue to read sequence offset

	    ENDIF


	    IF typcom=COMBX1

declzx_ldx	PSALDX			;; Copy one unpacked byte                 *** BX1 compression ***
declzx_main	GETBIT
		jp	c,declzx_ldx	;; 1 ... one unpacked byte
		ld	bc,#02
		GETBIT
		jp	c,declzx_push	;; 01 ... sequence 2 bytes
		inc	c
		GETBIT
		jp	c,declzx_push	;; 001 ... sequence 3 bytes
		dec	c		;; C = 2
		GETBIT
		jp	c,declzx_onemain;; 0001 ... one copied byte
		GETBIT
		jp	c,declzx_sek	;; 00001 ... sequence 4+ bytes
		GETBIT
		jp	c,declzx_repunp	;; 000001 ... one unpack byte + reused offset
		GETBIT
		jp	c,declzx_repcpy	;; 0000001 ... one unpack byte + reused offset
		push	de		;; C = 3
		ld	e,#03
		call	declzx_getegvx	;; 0000000 ... unpacked block (length = EG+3)
		pop	de
		inc	bc
		inc	bc
		inc	bc		;; Length += 3
		PSALDXR			;; Copy unpacked data
		jp	declzx_ldx	;; Copy one additional unpacked byte for length >= 12

	    ENDIF


	    IF typcom=COMBX2

declzx_ldx	PSALDX			;; Copy one unpacked byte                 *** BX2 compression ***
declzx_main	GETBIT
		jp	c,declzx_ldx	;; 1 ... one unpacked byte
		ld	bc,#02
		GETBIT
		jp	c,declzx_push	;; 01 ... sequence 2 bytes
		GETBIT
		jp	c,declzx_onemain;; 001 ... one copied byte
		inc	c
		GETBIT
		jp	c,declzx_push	;; 0001 ... sequence 3 bytes
		dec	c		;; C = 2
		GETBIT
		jp	c,declzx_sek	;; 00001 ... sequence 4+ bytes
		GETBIT
		jp	c,declzx_repunp	;; 000001 ... one unpack byte + reused offset
		GETBIT
		jp	c,declzx_repcpy	;; 0000001 ... one unpack byte + reused offset
		push	de		;; C = 3
		ld	e,#03
		call	declzx_getegvx	;; 0000000 ... unpacked block (length = EG+3)
		pop	de
		inc	bc
		inc	bc
		inc	bc		;; Length += 3
		PSALDXR			;; Copy unpacked data
		jp	declzx_ldx	;; Copy one additional unpacked byte for length >= 12

	    ENDIF


	    IF typcom=COMBX3

declzx_ldx	PSALDX			;; Copy one unpacked byte                 *** BX3 compression ***
declzx_main	GETBIT
		jp	c,declzx_ldx	;; 1 ... one unpacked byte
		GETBIT
		jp	c,declzx_onemain ; 01 ... one copied byte
		ld	bc,#02
		GETBIT
		jp	c,declzx_push	;; 001 ... sequence 2 bytes
		inc	c
		GETBIT
		jp	c,declzx_push	;; 0001 ... sequence 3 bytes
		dec	c		;; C = 2
		GETBIT
		jp	c,declzx_sek	;; 00001 ... sequence 4+ bytes
		GETBIT
		jp	c,declzx_repunp	;; 000001 ... one unpack byte + reused offset
		GETBIT
		jp	c,declzx_repcpy	;; 0000001 ... one unpack byte + reused offset
		push	de		;; C = 3
		ld	e,#03
		call	declzx_getegvx	;; 0000000 ... unpacked block (length = EG+3)
		pop	de
		inc	bc
		inc	bc
		inc	bc		;; Length += 3
		PSALDXR			;; Copy unpacked data
		jp	declzx_ldx	;; Copy one additional unpacked byte for length >= 12

	    ENDIF


	    IF typcom=COMSX1

declzx_ldx	PSALDX			;; Copy one unpacked byte                 *** SX1 compression ***
declzx_main	ld	bc,#01		;; Set length to 1
		GETBIT
		jp	c,declzx_sek	;; 1 ... regular 2+ sequence
		GETBIT
		jp	c,declzx_ldx	;; 01 ... one unpacked byte
		GETBIT
		jp	c,declzx_onemain;; 001 ... one copied byte
		GETBIT
		jp	c,declzx_repunp	;; 0001 ... one unpack byte + reused offset
		GETBIT
		jp	c,declzx_repcpy	;; 00001 ... one copied byte + reused offset
		push	de		;; C = 2
		ld	e,#02
		call	declzx_getegvx	;; 00000 ... unpacked block (length = EG+2)
		pop	de
		PSALDXR			;; Copy unpacked data
		jp	declzx_ldx	;; Copy one additional unpacked byte for length >= 5

	    ENDIF


	    IF typcom=COMBX1 or typcom=COMBX2 or typcom=COMBX3 or typcom=COMSX1

declzx_repcpy	call	declzx_onebyte
		jp	declzx_reuse	;; Jump to declzx_reuse

declzx_repunp	PSALDX			;; Copy one byte
declzx_reuse	push	de
		ld	e,#01
		call	declzx_getegvx	;; sequence length EG+1
		pop	de
		push	bc
declzx_last	ld	bc,#5555	;; Previous used offset
		jp	declzx_copy

declzx_sek	push	de
		ld	e,c
		call	declzx_getegvx	;; Get length of packed sequence (length >= 2^N)
		pop	de
		ret	c		;; If length > 65535 then end of data (end mark)
declzx_push	push	bc		;; Continue to read sequence offset

	    ENDIF


;; Clear carry if needed (some offset readings need CY=0 at begin)

	    IF (typcom >= COMBS2) and (typpos=POSOF1 or typpos=POSOF4 or typpos=POSOV4)
		and	a
	    ENDIF


;; Processing offsets

	    IF typpos=POSOF1
		push	de
		ld	e,ofset1	;; Number of bits of one fixed offset		*** OF1 offset ***
		call	declzx_getnum	;; Read value (C=number of value bits)
		pop	de
		INCOFS			;; Increment offset value (for later sbc hl,bc)

		ASSERT	ofset1 >= 1 and ofset1 <= 16
	    ENDIF


	    IF typpos=POSOF2
		push	de
		ld	bc,#FFFF	;; Set offset to -1				*** OF2 offset ***
		ld	e,ofset2-ofset1	;; We will read N bits, N = difference between bitwidth of offsets
		GETBIT
		call	nc,declzx_getnum ; If longer offset then reading N bits - it is first part of offset
		and	a		;; Clearing carry only (later 'call declzx_getloop' needs it)
		inc	bc		;; Increment offset (-1 => 0, or part of longer offset + 1)
		ld	e,ofset1	;; Number of bits of shorter offset
		call	declzx_getloop	;; Reading bits of offset (next part of longer or entire shorter offset)
		pop	de
		INCOFS			;; Next increment offset value (for later sbc hl,bc)

		ASSERT	ofset1 >= 1 and ofset1 < ofset2 and ofset2 <=16
	    ENDIF


	    IF typpos=POSOF3
		push	de
		ld	d,#01		;; Init counter to 1				*** OF3 offset ***
		ld	bc,#00		;; Init offset to 0
		GETBIT
		jp	nc,declzx_of3set ; Bit 0 => counter 1
		GETBIT
		ld	e,a
		ld	a,d
		rla			;; Bit 1x => counter 2+x
		ld	d,a
		ld	a,e
declzx_of3set	ld	e,ofset1	;; Number of bits of one part of offset
declzx_of3lop	push	de
		call	declzx_getloop	;; Reading part of offset
		pop	de
		inc	bc		;; Increment temporary offset value
		dec	d		;; (it is needed for covering of bigger interval)
		jp	nz,declzx_of3lop ; Repeat for given with of offset
		pop	de

		ASSERT	ofset1 >= 1 and ofset1 <= 5
	    ENDIF


	    IF typpos=POSOF4
		push	de
		ld	e,#02		;; Next two bits means offset width		*** OF4 offset ***
		call	declzx_getnum	;; Reading these two bits from bitstream
		inc	c		;; Adjust two bits to value in range 1..4
		ld	d,c		;; D will be reading offset counter
		ld	c,b		;; Clearing BC for next reading offset value
declzx_of4set	ld	e,ofset1	;; Number of bits of one part of offset
declzx_of4lop	push	de
		call	declzx_getloop	;; Reading part of offset
		pop	de
		inc	bc		;; Increment temporary offset value
		dec	d		;; (it is needed for covering of bigger interval)
		jp	nz,declzx_of4lop;; Repeat for given with of offset
		pop	de

		ASSERT	ofset1 >= 1 and ofset1 <= 4
	    ENDIF


	    IF typpos=POSOV1
		push	de
		call	declzx_getegv0	;; Read Elias-Gamma value (it is enough)	*** OV1 offset ***
		pop	de
	    ENDIF


	    IF typpos=POSOV2
		push	de
		ld	bc,#0000	;; Init offset to 0				*** OV2 offset ***
		GETBIT
		call	c,declzx_getegv0;; Case 1 ... Read Elias-Gamma - only additional variable part
		ld	e,ofset1	;; Number of bits of shorter offset
		call	declzx_getloop	;; Read shorter offset or fixed part of variable offset
		pop	de
		INCOFS			;; Increment offset value for range 1..X

		ASSERT	ofset1 >= 1 and ofset1 <= 14
	    ENDIF


	    IF typpos=POSOV3
		push	de
		ld	bc,#0000	;; Set offset to 0				*** OV3 offset ***
		GETBIT
		jp	nc,declzx_ov3set;; Case 0 ... Jump for 0 to direct read shorter offset
		GETBIT
		call	c,declzx_getegv0;; Case 11 ... Read Elias-Gamma - only additional variable part
		ld	e,ofset2-ofset1	;; We will read N bits, N = difference between bitwidth of offsets
		call	declzx_getloop	;; If longer offset then reading N bits - it is first part of offset
		inc	bc		;; Increment offset here means add value 1 << ofset1 in result
declzx_ov3set	ld	e,ofset1	;; Number of bits of shorter offset
		call	declzx_getloop	;; Reading bits of offset (next part of longer or entire shorter offset)
		pop	de
		INCOFS			;; Final increment offset value for range 1..X

		ASSERT	ofset1 >= 1 and ofset2 <=14 and ofset1 < ofset2
	    ENDIF


	    IF typpos=POSOV4
		push	de
		ld	e,#02		;; Next two bits means offset width		*** OV4 offset ***
		call	declzx_getnum	;; Reading these two bits from bitstream
		ld	d,c		;; D will be reading offset counter
		inc	d		;; Adjust two bits to value in range 1..4
		dec	c		;; Test for case 11 = variable offset
		dec	c
		dec	c
		ld	c,b		;; Clearing BC for next reading offset value
		jp	nz,declzx_ov4set
		push	de
		call	declzx_getegv0
		pop	de
		dec	d
declzx_ov4set	ld	e,ofset1	;; Number of bits of one part of offset
declzx_ov4lop	push	de
		call	declzx_getloop	;; Reading part of offset
		pop	de
		inc	bc		;; Increment temporary offset value
declzx_ov4nxt	dec	d		;; (it is needed for covering of bigger interval)
		jp	nz,declzx_ov4lop;; Repeat for given with of offset
		pop	de

		ASSERT	ofset1 >= 1 and ofset1 <= 5
	    ENDIF


;; Store actual offset for future "reused offset"

	    IF typcom=COMBS2 or typcom=COMBX1 or typcom=COMBX2 or typcom=COMBX3 or typcom=COMSX1
		push	hl
		ld	l,c
		ld	h,b
		ld	(declzx_last+1),hl
		pop	hl
	    ENDIF


;; Copy sequence
;;
;; BC=offset, (SP)=length, DE=destination
;; CY=possible increment of offset in case of revers=0

declzx_copy	ex	(sp),hl		;; Store address to source data and get sequence length
		push	af
		push	hl		;; Store sequence length
		IF revers
		  ld	h,d		;; DE keeps destination address
		  ld	l,e		;; Subtract offset from destination address
		  add	hl,bc
		ELSE
		  ld	a,e		;; hl=de-bc
		  sub	c
		  ld	l,a
		  ld	a,d
		  sbc	a,b
		  ld	h,a
		ENDIF			;; and now HL points to source data of copied sequence
		pop	bc		;; Restore BC = length of copied sequence
		LDXR			;; Copy sequence
		pop	af
		pop	hl		;; Restore address to packed source data

		jp	declzx_main	;; Copy finished and we can continue in next block of data


;; Subroutine for copying one byte
;;
;; Used in:
;;  - direct command for copying one byte
;;  - reused offset with preceded copying one byte

	    IF typcom=COMBX1 or typcom=COMBX2 or typcom=COMBX3 or typcom=COMSX1

declzx_onemain	ld	bc,declzx_main	;; After process, jump to declzx_main
		push	bc
declzx_onebyte	push	de
		or	a
		ld	e,bytcop	;; Bit width of offset for copying standalone bytes
		call	declzx_getnum	;; Read offset from bitstream
		pop	de
		inc	bc
		push	hl		;; Store source address
		push	af
		IF revers
		  ld	h,d		;; DE keeps destination address whole time
		  ld	l,e		;; Subtract offset from destination address
		  add	hl,bc
		ELSE
		  ld	a,e		;; hl=de-bc
		  sub	c
		  ld	l,a
		  ld	a,d
		  sbc	a,b
		  ld	h,a
		ENDIF			;; and now HL points to copied byte in data
		LDX			;; Copying one byte from (HL) do (DE)
		pop	af
		pop	hl		;; Restore source address to packed data
		ret

	    ENDIF


;; Get numeric value from bitstream
;;
;; Note:
;; E is used as bit count instead of C and XL

	      IF typcom=COMBLX or typcom=COMBLC or typcom=COMZX9 or typpos=POSOV1 or typpos=POSOV2 or typpos=POSOV3 or typpos=POSOV4
declzx_getegv0	ld	e,#00		;; Read of Elias-gamma value with no additional bits
	      ENDIF

declzx_getegvx	GETBIT			;; Get bit from bitstream
		inc	e		;; Compute zero bits before value bits
		jp	nc,declzx_getegvx
declzx_getnum	ld	bc,#00		;; Initialize destination value to zero

	    IF lzxspd			;; Speed-optimized GETBIT inlined in code
		jp	c,declzx_getnext;; First CY=1 is needed to rotate into BC always
declzx_getloop	add	a,a		;; Read bit from buffer (A = temporary buffer for bits)
		jp	nz,declzx_getnext; If there were some bits in buffer then return
		ld	a,(hl)		;; Buffer is empty so we must read next byte from bitstream
		adc	a,a		;; MSB bit will be returned reading bit
		INCHL			;; Move to next byte in packed data
	    ELSE
declzx_getloop	call	nc,declzx_getbit;; read bit (slow variant)
	    ENDIF

declzx_getnext	ld	d,a		;; Save bitstream bits into D
		ld	a,c		;; Include bit into destination value
		rla
		ld	c,a
		ld	a,b
		rla
		ld	b,a
		ld	a,d
		ret	c		;; If value > 65535 then return immediately with CY=1
		dec	e		;;   (value > 65535 is usually used as end mark)
		jp	nz,declzx_getloop; Repeat for all needed bits of value
		ret			;; Return with CY=0 (not end mark)


;; Get one bit from bitstream - in case of short variant

	    IF NOT lzxspd
declzx_getbit	add	a,a		;; Reading bit from buffer (A = temporary buffer for bits)
		ret	nz		;; If there were some bits in buffer then return
		ld	a,(hl)		;; Buffer is empty so we must read next byte from bitstream
		adc	a,a		;; LSB bit will be returned reading bit
		INCHL			;; Move to next byte in packed data
		ret
	    ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
