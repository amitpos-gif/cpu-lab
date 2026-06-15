data segment:	;DTCM content
arr dc16 63,542,245,190,91,86,78,64,83,16,24,62,79,19
arr_odds dc16 0
arr_evens dc16 0

code segment:	;ITCM content
mov r1,arr        ; pointer to arr[i]
mov r2,arr_odds   ; address of arr_odds (scalar)
mov r3,arr_evens  ; address of arr_evens (scalar)
mov r4,0          ; i
mov r5,1          ; constant 1
mov r6,14         ; limit

ld r7,0(r1)       ; arr[i]

and r9,r7,r5      ; r9 = arr[i] & 1   (LSB: 1=odd, 0=even)
sub r11,r9,r5     ; compare r9 with 1
jlo 4             ; if r9 < 1 -> even -> jump to EVEN case

; odd case: arr_odds = arr_odds + arr[i]
ld r10,0(r2)
add r10,r10,r7
st r10,0(r2)
jmp 3             ; skip EVEN case

; even case: arr_evens = arr_evens + arr[i]
ld r10,0(r3)
add r10,r10,r7
st r10,0(r3)

add r1,r1,r5      ; arr pointer++
add r4,r4,r5      ; i++

sub r10,r4,r6     ; compare i with 14
jlo -15           ; if i < 14, go back to ld r7,0(r1)

done
nop
jmp -2