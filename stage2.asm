; Dunbar OS stage-2 real-mode core
; Loaded at physical 0x10000 by boot.asm.

bits 16
org 0

start:
    cli
    xor ax, ax
    mov ds, ax
    mov ss, ax
    mov sp, 0xFF00
    sti

    call clear_screen
    call banner
    call boot_checks
    call login

halt:
    cli
    hlt
    jmp halt

; ------------------------------------------------------------
; Login
; ------------------------------------------------------------

login:
    mov byte [attempts], 0

.login_again:
    call clear_screen
    call banner

    mov si, login_title
    call print
    mov si, operator_prompt
    call print
    call read_line

    mov si, password_prompt
    call print
    call read_password

    call check_password
    jc .wrong

    call success_sequence
    call desktop
    ret

.wrong:
    inc byte [attempts]
    call wrong_password_alarm

    cmp byte [attempts], 3
    jae fatal_lockout

    mov si, retry_msg
    call print
    call wait_key
    jmp .login_again

; ------------------------------------------------------------
; Password check: development password = DUNBAR
; ------------------------------------------------------------

check_password:
    mov si, password_buffer
    mov di, password
.compare:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .bad
    cmp al, 0
    je .good
    inc si
    inc di
    jmp .compare
.good:
    clc
    ret
.bad:
    stc
    ret

; ------------------------------------------------------------
; Keyboard input
; ------------------------------------------------------------

read_line:
    mov di, input_buffer
    call read_line_common
    ret

read_password:
    mov di, password_buffer
.next:
    xor ah, ah
    int 0x16

    cmp al, 13
    je .done
    cmp al, 8
    je .backspace

    cmp al, 32
    jb .next

    mov [di], al
    inc di

    mov si, star
    call print
    jmp .next

.backspace:
    cmp di, password_buffer
    je .next
    dec di
    mov byte [di], 0
    mov si, backspace_visual
    call print
    jmp .next

.done:
    mov byte [di], 0
    mov si, newline
    call print
    ret

read_line_common:
.next:
    xor ah, ah
    int 0x16

    cmp al, 13
    je .done
    cmp al, 8
    je .backspace

    cmp al, 32
    jb .next

    mov [di], al
    inc di
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x0F
    int 0x10
    jmp .next

.backspace:
    cmp di, input_buffer
    je .next
    dec di
    mov byte [di], 0
    mov si, backspace_visual
    call print
    jmp .next

.done:
    mov byte [di], 0
    mov si, newline
    call print
    ret

; ------------------------------------------------------------
; Wrong password alarm
; Four short PC-speaker beeps with red screen flash.
; ------------------------------------------------------------

wrong_password_alarm:
    mov si, denied_msg
    call print

    mov cx, 4
.beep:
    call red_flash
    call short_beep
    call normal_screen
    call delay
    loop .beep
    ret

; ------------------------------------------------------------
; Three failures: fatal/lockout.
; Long PC-speaker tone.
; ------------------------------------------------------------

fatal_lockout:
    call clear_screen
    call red_background

    mov si, fatal_title
    call print
    mov si, fatal_text
    call print

    call long_beep

    cli
.halt:
    hlt
    jmp .halt

; ------------------------------------------------------------
; Desktop
; ------------------------------------------------------------

desktop:
    call clear_screen
    call normal_screen

    mov si, desktop_title
    call print
    mov si, desktop_body
    call print

.wait:
    xor ah, ah
    int 0x16

    cmp al, 27
    je .logout
    cmp al, 't'
    je .terminal
    cmp al, 'T'
    je .terminal

    mov si, desktop_hint
    call print
    jmp .wait

.terminal:
    call clear_screen
    mov si, terminal_title
    call print
    mov si, terminal_body
    call print
    call wait_key
    jmp desktop

.logout:
    jmp login

; ------------------------------------------------------------
; Boot screen
; ------------------------------------------------------------

banner:
    mov si, dunbar
    call print
    ret

boot_checks:
    mov si, checks
    call print
    call short_beep
    ret

success_sequence:
    mov si, accepted_msg
    call print
    call short_beep
    call delay
    ret

; ------------------------------------------------------------
; Video
; ------------------------------------------------------------

clear_screen:
    mov ax, 0x0003
    int 0x10
    ret

