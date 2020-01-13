;; blkjck.asm
;;
;; A game of Black Jack
;;
;; Dealer must hit until >= 17 and then stop
;;
;; (C) 2017 - Michael K. Pellegrino
;;
;; BUGS
;; It's possible to start with 2 aces - hence having a score of 22
;; dealer hits past 17
#include    "ti83plus.inc"
#define     progStart   $9D95
.org        progStart-2
.db         $BB,$6D

	bCall( _RunIndicOff )	; Turn the Run Indicator Off


;; TODO: Look for BANK in Calculator Memory
;; if not found bank is $3000 -- if found load it

	ld a, tTheta
	ld (variabletoken), a
	ld hl, variablename	; look for the variable in the vat
	bCall( _Mov9toOP1 )
	bCall( _FindSym )	; 
	jr c, bank_not_found	;
	ex de, hl
	jr firsttime
bank_not_found:
	bCall( _OP1Set3 )
	bCall( _TenX )
	bCall( _OP2Set3 )
	bCall( _FPMult )
	ld hl, OP1
firsttime:
	ld de, FP_Bank
	call Store9Bytes

	;call getCalcSerial	; 
	;bCall( _RandInit )     ; Seed the Random Number Generator


	
begin:	; $34 = 52 decimal

	call cls

	ld hl, text_title	; Title Screen
	bCall( _PutS )		; Title Screen
	bCall( _NewLine )	; Title Screen
	call pressanykey	; Title Screen
begin0p5:
	call cls
	call shuffle		; Shuffle the Deck
	call sort		; Shuffle the Deck

	xor a
	ld (hand_count), a
	ld (top_card),a		; Set the top card to the first card

begin1:
	xor a			; Wipe out the natural blackjacks
	ld (plyNat), a
	ld (dlrNat), a

	; Shuffle every 38 cards
	ld a, (top_card)
	cp $26
	jr nc, begin0p5
	
	;; Shuffle every 3 hands	
	;ld a, (hand_count)
	;inc a
	;ld (hand_count), a
	;cp $04
	;jr z, begin0p5
	
;; clear out the hands
	
	ld bc, $33		; Clear out 51 Bytes of Memory
	ld hl, dealer_hand
	bCall( _MemClear )	
	xor a			; Set the top card to the first card
	ld (playerBust), a
	ld (playerDone), a
	ld (player21), a
begin1p5:
	call cls
	ld hl, FP_Bank
	rst $0020
	bCall( _ZeroOP2 )
	bCall( _CpOP1OP2 )
	jp z, out_of_funds
;; TODO: If bank is 0 then show register screen
	ld hl, text_bank	; Display Bank
	bCall( _PutS )		; Display Bank
	ld hl, FP_Bank		; Display Bank
	rst  $0020		; Display Bank bCall( _Mov9toOP1 )
	call dispOP1		; Display Bank

;;; TODO: If Bank is < 5 then set minumum to Bank
;;; otherwise Minimum = 5
	
	ld hl, text_minimum	; Display Minumum Bet
	bCall( _PutS )		; Display Minumum Bet
	ld hl, FP_minimum	; Display Minumum Bet
	rst $0020		; Display Minumum Bet
	call dispOP1		; Display Minumum Bet
	bCall( _NewLine )
	
	ld hl, text_prompt	; Display prompt
	bCall( _PutS )		; Display prompt

;;; TODO: Turn the blinking cursor on here
	call getuserinput	; get user input

	
	ld hl, FP_bfr
	ld de, FP_bet
	call Store9Bytes

	
	;;  if they bet 0 then quit
	ld hl, FP_bet
	rst $0020
	bCall( _ZeroOP2 )
	bCall( _CpOP1OP2 )
	jp z, end

	;; if they bet less than the minimum then try again
	bCall( _OP2Set5 )
	bCall( _CpOP1OP2 )
	jp c, betmore

	;; if they bet more than they have then try again
	ld hl, FP_bet
	bCall( _Mov9toOP2 )
	ld hl, FP_Bank
	rst $0020
	bCall( _CpOP1OP2 )
	jp c, betless

	
	
	bCall( _NewLine )
	bCall( _NewLine )

;; DEAL THE First 2 CARDS HERE
	ld hl, player_hand
	ld (deal_to), hl
	call deal
	ld hl, dealer_hand
	ld (deal_to), hl
	call deal
	ld hl, player_hand
	ld (deal_to), hl
	call deal
	ld hl, dealer_hand
	ld (deal_to), hl
	call deal
	


