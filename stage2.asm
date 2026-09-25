; Dunbar OS graphical stage-2 core
; Real-mode BIOS UI for the Dell Inspiron E1705.
; VGA mode 13h (320x200x256), BIOS keyboard input, PC speaker alarms.
; Development access: arrow sequence UP, LEFT, RIGHT, DOWN, ENTER + password DUNBAR.

bits 16
org 0

start:
    cli
    mov ax,0x1000
    mov ds,ax
    xor ax,ax
    mov ss,ax
    mov sp,0xFF00
    sti

    call video_init
    call draw_login
    call alien_login
    call desktop
.halt:
    cli
    hlt
    jmp .halt

; ------------------------------------------------------------
; Alien keyboard access sequence
; UP, LEFT, RIGHT, DOWN, ENTER
; ------------------------------------------------------------

alien_login:
.retry:
    call draw_login
    mov si,seq_prompt
    call print_at_5_12

    xor bx,bx
.next:
    xor ah,ah
    int 16h
    cmp al,27
    je .retry

    ; Extended keyboard key: AL=00, AH=scan code.
    cmp al,0
    jne .check_enter

    cmp ah,48h
    je .up
    cmp ah,4Bh
    je .left
    cmp ah,4Dh
    je .right
    cmp ah,50h
    je .down
    jmp .wrong

.up:
    cmp bl,0
    jne .wrong
    inc bl
    call glyph_up
    jmp .next
.left:
    cmp bl,1
    jne .wrong
    inc bl
    call glyph_left
    jmp .next
.right:
    cmp bl,2
    jne .wrong
    inc bl
    call glyph_right
    jmp .next
.down:
    cmp bl,3
    jne .wrong
    inc bl
    call glyph_down
    jmp .next

.check_enter:
    cmp al,13
    jne .next
    cmp bl,4
    jne .wrong
    jmp .password

.wrong:
    inc byte [attempts]
    call alarm
    cmp byte [attempts],3
    jae fatal_lockout
    mov si,wrong_sequence
    call print_at_5_15
    call wait_key
    jmp .retry

.password:
    call draw_password
    mov si,password_prompt
    call print_at_5_11
    call read_password
    call check_password
    jc .badpass
    call success
    ret

.badpass:
    inc byte [attempts]
    call alarm
    cmp byte [attempts],3
    jae fatal_lockout
    mov si,wrong_password
    call print_at_5_15
    call wait_key
    jmp .retry

check_password:
    mov si,password_buffer
    mov di,password
.compare:
    mov al,[si]
    mov bl,[di]
    cmp al,bl
    jne .bad
    cmp al,0
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

read_password:
    mov di,password_buffer
.next:
    xor ah,ah
    int 16h
    cmp al,13
    je .done
    cmp al,8
    je .back
    cmp al,32
    jb .next
    cmp di,password_buffer+63
    jae .next
    mov [di],al
    inc di
    mov si,star
    call print_at_5_12_append
    jmp .next
.back:
    cmp di,password_buffer
    je .next
    dec di
    mov byte [di],0
    jmp .next
.done:
    mov byte [di],0
    ret

; ------------------------------------------------------------
; Graphical desktop
; ------------------------------------------------------------

desktop:
    call draw_desktop
.wait:
    xor ah,ah
    int 16h
    cmp al,27
    je .logout
    cmp al,'t'
    je .terminal
    cmp al,'T'
    je .terminal
    cmp al,'s'
    je .settings
    cmp al,'S'
    je .settings
    cmp al,'n'
    je .network
    cmp al,'N'
    je .network
    cmp al,'b'
    je .browser
    cmp al,'B'
    je .browser
    jmp .wait
.logout:
    mov byte [attempts],0
    jmp start
.terminal:
    call terminal
    jmp desktop
.settings:
    call settings
    jmp desktop
.network:
    call network_screen
    jmp desktop
.browser:
    call browser_screen
    jmp desktop

terminal:
    call clear
    call panel_frame
    mov si,terminal_title
    call print_at_5_3
    mov si,terminal_text
    call print_at_5_6
    call wait_key
    ret

settings:
    call clear
    call panel_frame
    mov si,settings_title
    call print_at_5_3
    mov si,settings_text
    call print_at_5_6
    call wait_key
    ret

