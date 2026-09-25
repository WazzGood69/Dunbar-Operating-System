; Dunbar OS stage-1 BIOS boot sector
; Loads stage2.bin from sectors 2..33 into 0x1000:0000.

bits 16
org 0x7C00

start:
    cli
    xor ax, ax
    mov ds, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov [boot_drive], dl

    mov si, msg
    call print

    ; ES:BX = 1000:0000
    mov ax, 0x1000
    mov es, ax
    xor bx, bx

    mov ah, 0x02
    mov al, 32
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    jmp 0x1000:0000

disk_error:
    mov si, err
    call print
    cli
.hang:
    hlt
    jmp .hang

print:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x07
    int 0x10
    jmp print
.done:
    ret

boot_drive db 0
msg db 13,10,"DUNBAR BIOS LOADER",13,10,"LOADING CORE...",0
err db 13,10,"DISK READ FAILURE.",13,10,0

times 510-($-$$) db 0
dw 0xAA55