;; check for black jack here
;; check dealer first
	ld hl, dealer_hand
	ld (hand_to_get), hl
	call getHandValue
	ld a, (hand_value)
	ld b, $15
	cp b
	call z, dealerNatural
	ld a, $15
	ld (value_dlr), a

	ld hl, player_hand
	ld (hand_to_get), hl
	call getHandValue
	ld a, (hand_value)
	ld b, $15
	cp b
	call z, playerNatural
	ld a, $15
	ld (value_plr), a

	ld a, (plyNat)
	ld b, a
	ld a, (dlrNat)
	add a,b

	;push af			; DEBUG
	;ld h, $00
	;ld l, a
	;bCall( _DispHL )
	;bCall( _NewLine )
	;bCall( _GetKey )
	;pop af

	
	cp $11
	jp z, naturalPush
	cp $01
	jp z, naturalLoss
	cp $10
	jp z, naturalWin

	
	
	

	

	
	ld hl, dealer_initial_hand
	ld (which_dealer_hand), hl 

;; Mask out one of the Dealer's Cards
	ld hl, dealer_hand
	ld de, dealer_initial_hand
	ld bc, $0003
	ldir
	ld hl, dealer_initial_hand+3
	ld (hl), 'X'
	inc hl
	ld (hl), 'X'
	inc hl
	ld (hl), $00

begin2:
	call cls
	call dispHands
	ld a, (playerDone)
	cp $01
	jr z, dealersTurn
	
	ld hl, text_menu_condensed
	bCall( _PutS )
begin3:
	bCall( _GetKey )
	
	cp $49			; Check for [F1] (hit)
	jp z, hit		; hit
	;cp $48			; Check for [F2] (double)
	;jp z, end		; double
	;cp $2E			; Check for [F3] (split)
	;jp z, end		; split
	cp $5A			; Check for [F4] (quit)
	jp z, end		; end
	cp $44			; Check for [F5] (Stand)
	jp z, stand		; stand
	jr begin3		; key not recognized-- get another
	
	ld a, (top_card)
	cp $34
	jp z, begin
	jp begin1

	
dealersTurn:
	ld hl, dealer_hand

	ld (which_dealer_hand), hl 
	ld (deal_to), hl
	ld (hand_to_check), hl
	
	ld a, (playerBust)	; if player busted - dealer wins
	cp $01			;
	jp z, dealerWin	;

dealersTurn0:
	call cls
	call dispHands

;;; now check to see if dealer has 17 or more
;;; if so--- dealer stands
;;; if not--- dealer hits
	ld hl, dealer_hand
	ld (hand_to_get), hl
	call getHandValue

	;push hl
	;push af
	;bCall( _NewLine )
	;ld h, $00
	;ld a, (hand_value)
	;ld l, a
	;bCall( _DispHL )
	;bCall( _GetKey )
	;bCall( _NewLine )
	;pop af
	;pop hl
	
	ld a, (hand_value)
	ld b, a
	ld a, $15
	cp b
	call c, change_one_11_to_a_1

	ld hl, dealer_hand
	ld (hand_to_get), hl
	call getHandValue
	ld a, (hand_value)
	ld b, a
	ld a, $15		; bust if over 21
	cp b
	jr c, dealerLoss

	ld b, $11		; stop at 17 or up
	ld a, (hand_value)
	cp b
	jr c, hit_then_top
	jr dealer_stands
hit_then_top:
	call deal
	jr dealersTurn0
dealer_stands:			; no more cards- now compare hands
	
	call getHandValue
	ld a, (hand_value)
	ld (value_dlr), a

	ld hl, player_hand
	ld (hand_to_get), hl
	call getHandValue
	ld a, (hand_value)
	ld (value_plr), a

	ld b, a
	ld a, (value_dlr)
	cp b
	jp z, tie
	jr c, dealerLoss
	
dealerWin:
	ld hl, text_dealer_wins
	bCall( _PutS )
	bCall( _NewLine )
	call pressanykey

	;; decrease bank
	ld hl, FP_bet
	bCall( _Mov9toOP2 )
	ld hl, FP_Bank
	rst $0020
	bCall( _FPSub )
	ld hl, OP1
	ld de, FP_Bank
	call Store9Bytes

	jp begin1
	
dealerLoss:
	ld hl, text_player_wins
	bCall( _PutS )
	bCall( _NewLine )
	call pressanykey

;; increase bank
	ld hl, FP_bet
	bCall( _Mov9toOP2 )
	ld hl, FP_Bank
	rst $0020
	bCall( _FPAdd )
	ld hl, OP1
	ld de, FP_Bank
	call Store9Bytes

	jp begin1