network_screen:
    call clear
    call panel_frame
    mov si,network_title
    call print_at_5_3
    mov si,network_text
    call print_at_5_6
    call wait_key
    ret

browser_screen:
    call clear
    call panel_frame
    mov si,browser_title
    call print_at_5_3
    mov si,browser_text
    call print_at_5_6
    call wait_key
    ret

; ------------------------------------------------------------
; VGA drawing
; ------------------------------------------------------------

video_init:
    mov ax,0013h
    int 10h
    ret

clear:
    push ax
    push cx
    push di
    push es
    mov ax,0A000h
    mov es,ax
    xor di,di
    xor al,al
    mov cx,32000
    rep stosw
    pop es
    pop di
    pop cx
    pop ax
    ret

; Draw desktop shell and calm dark background.
draw_desktop:
    call clear
    ; top bar
    mov ax,0000h
    mov bx,0013h
    mov cx,0
    mov dx,319
    call hline
    mov cx,0
    mov dx,24
    call hline
    ; main panels
    mov cx,12
    mov dx,150
    mov si,28
    mov di,86
    call rect
    mov cx,164
    mov dx,307
    mov si,28
    mov di,86
    call rect
    ; bottom bar
    mov cx,0
    mov dx,319
    mov si,181
    mov di,199
    call rect
    mov si,desktop_title
    call print_at_3_2
    mov si,desktop_core
    call print_at_3_5
    mov si,desktop_network
    call print_at_21_5
    mov si,desktop_help
    call print_at_3_23
    ret

draw_login:
    call clear
    mov cx,28
    mov dx,291
    mov si,25
    mov di,173
    call rect
    mov si,login_title
    call print_at_8_3
    mov si,login_subtitle
    call print_at_8_5
    ret

draw_password:
    call clear
    mov cx,28
    mov dx,291
    mov si,25
    mov di,173
    call rect
    mov si,password_title
    call print_at_8_3
    ret

panel_frame:
    mov cx,18
    mov dx,301
    mov si,24
    mov di,177
    call rect
    ret

; AX=color (low byte), CX=x1, DX=x2, SI=y1, DI=y2.
rect:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    mov bp,si
.row:
    mov si,bp
    call hline
    inc bp
    cmp bp,di
    jbe .row
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; CX=x1, DX=x2, SI=y. AL=color.
hline:
    push ax
    push bx
    push cx
    push dx
    push di
    push es
    mov bx,ax
    mov ax,0A000h
    mov es,ax
    mov ax,si
    mov di,320
    mul di
    add ax,cx
    mov di,ax
    mov al,bl
    mov ah,al
    mov cx,dx
    sub cx,dx
    ; rebuild count: x2-x1+1
    pop dx
    pop di
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; The simple panel routine above intentionally leaves pixel color at BIOS
; default after mode switch. Text is the primary visible UI in this first
; graphics shell.

; ------------------------------------------------------------
; Alien glyph feedback using BIOS characters/labels.
; ------------------------------------------------------------

glyph_up:
    mov si,g_up
    call print_at_12_12
    ret
glyph_left:
    mov si,g_left
    call print_at_12_12
    ret
glyph_right:
    mov si,g_right
    call print_at_12_12
    ret
glyph_down:
    mov si,g_down
    call print_at_12_12
    ret

; ------------------------------------------------------------
; Text output in VGA mode using BIOS teletype.
; BIOS text services remain available after mode 13h on the E1705.
; ------------------------------------------------------------

print_at_3_2:
    mov dh,2
    mov dl,3
    jmp print_at
print_at_3_5:
    mov dh,5
    mov dl,3
    jmp print_at
print_at_21_5:
    mov dh,5
    mov dl,21
    jmp print_at
print_at_3_23:
    mov dh,23
    mov dl,3
    jmp print_at
print_at_5_3:
    mov dh,3
    mov dl,5
    jmp print_at
print_at_5_6:
    mov dh,6
    mov dl,5
    jmp print_at
print_at_5_11:
    mov dh,11
    mov dl,5
    jmp print_at
print_at_5_12:
    mov dh,12
    mov dl,5
    jmp print_at
print_at_5_15:
    mov dh,15
    mov dl,5
    jmp print_at
print_at_8_3:
    mov dh,3
    mov dl,8
    jmp print_at