normal_screen:
    mov ax, 0x0600
    mov bh, 0x07
    xor cx, cx
    mov dx, 0x184F
    int 0x10
    ret

red_flash:
    mov ax, 0x0600
    mov bh, 0x4F
    xor cx, cx
    mov dx, 0x184F
    int 0x10
    ret

red_background:
    mov ax, 0x0600
    mov bh, 0x4F
    xor cx, cx
    mov dx, 0x184F
    int 0x10
    ret

; ------------------------------------------------------------
; PC speaker
; ------------------------------------------------------------

short_beep:
    ; PIT channel 2, approximately 880 Hz
    mov al, 0xB6
    out 0x43, al

    mov ax, 1355
    out 0x42, al
    mov al, ah
    out 0x42, al

    in al, 0x61
    or al, 3
    out 0x61, al

    call beep_delay

    in al, 0x61
    and al, 0xFC
    out 0x61, al
    ret

long_beep:
    mov al, 0xB6
    out 0x43, al

    mov ax, 1193
    out 0x42, al
    mov al, ah
    out 0x42, al

    in al, 0x61
    or al, 3
    out 0x61, al

    mov cx, 12
.wait:
    call beep_delay
    loop .wait

    in al, 0x61
    and al, 0xFC
    out 0x61, al
    ret

beep_delay:
    mov cx, 0x1800
.d:
    loop .d
    ret

delay:
    mov cx, 0xFFFF
.d1:
    nop
    loop .d1
    ret

; ------------------------------------------------------------
; Misc
; ------------------------------------------------------------

wait_key:
    xor ah, ah
    int 0x16
    ret

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

; ------------------------------------------------------------
; Strings / buffers
; ------------------------------------------------------------

dunbar db 13,10,"========================================",13,10
       db "          D U N B A R   O S",13,10
       db "       EXPERIMENTAL CORE SYSTEM",13,10
       db "========================================",13,10,0

checks db 13,10,"MEMORY ............ CHECK",13,10
       db "KEYBOARD .......... CHECK",13,10
       db "DISPLAY ........... CHECK",13,10
       db "PC SPEAKER ........ CHECK",13,10
       db "DUNBAR CORE ....... ONLINE",13,10,0

login_title db 13,10,"DUNBAR ACCESS TERMINAL",13,10
            db "----------------------",13,10,0

operator_prompt db "OPERATOR: ",0
password_prompt db "PASSWORD: ",0
star db "*",0
backspace_visual db 8," ",8,0
newline db 13,10,0

password db "DUNBAR",0

denied_msg db 13,10,"ACCESS DENIED",13,10
           db "SECURITY EVENT: INVALID PASSWORD",13,10,0

retry_msg db 13,10,"Press any key to retry...",0

accepted_msg db 13,10,"ACCESS ACCEPTED.",13,10
             db "DUNBAR CORE UNLOCKED.",13,10,0

fatal_title db 13,10,"!!! DUNBAR FATAL SECURITY EVENT !!!",13,10,0
fatal_text db 13,10,"THREE INVALID PASSWORDS.",13,10
           db "SYSTEM LOCKED.",13,10
           db "PC SPEAKER ALERT ACTIVE.",13,10
           db "DUNBAR CORE HALTED.",13,10,0

desktop_title db 13,10,"DUNBAR OS / MAIN DESKTOP",13,10
              db "=========================",13,10,0

desktop_body db 13,10
             db "[ CORE ]      ONLINE",13,10
             db "[ DISPLAY ]    TEXT MODE",13,10
             db "[ SECURITY ]   ARMED",13,10
             db "[ AUDIO ]      PC SPEAKER",13,10
             db "[ MEMORY ]     AVAILABLE",13,10
             db 13,10
             db "T = TERMINAL",13,10
             db "ESC = LOCK",13,10,0

desktop_hint db 13,10,"> DUNBAR: INPUT RECEIVED",13,10,0

terminal_title db 13,10,"DUNBAR TERMINAL",13,10
               db "---------------",13,10,0

terminal_body db 13,10
              db "This is the first real Dunbar OS shell.",13,10
              db "The graphical shell will replace this layer.",13,10
              db 13,10
              db "Press any key to return.",13,10,0

attempts db 0
input_buffer times 64 db 0
password_buffer times 64 db 0

times 16384-($-$$) db 0