text_dlr_blackjack:
.db "Dealer has      Blackjack!",0
text_ply_blackjack:
.db "Player has      Blackjack!",0
text_both_blackjack:
.db "You both have   Blackjack!",0

text_nw:
.db "natural win",0
text_nl:
.db "natural loss",0



naturalLoss:
	;ld hl, text_nl
	;bCall( _PutS )
	;bCall( _GetKey )
	;bCall( _NewLine )

	call dispHands
	bCall( _NewLine )
	;bCall( _GetKey )

	ld hl, text_dlr_blackjack

	bCall( _PutS )
	bCall( _NewLine )
	;call pressanykey
	
	jp dealerWin
naturalWin:
	
	;ld hl, text_nw
	;bCall( _PutS )
	;bCall( _GetKey )
	;bCall( _NewLine )
	
	call dispHands
	bCall( _NewLine )
	;bCall( _GetKey )

	
	ld hl, text_ply_blackjack
	bCall( _PutS )
	bCall( _NewLine )

	
;;; TODO: Make the bet = to the Bet* 1.5

	bCall( _OP1Set3 )
	bCall( _TimesPt5 )
	bCall( _OP1toOP2 )
	ld hl, FP_bet
	rst $0020
	;bCall( _Mov9toOP1 )
	bCall( _FPMult )
	ld d, $02
	bCall( _Round )
	ld hl, OP1
	ld de, FP_bet
	call Store9Bytes
	
	jp dealerLoss
naturalPush:
	call dispHands
	ld hl, text_both_blackjack
	bCall( _PutS )
	bCall( _NewLine )
	bCall( _GetKey )
	
	

tie:
	ld hl, text_push
	bCall( _PutS )
	bCall( _NewLine )
	call pressanykey
	jp begin1
	
end:
	bCall( _NewLine )
;; save stats here

	ld a, tTheta
	ld hl, FP_Bank
	call storeVariable
	
	bCall( _RunIndicOn )	; go back to showing the Run Indicator
	ret
betmore:
	ld hl, text_bet_more
betmore0:
	bCall( _NewLine )
	bCall( _PutS )
	bCall( _NewLine )
	call pressanykey
	jp begin1p5

betless:
	ld hl, text_bet_less
	jp betmore0

text_bet_less:
;;;; 1234567890123456	
.db "That's more thanyou have",0
text_bet_more:
.db "Min Bet is 5",0
text_player_wins:
.db "You Win!", 0
text_dealer_wins:
.db "Dealer Wins!", 0
text_push:
.db "Push", 0

plyNat:
.db $00
dlrNat:
.db $00

dealerNatural:
	push hl
	push af
	push bc
	push de
	ld a, $01
	ld (dlrNat), a
	pop de
	pop bc
	pop af
	pop hl
	ret
playerNatural:
	push hl
	push af
	push bc
	push de
	ld a, $10
	ld (plyNat), a
	pop de
	pop bc
	pop af
	pop hl
	ret
	

hit:

	
	ld hl, player_hand
	ld (deal_to), hl
	call deal
	bcall ( _NewLine )

hit0:
	call getHandValue	; %%%%
	ld a, (hand_value)
	ld b, a
	ld a, $15
	cp b			; compare the value of the hand with 21
	jr z, twentyone		; 21!
	jr c, bust		; bust!

	call getHandValue	; %%%%
	ld a, (hand_value)
	ld b, a
	ld a, $15
	cp b			; compare the value of the hand with 21
	jr c, bust		; bust!



	
;;; at this point we need to:
;;;
;;; check if score > 21
;;; by creating a function that
;;; just calculates the value
;;; of a hand w/o displaying it

hit_end:
	jp begin2
	
twentyone:
	ld a, $01
	ld (playerDone), a
	jp begin2

bust:
;;; IF score > 21 then
;;; check for an ace (0B)
;;; IF one is found then
;;; change it to a value
;;; of 1 and continue playing
;;; IF no ace is found
;;; then it's a loss for
;;; the player
	ld hl, (deal_to)
bust_top:
	ld a, (hl)
	cp $00
	;or a			; check for no more cards in hand
	jp z, bust_end
	inc hl
	inc hl
	ld a, (hl)
	cp $0B			; compare the value of the card with 11
	jr nc, found_an_11	; found an 11, change it to a 1
	inc hl
	jp bust_top
found_an_11:
	ld a, $01
	ld (hl), a
	jp hit_end
bust_end:
	ld a, $01
	ld (playerDone), a
	ld (playerBust), a
	jp hit_end
	
