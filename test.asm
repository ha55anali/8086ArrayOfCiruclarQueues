jmp start

%define rowSize 16
%define colSize 32

%define startIndex 2*colSize-4
%define endIndex 2*colSize-2

%define totalCells rowNo*colSize
	FreeQueue: dw 0xFFFF
	arr: times 512 dw 0
%undef totalCells

[org 0x100]

start:
mov bx,FreeQueue
mov cx,30
try:
	push 0
	push arr
	push 0
	push 10
	call qAdd
	pop ax
loop try

mov cx,30
try2:
	push 0
	push arr
	push 1
	push 10
	call qAdd
	pop ax
loop try2

push 0
push word [FreeQueue]
call qcreate
pop ax




getEl: ;element& (arr&,row col)
	push bp
	mov bp,sp
	pusha

	;get col size
	mov ax,colSize;size of col
	mul word [bp+6]
	
	add ax, [bp+8];arr base address
	add ax, [bp+4];col number

	mov [bp+10],ax ;put in return var
	
	popa
	pop bp
	ret 6

incIndex: ;index(index&)
	push bp
	mov bp,sp
	pusha

	;increment index
	mov bx,[bp+4]
	add bx,2

	;if index at end, wraparound
	cmp bx,startIndex
	jne incEnd
	
	mov bx,0

	incEnd:
	mov [bp+6],bx
	popa
	pop bp
	ret 2

createMask: ;returns mask, get bit number
	push bp
	mov bp,sp
	pusha
	mov cx,[bp+4];n
	mov ax,0x8000;store mask in
	maskLoop:
		cmp cx,0
		je endmaskLoop
		shr ax,1
		sub cx,1
		jmp maskLoop

	endmaskLoop:
	mov [bp+6],ax
	popa
	pop bp
	ret 2

isFree: ;bool(arr&,row number) returns 1 if free
	push bp
	mov bp,sp	
	pusha

	;get mask
	mov cx,[bp+4] ;row number
	push 0
	push cx
	call createMask
	pop ax

	test [FreeQueue],ax
	jz FreeArr

	mov word [bp+8],1
	jmp isFreeEnd

	FreeArr:
	mov word [bp+8],0

	isFreeEnd:
	popa
	pop bp
	ret 4

qAdd: ;returns bool takes arr address, row ,val
	push bp
	mov bp,sp
	pusha

	;check if row free
	push 0
	push word [bp+8];arr
	push word [bp+6];row
	call isFree
	pop ax
	cmp ax,0
	je qAddEnd
		;return 1
		mov word [bp+10],1

		;get que end index
		push 0
		push word [bp+8]
		push word [bp+6]
		push endIndex
		call getEl
		pop bx			

		;get end end address
		push 0
		push word [bp+8]
		push word [bp+6]
		push word [bx]
		call getEl
		pop si

		mov ax,[bp+4]
		mov [si],ax ;mov val to end of queue


		;inc end of queue
		push 0
		push word [bx]
		call incIndex
		pop word [bx]

		;check if list full
			;get start of list
			push 0
			push word [bp+8]
			push word [bp+6]
			push startIndex
			call getEl
			pop	si

			;cmp start and end, list full if start==end
			mov ax,[si]
			cmp [bx],ax
			jne qAddEnd

			;set freearr to 0
			push 0	
			push word [bp+6];row
			call createMask
			pop ax
			xor ax,0xFFFF

			and [FreeQueue],ax	
			 

	qAddEnd:
		popa
		pop bp
		ret	6 


qremove: ;bool(arr,row)
	push bp
	mov bp,sp
	pusha

	;if row empty(start==end && free) return 0
		;get start
		push 0
		push word [bp+6]
		push word [bp+4]
		push startIndex
		call getEl
		pop bx
		mov ax,[bx]

		;get end
		push 0
		push word [bp+6]
		push word [bp+4]
		push endIndex
		call getEl
		pop bx

		cmp ax,[bx]
		jne removeEl ;start!=end

		;check if row free
		push 0
		push word [bp+6];arr
		push word [bp+4];row
		call isFree
		pop ax
		cmp ax,1
		jne makeFree;mark list as free

		mov word [bp+8],0
		jmp qremoveEnd

		makeFree:
			push 0
			push word [bp+4]
			call createMask
			pop ax

			or [FreeQueue],ax
			jmp removeEl

	removeEl:
	;return 1
	mov word [bp+8],1

	;get start
	push 0
	push word [bp+6]
	push word [bp+4]
	push startIndex
	call getEl
	pop bx

	;increment start
	push 0
	push word [bx]
	call incIndex
	pop ax
	mov [bx],ax

	qremoveEnd:
	popa
	pop bp
	ret 4
	
qcreate: ;int (arr) returns free row number, -1 if all full
	push bp
	mov bp,sp
	pusha

	mov ax,0x8000 ;mask
	mov cx,15 ;counter

	travArr:
		test [bp+4],ax
		jnz foundFree
		shr ax,1
		loop travArr

	;not found
	mov word [bp+6],-1
	jmp qcreateEnd

	foundFree:
		sub cx,rowSize
		add cx,1 ;account for rowSize-1
		mov ax,cx
		mov cx,-1
		mul cx
		mov [bp+6],ax
		jmp qcreateEnd

	qcreateEnd:
	popa
	pop bp
	ret 2