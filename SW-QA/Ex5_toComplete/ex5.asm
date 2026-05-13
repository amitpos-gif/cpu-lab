data segment:	;DTCM content
arr1 dc16 63,542,245,190,91,86,78,64,83,16,24,62,79,19
arr2 dc16 13,312,141,160,92,88,71,63,59,14,43,12,71,90
res ds16 14

code segment:	;ITCM content
mov r1,arr1
mov r2,arr2
mov r3,res
mov r4,0      ; i
mov r5,1      ; constant 1
mov r6,14     ; limit

ld  r7,0(r1)      ; arr1[i]
ld  r8,0(r2)      ; arr2[i]

and r9,r4,r5      ; r9 = i & 1
sub r11,r9,r5     ; compare r9 with 1
jlo 3             ; if r9 < 1 -> even -> jump to SUB

; odd case: res[i] = arr1[i] + arr2[i]  r10 = res [i]
add r10,r7,r8
st r10,0(r3)
jmp 2             ; skip SUB case

; even case: res[i] = arr1[i] - arr2[i]
sub r10,r7,r8
st r10,0(r3)

add r1,r1,r5      ; arr1 pointer++
add r2,r2,r5      ; arr2 pointer++
add r3,r3,r5      ; res pointer++
add r4,r4,r5      ; i++

sub r10,r4,r6     ; compare i with 14
jlo -15           ; if i < 14, go back to ld r7,0(r1)

done
nop
jmp -2