stand:				; NOT NEEDED
;;; deal to dealer until >= 17
	ld a, $01
	ld (playerDone), a
	jp begin2
	
dispHands:
	push hl
	push af
	push bc
;;; =========================
	call cls
	ld a, $01
	ld (show_value), a
	
	ld hl, text_player_hand
	bCall( _PutS )
	ld hl, player_hand
	ld (hand_to_display), hl
	call dispHand
	
	xor a
	ld (show_value), a
	
	ld hl, text_dealer_hand
	bCall( _PutS )
	ld hl, (which_dealer_hand)
	ld (hand_to_display), hl
	call dispHand



;;; =========================
	pop bc
	pop af
	pop hl
	ret

dispkeys:
	bCall( _NewLine )
	ld hl, text_stand
	push hl
	ld hl, text_quit
	push hl
	ld hl, text_split
	push hl
	ld hl, text_double
	push hl
	ld hl, text_hit
	push hl
	
	ld b, $05
dispkeys0:
	pop hl
	bCall( _PutS )
	bCall( _NewLine )
	djnz dispkeys0
	ret
	
shuffle:
	ld hl, text_shuffling
	bCall( _PutS )
	bCall( _NewLine )

	ld hl, deck_of_cards
	ld c, $00
	ld b, $34
shuffle0:
	push bc

	push af
	push hl
	
	bCall( _Random )
	ld hl, FP_250
	bCall( _Mov9toOP2 )
	bCall( _FPMult )
	bCall( _Int )
	bCall( _ConvOP1 )
	ld (randbyte), a

	pop hl
	pop af

	ld a, (randbyte)
	ld (hl), a
	inc hl
	inc hl
	inc hl
	inc hl
	pop bc
	djnz shuffle0
	ret
sort:
	ld c,$34	; 52 cards
	dec c		; Note that the first step involves N-1 checks
	ld hl,$0001
sort0:
	ld ix, deck_of_cards
	ld e,h                         ; Bit 0 of E will indicate if there was need to swap
	ld b,c                         ; C holds the number of elements in the current step
sort1:

	ld a,(ix)
	ld d,(ix+4)
	cp d                           ; If A was less than D, the carry will be set
	jr c, sort2

	push hl
	push af

	; save the second card to the buffer
	ld hl, sort_bfr

	ld a, (ix+4)
	ld (hl), a
	inc hl
	ld a, (ix+5)
	ld (hl), a
	inc hl
	ld a, (ix+6)
	ld (hl), a

	; copy first card to second card
	ld a, (ix)
	ld (ix+4), a
	ld a, (ix+1)
	ld (ix+5), a
	ld a, (ix+2)
	ld (ix+6), a
	
	ld hl, sort_bfr
	ld a, (hl)
	ld (ix), a
	inc hl
	ld a, (hl)
	ld (ix+1), a
	inc hl
	ld a, (hl)
	ld (ix+2), a
	pop af
	pop hl
	ld e,l                         ; Swapping is indicated here (L=1)
sort2:
	inc ix
	inc ix
	inc ix
	inc ix
	djnz sort1
	dec e
	jr nz, sort3                   ; If E became zero after DEC, we have to continue
	dec c
	jr nz, sort0
sort3:
	ret

change_one_11_to_a_1:
	push hl
	push af
	push de
	push bc
;;; ==========================
	ld hl, (hand_to_check)
change_one_11_to_a_1_0:
	ld a, (hl)
	cp $00
	;or a			; check for no more cards in hand
	jp z, change_one_11_to_a_1_end
	inc hl
	inc hl
	ld a, (hl)
	cp $0B			; compare the value of the card with 11
	jr nc, change_one_11_to_a_1_a	; found an 11, change it to a 1
	inc hl
	jp change_one_11_to_a_1_0
change_one_11_to_a_1_a:
	ld a, $01
	ld (hl), a
change_one_11_to_a_1_end:
;;; ==========================
	pop bc
	pop de
	pop af
	pop hl
	ret
hand_to_check:
.dw $0000

dispCard:
	push hl
	push af
	ld hl, deck_of_cards
	ld a, (top_card)