print_at_8_5:
    mov dh,5
    mov dl,8
    jmp print_at
print_at_12_12:
    mov dh,12
    mov dl,12
    jmp print_at

print_at:
    push ax
    push bx
    mov ah,02h
    xor bh,bh
    int 10h
    pop bx
    pop ax
    call print
    ret

print_at_5_12_append:
    mov dh,12
    mov dl,17
    jmp print_at

print:
.next:
    lodsb
    or al,al
    jz .done
    mov ah,0Eh
    xor bh,bh
    mov bl,0Fh
    int 10h
    jmp .next
.done:
    ret

wait_key:
    xor ah,ah
    int 16h
    ret

; ------------------------------------------------------------
; Security / speaker
; ------------------------------------------------------------

alarm:
    mov cx,4
.beep:
    call short_beep
    call delay
    loop .beep
    ret

short_beep:
    mov al,0B6h
    out 43h,al
    mov ax,1355
    out 42h,al
    mov al,ah
    out 42h,al
    in al,61h
    or al,3
    out 61h,al
    call beep_delay
    in al,61h
    and al,0FCh
    out 61h,al
    ret

long_beep:
    mov al,0B6h
    out 43h,al
    mov ax,1193
    out 42h,al
    mov al,ah
    out 42h,al
    in al,61h
    or al,3
    out 61h,al
    mov cx,12
.lb:
    call beep_delay
    loop .lb
    in al,61h
    and al,0FCh
    out 61h,al
    ret

fatal_lockout:
    call clear
    mov si,fatal_title
    call print_at_5_6
    mov si,fatal_text
    call print_at_5_9
    call long_beep
    cli
.h:
    hlt
    jmp .h

success:
    call clear
    mov si,accepted
    call print_at_8_8
    call short_beep
    call delay
    ret

beep_delay:
    mov cx,1800h
.bd:
    loop .bd
    ret

delay:
    mov cx,0FFFFh
.d:
    nop
    loop .d
    ret

; ------------------------------------------------------------
; Strings and buffers
; ------------------------------------------------------------

login_title db "D U N B A R   O S",0
login_subtitle db "E1705 GRAPHICAL CORE / ACCESS TERMINAL",0
seq_prompt db "ALIEN ACCESS SEQUENCE:  UP  LEFT  RIGHT  DOWN  ENTER",0
g_up db "[ Ϟ / UP ]",0
g_left db "[ ⟟ / LEFT ]",0
g_right db "[ ᛝ / RIGHT ]",0
g_down db "[ ∴ / DOWN ]",0
password_title db "DUNBAR SECURITY CORE",0
password_prompt db "PASSWORD:",0
star db "*",0
wrong_sequence db "INVALID CONTROL SEQUENCE.",0
wrong_password db "ACCESS DENIED.",0
accepted db "ACCESS ACCEPTED / DUNBAR CORE UNLOCKED",0
fatal_title db "!!! DUNBAR SECURITY LOCKOUT !!!",0
fatal_text db "THREE INVALID ACCESS EVENTS. CORE HALTED.",0

desktop_title db "DUNBAR OS     CORE ONLINE",0
desktop_core db "[ CORE ]  [ TERMINAL ]  [ SETTINGS ]",0
desktop_network db "[ NETWORK DIAGNOSTICS ]  [ BROWSER ]",0
desktop_help db "T TERMINAL   S SETTINGS   N NETWORK   B BROWSER   ESC LOCK",0

terminal_title db "DUNBAR TERMINAL",0
terminal_text db "REAL-MODE TERMINAL READY. PRESS ANY KEY.",0
settings_title db "DUNBAR CONFIGURATION",0
settings_text db "GRAPHICS / INPUT / SECURITY MODULES. PRESS ANY KEY.",0
network_title db "AUTHORIZED NETWORK DIAGNOSTICS",0
network_text db "LOCAL NETWORK DRIVER NOT YET INSTALLED. NO PASSIVE SNIFFING.",0
browser_title db "DUNBAR BROWSER",0
browser_text db "BROWSER ENGINE MODULE NOT YET INSTALLED. SHELL READY.",0

password db "DUNBAR",0
attempts db 0
password_buffer times 64 db 0

times 16384-($-$$) db 0