;; Multiply it by 4
	sla a
	sla a
	ld c, a
	ld b, $00
	add hl, bc		; Move pointer to the (cardNum)th card

	inc hl
	ld a, (hl)
	ld (top_card_face), a

	cp 'K'
	call z, cardK
	cp 'Q'
	call z, cardQ
	cp 'J'
	call z, cardJ
	cp 'T'
	call z, cardT
	cp '9'
	call z, card9
	cp '8'
	call z, card8
	cp '7'
	call z, card7
	cp '6'
	call z, card6
	cp '5'
	call z, card5
	cp '4'
	call z, card4
	cp '3'
	call z, card3
	cp '2'
	call z, card2
	cp 'A'
	call z, cardA

	ld (top_card_value), a

	inc hl			
	ld a, (hl)
	ld (top_card_suit), a
	
	ld a, (top_card)	; point to next card
	inc a
	ld (top_card), a
	pop af
	pop hl
	ret
cardK:
cardQ:
cardJ:
cardT:
	ld a, $0A
	ret
card9:
	ld a, $09
	ret
card8:
	ld a, $08
	ret
card7:
	ld a, $07
	ret
card6:
	ld a, $06
	ret
card5:
	ld a, $05
	ret
card4:
	ld a, $04
	ret
card3:
	ld a, $03
	ret
card2:
	ld a, $02
	ret
cardA:
	ld a, $0B		; initially count aces as 11-- if score > 21 then change to a 1
	ret


	
top_card_suit:
.db $00
top_card_face:
.db $00
top_card_value:
.db $00

;; function - pressanykey
pressanykey:
	ld hl, text_pressanykey
	bCall( _PutS )
	bCall( _GetKey )
	bCall( _NewLine )
	ret

getuserinput:
	push hl
	push af
	push bc
	push de

	bCall( _CursorOn )
	xor a
	ld (text_buffer_length), a
	
	ld hl, text_buffer
	ld (text_buffer_ptr), hl
	
readmore:
	call readkeyA
	ld a, (text_buffer_length)
	cp $18
	jp z, buffer_filled
	
	ld a, (readkeyA_byte)
	or a
	jp z, buffer_filled
	jp readmore 

buffer_filled:
	ld a, (text_buffer_length) ; take the last byte off of the equation
	dec a
	ld (text_buffer_length), a
	call create_equation

	ld hl, equationName
	ld de, OP1
	ld bc, $04
	ldir
	bCall( _ParseInp )
	ld hl, OP1
	ld de, FP_bfr
	ld bc, $09
	ldir

	; Delete the equation from memory
	ld hl, equationName	; look for the variable in the vat
	bCall( _Mov9toOP1 )	; using its name (FP_VA)
	bCall( _FindSym )	; 
	bCall( _DelVar )	; and delete it from the VAT
	bCall( _CursorOff )

	
	pop de
	pop bc
	pop af
	pop hl
	ret

readkeyA:
	push af
	push hl
readkeyA0:
	bCall(_GetCSC)		; read the keyboard
	or a			; cp a, $00
	jp z, readkeyA0
	cp sk0
	jp z, readkeyA_zero
	cp sk9
	jp z, readkeyA_nine
	cp sk8
	jp z, readkeyA_eight
	cp sk7
	jp z, readkeyA_seven
	cp sk6
	jp z, readkeyA_six
	cp sk5
	jp z, readkeyA_five
	cp sk4
	jp z, readkeyA_four
	cp sk3
	jp z, readkeyA_three
	cp sk2
	jp z, readkeyA_two
	cp sk1
	jp z, readkeyA_one
	cp skEnter
	jp z, readkeyA_cr
	cp skDecPnt
	jp z, readkeyA_decpt
	cp skLeft
	jp z, readkeyA_backspace
	cp skDel
	jp z, readkeyA_backspace
	jp readkeyA0

readkeyA1:
	bCall( _PutC )
readkeyA2:
	ld (readkeyA_byte), a
	ld hl, (text_buffer_ptr)
	ld (hl), a
	inc hl
	ld (text_buffer_ptr), hl

	ld a, (text_buffer_length)
	inc a
	ld (text_buffer_length), a
	
	pop hl
	pop af
	ret
readkeyA_zero:
	ld a, $30
	jp readkeyA1
readkeyA_nine:
	ld a, $39
	jp readkeyA1
readkeyA_eight:
	ld a, $38
	jp readkeyA1
readkeyA_seven:
	ld a, $37
	jp readkeyA1
readkeyA_six:
	ld a, $36
	jp readkeyA1
readkeyA_five:
	ld a, $35
	jp readkeyA1
readkeyA_four:
	ld a, $34
	jp readkeyA1
readkeyA_three:
	ld a, $33
	jp readkeyA1
readkeyA_two:
	ld a, $32
	jp readkeyA1
readkeyA_one:
	ld a, $31
	jp readkeyA1
readkeyA_cr:
;; check to see if this is the first byte-- if it is
;; then do nothing
	ld a, (text_buffer_length) ; if text length = 0 just return
	or a
	jp z, readkeyA0
	
	ld a, $00
	jp readkeyA2
readkeyA_decpt:
	ld a, '.'
	bCall( _PutC )
	ld a, tDecPt
	jp readkeyA2
readkeyA_backspace:
	ld a, (text_buffer_length) ; if text length = 0 just return
	or a
	jp z, readkeyA0
	
;; ;; ; otherwise
	dec a
	ld (text_buffer_length), a

	push af
	ld a, (CurCol)
	dec a
	ld (CurCol),a
	ld a, ' '
	bCall(_PutC)
	ld a, (CurCol)
	dec a
	ld (CurCol),a
	pop af

	push hl
	ld hl, (text_buffer_ptr)
	dec hl
	ld (text_buffer_ptr), hl
	pop hl
	jp readkeyA0
	
create_equation:
	ld hl, equationName	; look for the variable in the vat
	bCall( _Mov9toOP1 )	; using its name (FP_VA)
	bCall( _FindSym )	; 
	jr c, storeEqu		; if it isn't found then create it	
	bCall( _DelVar )	; and delete it from the VAT
storeEqu:
	ld a, (text_buffer_length)
	ld h, $00
	ld l, a			; Bytes of Memory needed to store it
	bCall( _CreateEqu ) 	; de is returned
	inc de
	inc de
	ld hl, text_buffer	; Point hl to start of Text Buffer
	ld a, (text_buffer_length)
	ld b, $00
	ld c, a			; Bytes of Memory needed to store it
	ldir			; copy it to the VAT
	ret

deal:				; DE should point to either player_hand or dealer_hand
	push hl
	push de
	push af
	push bc
;;;================================
	ld hl, (deal_to)
deal0:
	ld a, (hl)
	or a			; cp $00 (but faster)
	jr z, empty_spot
	inc hl
	inc hl
	inc hl
	jr deal0
empty_spot:
	call dispCard
	ld a, (top_card_face)
	ld (hl), a
	inc hl
	ld a, (top_card_suit)
	ld (hl), a
	inc hl
	ld a, (top_card_value)
	ld (hl), a
;;;================================
	pop bc
	pop af
	pop de
	pop hl
	ret

deal_to:
.dw $0000

dispHand:			; hl should point to which hand
	push hl
	push de
	push af
	push bc
;;;================================
	ld hl, (hand_to_display)
dispHand0:
	ld a, (hl)
	or a			; a faster cp $00
	jr z, dispHand9		; if card is null, goto end of loop
	
	bCall( _PutC )		; display face
	inc hl
	ld a, (hl)
	bCall( _PutC )		; display suit
	inc hl
	ld a, ' '
	bCall( _PutC )		; display a space
	inc hl			; Point to next card in the hand
	jr dispHand0		; goto top of loop


;;;================================
dispHand9:
	ld a, (show_value)
	or a
	jr z, dispHandA		; If Not Equal return

	ld hl, (hand_to_display)
	ld (hand_to_get), hl
	
	call getHandValue
	
	;bCall( _NewLine )
	;ld hl, text_value
	;bCall( _PutS )

	;ld a, (hand_value)
	;ld h, $00
	;ld l, a
	;bCall( _DispHL )
	
dispHandA:
	bCall( _NewLine )
	bCall( _NewLine )
	pop bc
	pop af
	pop de
	pop hl
	ret

getHandValue:			
	push hl
	push de
	push af
	push bc
	xor a
	ld (hand_value), a   ; clear out hand_value
	ld hl, (hand_to_get)	; value of player's hand? or dealer's hand?
getHandValue0:
	ld a, (hl)
	or a			; a faster cp $00
	jr z, getHandValueret	; so - if the first card is zero - just return
	inc hl 			; skip suit and face value
	inc hl
	ld a, (hand_value)
	ld b, a
	ld a, (hl)
	add a,b
	ld (hand_value), a
	inc hl			; Point to next card in the hand
	jr getHandValue0
getHandValueret:
	pop bc
	pop af
	pop de
	pop hl
	ret

	

cls:
	push af
	push hl
	xor a			; CLS
	ld (CurCol),a		; CLS
	ld (CurRow),a		; CLS
	bCall( _ClrLCDFull )	; CLS
	bCall( _ClrScrn )	; CLS
	pop hl
	pop af
	ret

;;; FUNCTION Store9Bytes
Store9Bytes:			; DE = Dest Addr, HL = Src Addr
	ld (store9_hl), hl
	ex de, hl
	ld (store9_de), hl
	push hl
	push de
	push bc
	ld hl, (store9_hl)
	ld de, (store9_de)
	ld bc, $09
	ldir
	pop bc
	pop hl			; Switched the order here because I did an
	pop de			; exchange at the beginning of the func.
	ret


;text_value:
;.db "Score:",0
	
show_value:			; Default is to not show
.db $00
	
hand_to_display:
.dw $0000
hand_to_get:
.dw $0000

hand_value:
.db $00
	
dispOP1:			
	ld a, $06
	bCall( _FormReal )	
	ld hl, OP3		
	bCall( _PutS )		
	bCall( _NewLine )	
	ret

out_of_funds:
	ld hl, text_no_funds_screen
	bCall( _PutS )
	bCall( _NewLine )
	ld hl, text_pressanykey
	bCall( _PutS )
	bCall( _GetKey )
	jp end

getCalcSerial:
	push af
	push bc
	push de
	push hl
	bCall( $8073 )
	ld hl, OP4
	ld de, calc_serial_number
	ld bc, $0005
	ldir
	pop hl
	pop de
	pop bc
	pop af
	ret

calc_serial_number:
.db $00, $00, $00, $00, $00
	
;debugText:
;	push hl
;	push de
;	push af
;	push bc
;	ld hl, text_debug
;	bCall( _PutS )
;	bCall( _NewLine )
;	bCall( _GetKey )
;	pop bc
;	pop af
;	pop de
;	pop hl
;
;	ret
;
;text_debug:			
;.db "---",0

storeVariable:
	ld (variabletoken), a
	ld de, variabledata
	ld bc, $09
	ldir
	
	push hl
	push de
	push bc
	ld hl, variablename	; look for the variable in the vat
	bCall( _Mov9toOP1 )	; using its name (FP_VA)
	bCall( _FindSym )	; 
	jr c, storeVAR		; if it isn't found then create it
	
	bCall( _DelVar )	; and delete it from the VAT
storeVAR:
	ld hl, $09		; Bytes of Memory needed to store it
	bCall( _CreateReal ) 	; de is returned	
	ld hl, variabledata	; Point hl to start of Variable 
	ld bc, $09		; Bytes of Memory needed to store it
	ldir			; copy it to the VAT

	; clear out token
	xor a
	ld (variabletoken), a

	pop bc
	pop de
	pop hl
	ret

variablename:
.db RealObj
variabletoken:
.db $00, $00, $00
	
variabledata:
.db $00, $00, $00, $00, $00, $00, $00, $00, $00

recallAppVar:
;; a is the tokenized name
;; OP1 gets recalled
;; if (appvarname) is Tokenized name then it wasn't found
	ld (appvarname), a
	push hl
	push de
	push bc
	ld hl, appvar
	rst $0020
	bCall( _ChkFindSym )
	jr c, recallAppVar1
	ex de, hl
	inc hl
	inc hl
	ld de, appvardata
	ld bc, $0009
	ldir
	ld hl, appvardata
	rst $0020
	xor a
	ld (appvarname), a

recallAppVar1:

	pop bc
	pop de
	pop hl

	ret
	
storeAppVar:
;; a is the tokenized name
;; OP1 gets stored
	ld (appvarname), a
	ld hl, OP1
	ld de, appvardata
	ld bc, $09
	ldir
	
	push hl
	push de
	push bc
	ld hl, appvar		; look for the variable in the vat
	rst $0020	
	bCall( _ChkFindSym )	; 
	jr c, storeVAR		; if it isn't found then create it
	bCall( _DelVar )	; and delete it from the VAT
storeVAR:
	ld hl, appvar		; look for the variable in the vat
	rst $0020
	ld hl, $000B		; Bytes of Memory needed to store data plus a 2 bytes size
	bCall( _CreateAppVar ) 	; de is returned
	ld hl, appvardata	; Point hl to start of Variable
	inc de
	inc de
	ld bc, $0009		; Bytes of Memory needed to store data
	ldir			; copy it to the VAT

	; clear out token
	xor a
	ld (appvarname), a

	pop bc
	pop de
	pop hl
	ret
appvar:
.db AppVarObj
.db tSpace
.db tB, tJ
appvarname:
.db $00, $00, $00, $00, $00, $00
appvardata:
.db $00, $00, $00, $00, $00, $00, $00, $00, $00

	
;; DATA SECTION

value_dlr:
.db $00
value_plr:
.db $00

text_menu_condensed:
.db $C1,"Y=]     ",$C1,"Graph]"
.db " Hit       Stand",$00
	

which_dealer_hand:
.dw $0000
	
text_dealer_hand:
.db "Dlr:",0

dealer_hand:
;;; Suit|Face|Value
.db $00, $00, $00
.db $00, $00, $00
.db $00, $00, $00
.db $00, $00, $00
.db $00, $00, $00
.db $00, $00, $00
.db $00, $00, $00, $00

dealer_initial_hand:
.db $00, $00, $00
.db $00, $00, $00, $00

player_hand:
;;; Suit|Face|Value
.db $00, $00, $00
.db $00, $00, $00
.db $00, $00, $00
.db $00, $00, $00
.db $00, $00, $00
.db $00, $00, $00
.db $00, $00, $00, $00

text_player_hand:
.db "You:",0

	
text_title:
.db "  Single Deck      Black Jack   by mr pellegrino================",0
cardNum:
.db $00
	
sort_bfr:
.db $00, $00, $00

top_card:
.db $00
	
text_shuffling:
.db "Shuffling...",0

text_no_funds_screen:
;;;  1234567890123456
.db "OUT OF MONEY!!!!"
.db "visit: mkpelleg."
.db "freeshell.org/  "
.db "blackjack.html  "
.db "1: Enter Code   "
.db "0: Quit",0
text_register_id:
.db "Reg ID:",0
text_register_code:
.db "Reg Code:",0
	
text_menu:
text_hit:
.db $C1,"F1] Hit",0
text_stand:
.db $C1,"F5] Stand",0
text_split:
.db $C1,"F3] Split",0
text_double:
.db $C1,"F2] Double",0
text_quit:
.db $C1,"F4] Quit",0
text_bank:
.db "Bank: ",0
text_prompt:
.db "Enter 0 to quit "
.db "Enter Bet: ",0
text_minimum:
.db "Min Bet: ",0
	
text_pressanykey:
.db "(press any key)",0

FP_bfr:
.db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
		
store9_hl:
.dw $0000
store9_de:
.dw $0000

readkey_byte:
.db $00
readkeyA_byte:
.db $00


equationName:
.db EquObj, tVarEqu, tY3, $00
	
text_buffer_length:
.db $00				; out of $18
	
text_buffer_ptr:
.dw $0000
	
text_buffer:			; $18 byte buffer
.db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

FP_bet:
.db $00, $80, $50, $00, $00, $00, $00, $00, $00, $00, $00


FP_minimum:
.db $00, $80, $50, $00, $00, $00, $00, $00, $00, $00, $00
FP_bank:
.db $00, $82, $25, $00, $00, $00, $00, $00, $00, $00, $00

;; Floating Point 250
FP_250:
.db $00, $82, $25, $00, $00, $00, $00, $00, $00, $00, $00

parentheses_text:
.db ") ",0
	
randbyte:
.db $00

cardsDealt:
.db $00

playerDone:
.db $00

playerBust:
.db $00

player21:
.db $00

hand_count:
.db $00

deck_of_cards:
.db $00,"AS",$00
.db $00,"2S",$00
.db $00,"3S",$00
.db $00,"4S",$00
.db $00,"5S",$00
.db $00,"6S",$00
.db $00,"7S",$00
.db $00,"8S",$00
.db $00,"9S",$00
.db $00,"TS",$00
.db $00,"JS",$00
.db $00,"QS",$00
.db $00,"KS",$00

.db $00,"AC",$00
.db $00,"2C",$00
.db $00,"3C",$00
.db $00,"4C",$00
.db $00,"5C",$00
.db $00,"6C",$00
.db $00,"7C",$00
.db $00,"8C",$00
.db $00,"9C",$00
.db $00,"TC",$00
.db $00,"JC",$00
.db $00,"QC",$00
.db $00,"KC",$00

.db $00,"AD",$00
.db $00,"2D",$00
.db $00,"3D",$00
.db $00,"4D",$00
.db $00,"5D",$00
.db $00,"6D",$00
.db $00,"7D",$00
.db $00,"8D",$00
.db $00,"9D",$00
.db $00,"TD",$00
.db $00,"JD",$00
.db $00,"QD",$00
.db $00,"KD",$00

.db $00,"AH",$00
.db $00,"2H",$00
.db $00,"3H",$00
.db $00,"4H",$00
.db $00,"5H",$00
.db $00,"6H",$00
.db $00,"7H",$00
.db $00,"8H",$00
.db $00,"9H",$00
.db $00,"TH",$00
.db $00,"JH",$00
.db $00,"QH",$00
.db $00,"KH",$00
