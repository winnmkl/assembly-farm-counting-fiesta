; ============================================================================
; FARM COUNTING FIESTA :: VGA EDITION  (NASM .COM)
; Stage 5: Enhanced SFX, background melody, fixed single-player button layout
; ============================================================================
        BITS    16
        CPU     286
        ORG     100h

VIDEO_SEG       equ 0A000h
SCREEN_W        equ 320
SCREEN_H        equ 200

; State IDs
ST_START        equ 1
ST_TUTORIAL     equ 2
ST_MODE         equ 3
ST_DIFFICULTY   equ 4
ST_P1NAME       equ 5
ST_P1BANNER     equ 6
ST_GAME         equ 7
ST_CORRECT      equ 8
ST_WRONG        equ 9
ST_P2NAME       equ 10
ST_P2BANNER     equ 11
ST_VICTORY      equ 12
ST_GAMEOVER     equ 13
ST_HISCORES     equ 14
ST_ROUNDEND     equ 15
ST_P1PASS       equ 16
ST_P2PASS       equ 17
ST_LOGIN        equ 18
ST_REGISTER     equ 19
ST_QUIT         equ 99

; Modes
MODE_1P         equ 1
MODE_2P         equ 2

; Difficulty
DIFF_EASY       equ 1
DIFF_MEDIUM     equ 2
DIFF_HARD       equ 3

; Animal types
ANIM_CHICKEN    equ 0
ANIM_COW        equ 1
ANIM_PIG        equ 2

; Win condition: tokens stored as half-tokens (x2)
; 5 full tokens = 10 half-tokens
WIN_TOKENS      equ 10
MAX_STRIKES     equ 3

; SoundBlaster ports (default base 220h)
SB_RESET        equ 0226h
SB_READ         equ 022Ah
SB_WRITE        equ 022Ch
SB_POLL         equ 022Eh

; Color names (indices into our palette)
C_BLACK         equ 0
C_WHITE         equ 1
C_SKY           equ 2
C_SKY_DK        equ 3
C_GRASS         equ 4
C_GRASS_DK      equ 5
C_DIRT          equ 6
C_DIRT_DK       equ 7
C_BARN          equ 8
C_BARN_DK       equ 9
C_ROOF          equ 10
C_TREE          equ 11
C_TRUNK         equ 12
C_SUN           equ 13
C_CLOUD         equ 14
C_FENCE         equ 15
C_FENCE_DK      equ 16
C_TITLE_O       equ 17
C_TITLE_G       equ 18
C_TITLE_Y       equ 19
C_PANEL         equ 20
C_PANEL_BD      equ 21
C_GREEN         equ 22
C_PURPLE        equ 23
C_RED           equ 24
C_TEAL          equ 25
C_ORANGE        equ 26
C_GOLD          equ 27
C_GRAY          equ 29
C_DKGRAY        equ 30
C_PINK          equ 31
C_PIG_DK        equ 32
C_COW_BLACK     equ 33
C_BEAK          equ 34
C_COMB          equ 35

; ============================================================================
start:
        mov     sp, stack_top

        ; Resize memory block
        mov     bx, prog_end
        add     bx, 15
        mov     cl, 4
        shr     bx, cl
        mov     ah, 4Ah
        int     21h

        call    AllocBack
        call    SetMode13h
        call    SetupPalette
        call    InitRandom
        call    DetectSB
        call    LoadSingleScores
        call    LoadDuelScores
        call    LoadAccounts
        call    BgMusic_Install
        call    BgMusic_Start

        ; --- main state loop ---
main_loop:
        mov     al, [g_state]
        cmp     al, ST_QUIT
        je      main_done

        cmp     al, ST_START
        je      .do_start
        cmp     al, ST_TUTORIAL
        je      .do_tut
        cmp     al, ST_MODE
        je      .do_mode
        cmp     al, ST_DIFFICULTY
        je      .do_diff
        cmp     al, ST_P1NAME
        je      .do_p1n
        cmp     al, ST_P1BANNER
        je      .do_p1b
        cmp     al, ST_GAME
        je      .do_game
        cmp     al, ST_CORRECT
        je      .do_corr
        cmp     al, ST_WRONG
        je      .do_wrong
        cmp     al, ST_P2NAME
        je      .do_p2n
        cmp     al, ST_P2BANNER
        je      .do_p2b
        cmp     al, ST_VICTORY
        je      .do_vic
        cmp     al, ST_GAMEOVER
        je      .do_go
        cmp     al, ST_HISCORES
        je      .do_hi
        cmp     al, ST_ROUNDEND
        je      .do_rnd
        cmp     al, ST_P1PASS
        je      .do_p1pw
        cmp     al, ST_P2PASS
        je      .do_p2pw
        ; unknown state -> reset
        mov     byte [g_state], ST_START
        jmp     main_loop

.do_start:
        call    DoStart
        jmp     main_loop
.do_tut:
        call    DoTutorial
        jmp     main_loop
.do_mode:
        call    DoMode
        jmp     main_loop
.do_diff:
        call    DoDifficulty
        jmp     main_loop
.do_p1n:
        mov     al, 1
        call    DoNameEntry
        jmp     main_loop
.do_p1b:
        mov     al, 1
        call    DoBanner
        jmp     main_loop
.do_game:
        call    DoGame
        jmp     main_loop
.do_corr:
        call    DoCorrect
        jmp     main_loop
.do_wrong:
        call    DoWrong
        jmp     main_loop
.do_p2n:
        mov     al, 2
        call    DoNameEntry
        jmp     main_loop
.do_p2b:
        mov     al, 2
        call    DoBanner
        jmp     main_loop
.do_vic:
        call    DoVictory
        jmp     main_loop
.do_go:
        call    DoGameOver
        jmp     main_loop
.do_hi:
        call    DoHiScores
        jmp     main_loop
.do_rnd:
        call    DoRoundEnd
        jmp     main_loop
.do_p1pw:
        mov     al, 1
        call    DoPassEntry
        jmp     main_loop
.do_p2pw:
        mov     al, 2
        call    DoPassEntry
        jmp     main_loop

main_done:
        call    BgMusic_Remove
        call    SaveSingleScores
        call    SaveDuelScores
        call    SaveAccounts
        call    SetMode03h
        call    FreeBack

        mov     ax, 4C00h
        int     21h

; ============================================================================
SetMode13h:
        push    ax
        mov     ax, 0013h
        int     10h
        pop     ax
        ret

SetMode03h:
        push    ax
        mov     ax, 0003h
        int     10h
        pop     ax
        ret

AllocBack:
        push    ax
        push    bx
        mov     ah, 48h
        mov     bx, 4000
        int     21h
        mov     [g_back_seg], ax
        pop     bx
        pop     ax
        ret

FreeBack:
        push    ax
        push    es
        mov     es, [g_back_seg]
        mov     ah, 49h
        int     21h
        pop     es
        pop     ax
        ret

SetupPalette:
        push    ax
        push    cx
        push    dx
        push    si
        mov     dx, 03C8h
        xor     al, al
        out     dx, al
        inc     dx
        mov     si, palette_data
        mov     cx, 36 * 3
.lp:    lodsb
        out     dx, al
        loop    .lp
        pop     si
        pop     dx
        pop     cx
        pop     ax
        ret

ClearBack:
        push    ax
        push    cx
        push    di
        push    es
        mov     es, [g_back_seg]
        xor     di, di
        mov     al, [gfx_color]
        mov     ah, al
        mov     cx, 32000
        rep     stosw
        pop     es
        pop     di
        pop     cx
        pop     ax
        ret

WaitVR:
        push    ax
        push    dx
        mov     dx, 03DAh
.w1:    in      al, dx
        test    al, 8
        jnz     .w1
.w2:    in      al, dx
        test    al, 8
        jz      .w2
        pop     dx
        pop     ax
        ret

Flip:
        push    ax
        push    cx
        push    si
        push    di
        push    ds
        push    es
        call    WaitVR
        mov     ax, [g_back_seg]
        mov     ds, ax
        xor     si, si
        mov     ax, VIDEO_SEG
        mov     es, ax
        xor     di, di
        mov     cx, 32000
        rep     movsw
        pop     es
        pop     ds
        pop     di
        pop     si
        pop     cx
        pop     ax
        ret

; ============================================================================
; TRANSITION EFFECTS  (operate on live VGA seg 0A000h)
; ============================================================================

; TransFadeOut: fade screen to black by writing scaled palette values (8 steps)
; Uses palette_data as source so no DAC read needed. Leaves palette at 0.
TransFadeOut:
        push    ax
        push    bx
        push    cx
        push    dx
        push    si

        ; step goes 7..0  (scale = step*8, so 56..0 out of 63)
        mov     cx, 8
        mov     byte [tr_step], 56     ; start near full brightness
.pass:
        push    cx
        call    WaitVR

        mov     dx, 03C8h
        xor     al, al
        out     dx, al                 ; write index = 0
        mov     dx, 03C9h

        mov     si, palette_data
        mov     bx, 36*3
.comp:
        mov     al, [si]
        xor     ah, ah
        mul     byte [tr_step]         ; ax = val * step
        shr     ax, 1
        shr     ax, 1
        shr     ax, 1
        shr     ax, 1
        shr     ax, 1
        shr     ax, 1                  ; ax = ax / 64 ≈ val * step / 63
        cmp     al, 63
        jbe     .ok
        mov     al, 63
.ok:
        out     dx, al
        inc     si
        dec     bx
        jnz     .comp

        ; Subtract 8 from step each pass (56, 48, 40, 32, 24, 16, 8, 0)
        mov     al, [tr_step]
        cmp     al, 8
        jb      .zero_step
        sub     al, 8
        jmp     .save_step
.zero_step:
        xor     al, al
.save_step:
        mov     [tr_step], al

        pop     cx
        loop    .pass

        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

; TransFadeIn: restore our palette from palette_data over ~6 VBL frames
; Call AFTER you've drawn the new scene to the backbuffer and flipped it.
TransFadeIn:
        push    ax
        push    bx
        push    cx
        push    dx
        push    si

        ; We do 8 passes. Each pass we write palette_data * (pass/8)
        ; To avoid floating point: use a scale byte 0..63 built up each pass.
        ; Each pass: target[i] = palette_data[i] * step / 8
        mov     byte [tr_step], 0

        mov     cx, 8
.pass:
        push    cx
        call    WaitVR

        ; Increment scale step
        mov     al, [tr_step]
        add     al, 8
        cmp     al, 64
        jbe     .ok_step
        mov     al, 63
.ok_step:
        mov     [tr_step], al

        ; Write all 36 palette entries scaled by tr_step/63
        mov     dx, 03C8h
        xor     al, al
        out     dx, al          ; start write at color 0

        mov     dx, 03C9h
        mov     si, palette_data
        mov     bx, 36*3
.comp:
        mov     al, [si]
        ; scale: al = al * tr_step / 63  ≈ al * tr_step >> 6
        xor     ah, ah
        mul     byte [tr_step]  ; ax = palette_val * step
        ; divide by 63: approximate as >> 6 (div by 64, close enough)
        shr     ax, 1
        shr     ax, 1
        shr     ax, 1
        shr     ax, 1
        shr     ax, 1
        shr     ax, 1
        cmp     al, 63
        jbe     .clamp_ok
        mov     al, 63
.clamp_ok:
        out     dx, al
        inc     si
        dec     bx
        jnz     .comp

        pop     cx
        loop    .pass

        ; Final: write exact palette to fix any rounding
        call    SetupPalette

        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

; TransWipeDown: wipe a black bar down over the live screen, then clear back
; TransWipeDown: sweep a black bar down the screen, 8 scanlines per VBL frame
; Gives a smooth wipe in ~25 frames. No WaitVR per line — one per batch.
TransWipeDown:
        push    ax
        push    bx
        push    cx
        push    dx
        push    di
        push    es

        mov     ax, VIDEO_SEG
        mov     es, ax

        xor     bx, bx          ; bx = current top scanline
.frame:
        cmp     bx, SCREEN_H
        jae     .done
        call    WaitVR

        ; Draw 8 black scanlines starting at bx
        ; offset = bx * 320  using: bx*256 + bx*64
        mov     ax, bx
        mov     dx, 320
        mul     dx              ; dx:ax = bx * 320; ax = low word (fits in 16-bit for bx<200)
        mov     di, ax

        ; How many lines to draw this frame
        mov     cx, SCREEN_H
        sub     cx, bx
        cmp     cx, 8
        jbe     .last_batch
        mov     cx, 8
.last_batch:
        ; cx lines × 320 bytes / 2 words
        push    bx
        mov     bx, cx
        mov     cx, 320
        mul     bx              ; ax = lines*320 — recompute? No, use bx directly
        ; simpler: cx lines, each 160 words
        mov     ax, bx          ; lines count
        mov     cx, 160         ; words per line
        mul     cx              ; ax = lines * 160
        mov     cx, ax          ; cx = total words
        pop     bx
        xor     ax, ax          ; fill with black
        rep     stosw

        add     bx, 8
        jmp     .frame
.done:
        pop     es
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

; TransFlash: flash the screen with a solid color for a few frames
; AL = color index to flash with, CX = number of VBL frames
TransFlash:
        push    ax
        push    bx
        push    cx
        push    di
        push    es

        mov     bx, cx          ; frame count
        mov     ah, al          ; color word

        mov     cx, VIDEO_SEG
        mov     es, cx

.frame:
        cmp     bx, 0
        je      .done
        call    WaitVR
        xor     di, di
        mov     cx, 32000
        rep     stosw
        dec     bx
        jmp     .frame
.done:
        ; Restore backbuffer to screen
        call    Flip

        pop     es
        pop     di
        pop     cx
        pop     bx
        pop     ax
        ret

; tr_step: scratch for TransFadeIn
tr_step:        db 0

; ============================================================================
FillRect:
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    bp
        push    es

        mov     es, [g_back_seg]
        mov     al, [gfx_color]
        mov     ah, al

        mov     bx, [gfx_y]
        mov     bp, [gfx_h]
.yloop:
        cmp     bp, 0
        je      .done
        cmp     bx, SCREEN_H
        jae     .done

        mov     di, bx
        mov     cl, 6
        shl     di, cl
        mov     dx, bx
        mov     cl, 8
        shl     dx, cl
        add     di, dx
        add     di, [gfx_x]

        mov     cx, [gfx_w]

        mov     dx, [gfx_x]
        cmp     dx, SCREEN_W
        jae     .skiprow
        mov     si, dx
        add     si, cx
        cmp     si, SCREEN_W
        jbe     .dorow
        mov     cx, SCREEN_W
        sub     cx, dx

.dorow:
        cmp     cx, 0
        je      .skiprow
        mov     dx, cx
        shr     cx, 1
        jcxz    .nowords
        rep     stosw
.nowords:
        test    dx, 1
        jz      .skiprow
        stosb

.skiprow:
        inc     bx
        dec     bp
        jmp     .yloop
.done:
        pop     es
        pop     bp
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

; ============================================================================
FrameRect:
        push    ax
        push    bx
        push    cx
        push    dx
        mov     ax, [gfx_y]
        push    ax
        mov     ax, [gfx_h]
        push    ax

        mov     word [gfx_h], 1
        call    FillRect

        pop     dx
        pop     bx
        push    bx
        push    dx
        mov     ax, bx
        add     ax, dx
        dec     ax
        mov     [gfx_y], ax
        mov     word [gfx_h], 1
        call    FillRect

        pop     dx
        pop     bx
        mov     [gfx_y], bx
        mov     [gfx_h], dx

        mov     ax, [gfx_x]
        push    ax
        mov     ax, [gfx_w]
        push    ax
        mov     word [gfx_w], 1
        call    FillRect

        pop     dx
        pop     bx
        push    bx
        push    dx
        mov     ax, bx
        add     ax, dx
        dec     ax
        mov     [gfx_x], ax
        mov     word [gfx_w], 1
        call    FillRect

        pop     dx
        pop     bx
        mov     [gfx_x], bx
        mov     [gfx_w], dx

        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

; ============================================================================
DrawScene:
        push    ax
        push    bx

        mov     word [gfx_x], 0
        mov     word [gfx_y], 0
        mov     word [gfx_w], 320
        mov     word [gfx_h], 130
        mov     byte [gfx_color], C_SKY
        call    FillRect

        mov     bx, 0
.sky_lp:
        cmp     bx, 130
        jae     .sky_done
        mov     word [gfx_x], 0
        mov     [gfx_y], bx
        mov     word [gfx_w], 320
        mov     word [gfx_h], 1
        mov     byte [gfx_color], C_SKY_DK
        call    FillRect
        add     bx, 4
        jmp     .sky_lp
.sky_done:

        mov     word [gfx_x], 0
        mov     word [gfx_y], 130
        mov     word [gfx_w], 320
        mov     word [gfx_h], 30
        mov     byte [gfx_color], C_GRASS
        call    FillRect

        mov     word [gfx_x], 0
        mov     word [gfx_y], 154
        mov     word [gfx_w], 320
        mov     word [gfx_h], 4
        mov     byte [gfx_color], C_GRASS_DK
        call    FillRect

        mov     word [gfx_x], 0
        mov     word [gfx_y], 160
        mov     word [gfx_w], 320
        mov     word [gfx_h], 40
        mov     byte [gfx_color], C_DIRT
        call    FillRect

        mov     bx, 162
.dirt_lp:
        cmp     bx, 200
        jae     .dirt_done
        mov     word [gfx_x], 0
        mov     [gfx_y], bx
        mov     word [gfx_w], 320
        mov     word [gfx_h], 1
        mov     byte [gfx_color], C_DIRT_DK
        call    FillRect
        add     bx, 6
        jmp     .dirt_lp
.dirt_done:

        mov     word [gfx_x], 260
        mov     word [gfx_y], 25
        mov     word [gfx_w], 24
        mov     word [gfx_h], 24
        mov     byte [gfx_color], C_SUN
        call    FillRect
        mov     word [gfx_x], 260
        mov     word [gfx_y], 25
        mov     word [gfx_w], 4
        mov     word [gfx_h], 4
        mov     byte [gfx_color], C_SKY
        call    FillRect
        mov     word [gfx_x], 280
        mov     word [gfx_y], 25
        mov     word [gfx_w], 4
        mov     word [gfx_h], 4
        call    FillRect
        mov     word [gfx_x], 260
        mov     word [gfx_y], 45
        mov     word [gfx_w], 4
        mov     word [gfx_h], 4
        call    FillRect
        mov     word [gfx_x], 280
        mov     word [gfx_y], 45
        mov     word [gfx_w], 4
        mov     word [gfx_h], 4
        call    FillRect

        mov     word [gfx_x], 30
        mov     word [gfx_y], 30
        mov     word [gfx_w], 24
        mov     word [gfx_h], 6
        mov     byte [gfx_color], C_CLOUD
        call    FillRect
        mov     word [gfx_x], 36
        mov     word [gfx_y], 26
        mov     word [gfx_w], 14
        mov     word [gfx_h], 4
        call    FillRect

        mov     word [gfx_x], 200
        mov     word [gfx_y], 70
        mov     word [gfx_w], 22
        mov     word [gfx_h], 5
        call    FillRect
        mov     word [gfx_x], 206
        mov     word [gfx_y], 67
        mov     word [gfx_w], 12
        mov     word [gfx_h], 4
        call    FillRect

        mov     word [gfx_x], 50
        mov     word [gfx_y], 110
        mov     word [gfx_w], 6
        mov     word [gfx_h], 25
        mov     byte [gfx_color], C_TRUNK
        call    FillRect
        mov     word [gfx_x], 38
        mov     word [gfx_y], 70
        mov     word [gfx_w], 30
        mov     word [gfx_h], 42
        mov     byte [gfx_color], C_TREE
        call    FillRect

        mov     word [gfx_x], 240
        mov     word [gfx_y], 90
        mov     word [gfx_w], 50
        mov     word [gfx_h], 50
        mov     byte [gfx_color], C_BARN
        call    FillRect
        mov     word [gfx_x], 240
        mov     word [gfx_y], 80
        mov     word [gfx_w], 50
        mov     word [gfx_h], 12
        mov     byte [gfx_color], C_ROOF
        call    FillRect
        mov     word [gfx_x], 256
        mov     word [gfx_y], 110
        mov     word [gfx_w], 18
        mov     word [gfx_h], 30
        mov     byte [gfx_color], C_BARN_DK
        call    FillRect
        mov     word [gfx_x], 264
        mov     word [gfx_y], 110
        mov     word [gfx_w], 2
        mov     word [gfx_h], 30
        mov     byte [gfx_color], C_WHITE
        call    FillRect
        mov     word [gfx_x], 256
        mov     word [gfx_y], 124
        mov     word [gfx_w], 18
        mov     word [gfx_h], 2
        call    FillRect
        mov     word [gfx_x], 295
        mov     word [gfx_y], 95
        mov     word [gfx_w], 12
        mov     word [gfx_h], 45
        mov     byte [gfx_color], C_ROOF
        call    FillRect

        mov     bx, 0
.fence_lp:
        cmp     bx, 320
        jae     .fence_done
        mov     [gfx_x], bx
        mov     word [gfx_y], 162
        mov     word [gfx_w], 4
        mov     word [gfx_h], 14
        mov     byte [gfx_color], C_FENCE
        call    FillRect
        add     bx, 16
        jmp     .fence_lp
.fence_done:

        mov     word [gfx_x], 0
        mov     word [gfx_y], 165
        mov     word [gfx_w], 320
        mov     word [gfx_h], 2
        mov     byte [gfx_color], C_FENCE_DK
        call    FillRect
        mov     word [gfx_x], 0
        mov     word [gfx_y], 173
        mov     word [gfx_w], 320
        mov     word [gfx_h], 2
        call    FillRect

        pop     bx
        pop     ax
        ret

; ============================================================================
; DrawSceneDiff: Like DrawScene but sky/sun changes based on g_diff.
;   EASY   (1) = bright morning sky (normal)
;   MEDIUM (2) = warm afternoon: amber sky, sun higher/brighter
;   HARD   (3) = night: dark navy sky, moon, stars, dark grass
; ============================================================================
DrawSceneDiff:
        push    ax
        push    bx
        push    cx

        cmp     byte [g_diff], DIFF_HARD
        je      .night
        cmp     byte [g_diff], DIFF_MEDIUM
        je      .afternoon

        ; ---- EASY: normal bright morning (same as DrawScene) ----
        pop     cx
        pop     bx
        pop     ax
        jmp     DrawScene

        ; ---- MEDIUM: warm afternoon amber sky ----
.afternoon:
        ; Sky: use C_TITLE_O (amber/orange) as base with C_SUN stripes
        mov     word [gfx_x], 0
        mov     word [gfx_y], 0
        mov     word [gfx_w], 320
        mov     word [gfx_h], 130
        mov     byte [gfx_color], C_SKY
        call    FillRect
        ; Amber tint stripes across sky
        mov     bx, 0
.aft_sky_lp:
        cmp     bx, 130
        jae     .aft_sky_done
        mov     word [gfx_x], 0
        mov     [gfx_y], bx
        mov     word [gfx_w], 320
        mov     word [gfx_h], 1
        mov     byte [gfx_color], C_TITLE_O
        call    FillRect
        add     bx, 3
        jmp     .aft_sky_lp
.aft_sky_done:
        ; Slightly lower, brighter sun (afternoon position)
        mov     word [gfx_x], 255
        mov     word [gfx_y], 15
        mov     word [gfx_w], 28
        mov     word [gfx_h], 28
        mov     byte [gfx_color], C_SUN
        call    FillRect
        ; Sun rays (bright gold dots around it)
        mov     word [gfx_x], 248
        mov     word [gfx_y], 18
        mov     word [gfx_w], 5
        mov     word [gfx_h], 5
        mov     byte [gfx_color], C_GOLD
        call    FillRect
        mov     word [gfx_x], 285
        mov     word [gfx_y], 18
        call    FillRect
        mov     word [gfx_x], 248
        mov     word [gfx_y], 35
        call    FillRect
        mov     word [gfx_x], 285
        mov     word [gfx_y], 35
        call    FillRect
        ; Grass (normal green)
        mov     word [gfx_x], 0
        mov     word [gfx_y], 130
        mov     word [gfx_w], 320
        mov     word [gfx_h], 30
        mov     byte [gfx_color], C_GRASS
        call    FillRect
        mov     word [gfx_x], 0
        mov     word [gfx_y], 154
        mov     word [gfx_w], 320
        mov     word [gfx_h], 4
        mov     byte [gfx_color], C_GRASS_DK
        call    FillRect
        ; Draw rest of scene elements shared with normal scene
        jmp     .draw_common

        ; ---- HARD: night scene - dark navy sky, moon, stars ----
.night:
        ; Dark navy sky
        mov     word [gfx_x], 0
        mov     word [gfx_y], 0
        mov     word [gfx_w], 320
        mov     word [gfx_h], 130
        mov     byte [gfx_color], C_SKY_DK
        call    FillRect
        ; Very dark overlay stripes
        mov     bx, 0
.night_sky_lp:
        cmp     bx, 130
        jae     .night_sky_done
        mov     word [gfx_x], 0
        mov     [gfx_y], bx
        mov     word [gfx_w], 320
        mov     word [gfx_h], 1
        mov     byte [gfx_color], C_BLACK
        call    FillRect
        add     bx, 3
        jmp     .night_sky_lp
.night_sky_done:
        ; Moon (crescent-ish: gold circle with dark cutout)
        mov     word [gfx_x], 258
        mov     word [gfx_y], 10
        mov     word [gfx_w], 22
        mov     word [gfx_h], 22
        mov     byte [gfx_color], C_GOLD
        call    FillRect
        ; Dark cutout to make crescent
        mov     word [gfx_x], 263
        mov     word [gfx_y], 8
        mov     word [gfx_w], 16
        mov     word [gfx_h], 18
        mov     byte [gfx_color], C_SKY_DK
        call    FillRect
        ; Stars (small bright dots scattered)
        mov     word [gfx_x], 20
        mov     word [gfx_y], 8
        mov     word [gfx_w], 2
        mov     word [gfx_h], 2
        mov     byte [gfx_color], C_WHITE
        call    FillRect
        mov     word [gfx_x], 60
        mov     word [gfx_y], 20
        call    FillRect
        mov     word [gfx_x], 110
        mov     word [gfx_y], 5
        call    FillRect
        mov     word [gfx_x], 150
        mov     word [gfx_y], 15
        call    FillRect
        mov     word [gfx_x], 190
        mov     word [gfx_y], 8
        call    FillRect
        mov     word [gfx_x], 80
        mov     word [gfx_y], 40
        call    FillRect
        mov     word [gfx_x], 230
        mov     word [gfx_y], 50
        call    FillRect
        mov     word [gfx_x], 40
        mov     word [gfx_y], 60
        call    FillRect
        ; Dark grass (night: darker tone)
        mov     word [gfx_x], 0
        mov     word [gfx_y], 130
        mov     word [gfx_w], 320
        mov     word [gfx_h], 30
        mov     byte [gfx_color], C_GRASS_DK
        call    FillRect
        mov     word [gfx_x], 0
        mov     word [gfx_y], 154
        mov     word [gfx_w], 320
        mov     word [gfx_h], 4
        mov     byte [gfx_color], C_BLACK
        call    FillRect
        ; Fall through to common elements

.draw_common:
        ; Dirt path
        mov     word [gfx_x], 0
        mov     word [gfx_y], 160
        mov     word [gfx_w], 320
        mov     word [gfx_h], 40
        mov     byte [gfx_color], C_DIRT
        call    FillRect
        mov     bx, 162
.dirt_lp2:
        cmp     bx, 200
        jae     .dirt_done2
        mov     word [gfx_x], 0
        mov     [gfx_y], bx
        mov     word [gfx_w], 320
        mov     word [gfx_h], 1
        mov     byte [gfx_color], C_DIRT_DK
        call    FillRect
        add     bx, 6
        jmp     .dirt_lp2
.dirt_done2:
        ; Tree
        mov     word [gfx_x], 50
        mov     word [gfx_y], 110
        mov     word [gfx_w], 6
        mov     word [gfx_h], 25
        mov     byte [gfx_color], C_TRUNK
        call    FillRect
        mov     word [gfx_x], 38
        mov     word [gfx_y], 70
        mov     word [gfx_w], 30
        mov     word [gfx_h], 42
        mov     byte [gfx_color], C_TREE
        call    FillRect
        ; Barn
        mov     word [gfx_x], 240
        mov     word [gfx_y], 90
        mov     word [gfx_w], 50
        mov     word [gfx_h], 50
        mov     byte [gfx_color], C_BARN
        call    FillRect
        mov     word [gfx_x], 240
        mov     word [gfx_y], 80
        mov     word [gfx_w], 50
        mov     word [gfx_h], 12
        mov     byte [gfx_color], C_ROOF
        call    FillRect
        mov     word [gfx_x], 256
        mov     word [gfx_y], 110
        mov     word [gfx_w], 18
        mov     word [gfx_h], 30
        mov     byte [gfx_color], C_BARN_DK
        call    FillRect
        mov     word [gfx_x], 264
        mov     word [gfx_y], 110
        mov     word [gfx_w], 2
        mov     word [gfx_h], 30
        mov     byte [gfx_color], C_WHITE
        call    FillRect
        mov     word [gfx_x], 256
        mov     word [gfx_y], 124
        mov     word [gfx_w], 18
        mov     word [gfx_h], 2
        call    FillRect
        mov     word [gfx_x], 295
        mov     word [gfx_y], 95
        mov     word [gfx_w], 12
        mov     word [gfx_h], 45
        mov     byte [gfx_color], C_ROOF
        call    FillRect
        ; Night: barn has lit window (gold)
        cmp     byte [g_diff], DIFF_HARD
        jne     .no_barn_light
        mov     word [gfx_x], 252
        mov     word [gfx_y], 94
        mov     word [gfx_w], 8
        mov     word [gfx_h], 8
        mov     byte [gfx_color], C_GOLD
        call    FillRect
.no_barn_light:
        ; Fence
        mov     bx, 0
.fence_lp2:
        cmp     bx, 320
        jae     .fence_done2
        mov     [gfx_x], bx
        mov     word [gfx_y], 162
        mov     word [gfx_w], 4
        mov     word [gfx_h], 14
        mov     byte [gfx_color], C_FENCE
        call    FillRect
        add     bx, 16
        jmp     .fence_lp2
.fence_done2:
        mov     word [gfx_x], 0
        mov     word [gfx_y], 165
        mov     word [gfx_w], 320
        mov     word [gfx_h], 2
        mov     byte [gfx_color], C_FENCE_DK
        call    FillRect
        mov     word [gfx_x], 0
        mov     word [gfx_y], 173
        mov     word [gfx_w], 320
        mov     word [gfx_h], 2
        call    FillRect

        pop     cx
        pop     bx
        pop     ax
        ret

DrawCh:
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    bp

        cmp     al, 'a'
        jb      .nm
        cmp     al, 'z'
        ja      .nm
        sub     al, 32
.nm:
        cmp     al, 32
        jb      .done
        cmp     al, 90
        ja      .done

        sub     al, 32
        xor     ah, ah
        mov     bx, ax
        mov     cl, 3
        shl     bx, cl
        add     bx, font_data
        mov     si, bx

        mov     ax, [gfx_x]
        mov     [tmp_x], ax
        mov     ax, [gfx_y]
        mov     [tmp_y], ax
        mov     ax, [gfx_w]
        mov     [tmp_w], ax
        mov     ax, [gfx_h]
        mov     [tmp_h], ax

        mov     bp, 0
.row:
        cmp     bp, 8
        jae     .all_done
        mov     ah, [si+bp]

        mov     bx, 0
.col:
        cmp     bx, 8
        jae     .colend

        mov     cl, bl
        mov     dl, 80h
        shr     dl, cl
        test    ah, dl
        jz      .skip

        push    ax
        push    bx

        mov     al, [gfx_scale]
        xor     ah, ah
        mul     bx
        add     ax, [tmp_x]
        mov     [gfx_x], ax

        mov     al, [gfx_scale]
        xor     ah, ah
        push    bx
        mov     bx, bp
        mul     bx
        pop     bx
        add     ax, [tmp_y]
        mov     [gfx_y], ax

        mov     al, [gfx_scale]
        xor     ah, ah
        mov     [gfx_w], ax
        mov     [gfx_h], ax

        call    FillRect

        pop     bx
        pop     ax
.skip:
        inc     bx
        jmp     .col
.colend:
        inc     bp
        jmp     .row
.all_done:
        mov     ax, [tmp_x]
        mov     [gfx_x], ax
        mov     ax, [tmp_y]
        mov     [gfx_y], ax
        mov     ax, [tmp_w]
        mov     [gfx_w], ax
        mov     ax, [tmp_h]
        mov     [gfx_h], ax
.done:
        pop     bp
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

DrawString:
        push    ax
        push    bx
        push    cx
        push    dx
        push    si

        mov     si, [gfx_strptr]
        mov     bx, [gfx_x]
.lp:
        mov     al, [si]
        cmp     al, 0
        je      .done
        call    DrawCh
        mov     al, [gfx_scale]
        xor     ah, ah
        mov     cx, 7
        mul     cx
        add     [gfx_x], ax
        inc     si
        jmp     .lp
.done:
        mov     [gfx_x], bx
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

DrawStringCenter:
        push    ax
        push    bx
        push    cx
        push    dx
        push    si

        mov     si, [gfx_strptr]
        xor     cx, cx
.cnt:
        cmp     byte [si], 0
        je      .have
        inc     cx
        inc     si
        jmp     .cnt
.have:
        mov     ax, cx
        mov     bx, 7
        mul     bx
        mov     bl, [gfx_scale]
        xor     bh, bh
        mul     bx
        mov     bx, SCREEN_W
        sub     bx, ax
        shr     bx, 1
        mov     [gfx_x], bx
        call    DrawString

        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

DrawNumber:
        push    ax
        push    bx
        push    cx
        push    dx
        push    si

        mov     bx, 10
        xor     cx, cx
        cmp     ax, 0
        jne     .div_lp
        push    ax
        mov     ax, '0'
        call    DrawCh
        mov     al, [gfx_scale]
        xor     ah, ah
        mov     bx, 7
        mul     bx
        add     [gfx_x], ax
        pop     ax
        jmp     .done
.div_lp:
        cmp     ax, 0
        je      .pop_lp
        xor     dx, dx
        div     bx
        push    dx
        inc     cx
        jmp     .div_lp
.pop_lp:
        cmp     cx, 0
        je      .done
        pop     ax
        add     al, '0'
        call    DrawCh
        push    ax
        push    cx
        mov     al, [gfx_scale]
        xor     ah, ah
        mov     bx, 7
        mul     bx
        add     [gfx_x], ax
        pop     cx
        pop     ax
        dec     cx
        jmp     .pop_lp
.done:
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

; ============================================================================
; DrawTokens: AX = half-tokens count. Draws "N" or "N.5" at gfx_x/gfx_y
; ============================================================================
DrawTokens:
        push    ax
        push    bx
        push    cx
        push    dx
        ; full = ax / 2, half = ax & 1
        mov     bx, ax
        shr     ax, 1               ; full count
        and     bx, 1               ; remainder (0 or 1)
        push    bx
        ; draw full count
        call    DrawNumber
        pop     bx
        cmp     bx, 0
        je      .done
        ; draw ".5"
        mov     al, '.'
        call    DrawCh
        mov     al, [gfx_scale]
        xor     ah, ah
        mov     bx, 7
        mul     bx
        add     [gfx_x], ax
        mov     al, '5'
        call    DrawCh
        mov     al, [gfx_scale]
        xor     ah, ah
        mov     bx, 7
        mul     bx
        add     [gfx_x], ax
.done:
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

; ============================================================================
; FONT DATA
; ============================================================================
font_data:
        db 0,0,0,0,0,0,0,0
        db 20h,20h,20h,20h,20h,0,20h,0
        db 50h,50h,0,0,0,0,0,0
        db 50h,50h,0F8h,50h,0F8h,50h,50h,0
        db 20h,78h,0A0h,70h,28h,0F0h,20h,0
        db 0C0h,0C8h,10h,20h,40h,98h,18h,0
        db 60h,90h,0A0h,40h,0A8h,90h,68h,0
        db 20h,20h,0,0,0,0,0,0
        db 10h,20h,40h,40h,40h,20h,10h,0
        db 40h,20h,10h,10h,10h,20h,40h,0
        db 0,50h,20h,0F8h,20h,50h,0,0
        db 0,20h,20h,0F8h,20h,20h,0,0
        db 0,0,0,0,0,30h,30h,20h
        db 0,0,0,0F8h,0,0,0,0
        db 0,0,0,0,0,30h,30h,0
        db 8,10h,20h,20h,40h,80h,80h,0
        db 70h,88h,98h,0A8h,0C8h,88h,70h,0
        db 20h,60h,20h,20h,20h,20h,70h,0
        db 70h,88h,8,30h,40h,80h,0F8h,0
        db 70h,88h,8,30h,8,88h,70h,0
        db 10h,30h,50h,90h,0F8h,10h,10h,0
        db 0F8h,80h,0F0h,8,8,88h,70h,0
        db 30h,40h,80h,0F0h,88h,88h,70h,0
        db 0F8h,8,10h,20h,40h,40h,40h,0
        db 70h,88h,88h,70h,88h,88h,70h,0
        db 70h,88h,88h,78h,8,10h,60h,0
        db 0,30h,30h,0,30h,30h,0,0
        db 0,30h,30h,0,30h,30h,20h,0
        db 10h,20h,40h,80h,40h,20h,10h,0
        db 0,0,0F8h,0,0F8h,0,0,0
        db 40h,20h,10h,8,10h,20h,40h,0
        db 70h,88h,8,10h,20h,0,20h,0
        db 70h,88h,98h,0A8h,98h,80h,70h,0
        db 20h,50h,88h,88h,0F8h,88h,88h,0
        db 0F0h,88h,88h,0F0h,88h,88h,0F0h,0
        db 70h,88h,80h,80h,80h,88h,70h,0
        db 0F0h,88h,88h,88h,88h,88h,0F0h,0
        db 0F8h,80h,80h,0F0h,80h,80h,0F8h,0
        db 0F8h,80h,80h,0F0h,80h,80h,80h,0
        db 70h,88h,80h,98h,88h,88h,70h,0
        db 88h,88h,88h,0F8h,88h,88h,88h,0
        db 70h,20h,20h,20h,20h,20h,70h,0
        db 38h,10h,10h,10h,10h,90h,60h,0
        db 88h,90h,0A0h,0C0h,0A0h,90h,88h,0
        db 80h,80h,80h,80h,80h,80h,0F8h,0
        db 88h,0D8h,0A8h,88h,88h,88h,88h,0
        db 88h,0C8h,0A8h,98h,88h,88h,88h,0
        db 70h,88h,88h,88h,88h,88h,70h,0
        db 0F0h,88h,88h,0F0h,80h,80h,80h,0
        db 70h,88h,88h,88h,0A8h,90h,68h,0
        db 0F0h,88h,88h,0F0h,0A0h,90h,88h,0
        db 70h,88h,80h,70h,8,88h,70h,0
        db 0F8h,20h,20h,20h,20h,20h,20h,0
        db 88h,88h,88h,88h,88h,88h,70h,0
        db 88h,88h,88h,88h,88h,50h,20h,0
        db 88h,88h,88h,88h,0A8h,0D8h,88h,0
        db 88h,88h,50h,20h,50h,88h,88h,0
        db 88h,88h,88h,50h,20h,20h,20h,0
        db 0F8h,8,10h,20h,40h,80h,0F8h,0

; ============================================================================
; RANDOM
; ============================================================================
InitRandom:
        push    ax
        push    cx
        push    dx
        mov     ah, 0
        int     1Ah
        mov     ax, dx
        or      ax, cx
        cmp     ax, 0
        jne     .ok
        mov     ax, 1
.ok:    mov     [g_seed], ax
        pop     dx
        pop     cx
        pop     ax
        ret

Random:
        push    bx
        push    dx
        mov     ax, [g_seed]
        mov     bx, 25173
        mul     bx
        add     ax, 13849
        mov     [g_seed], ax
        pop     dx
        pop     bx
        ret

RandomRange:
        push    dx
        call    Random
        xor     dx, dx
        div     bx
        mov     ax, dx
        pop     dx
        ret

; ============================================================================
; INPUT
; ============================================================================
WaitKey:
        mov     ah, 0
        int     16h
        ret

FlushKeys:
        push    ax
.lp:    mov     ah, 1
        int     16h
        jz      .done
        mov     ah, 0
        int     16h
        jmp     .lp
.done:
        pop     ax
        ret

; CheckKey: non-blocking. ZF=1 if no key. AH=scan, AL=ASCII.
CheckKey:
        mov     ah, 1
        int     16h
        jz      .none
        mov     ah, 0
        int     16h
        ; clear ZF (we have a key)
        or      al, al
        jnz     .done
        ; key was 0 ASCII (extended) — still a key, set NZ
        cmp     ah, 0
.done:
        ret
.none:
        ; ZF already set
        ret

; ReadTicks: returns AX = low word of BIOS tick counter
ReadTicks:
        push    cx
        push    dx
        mov     ah, 0
        int     1Ah
        mov     ax, dx
        pop     dx
        pop     cx
        ret

; ============================================================================
; DELAY
; ============================================================================
Delay:
        push    ax
        push    bx
        push    cx
        push    dx
        mov     bx, 1000
        mul     bx
        mov     cx, dx
        mov     dx, ax
        mov     ah, 86h
        int     15h
        jnc     .done
        mov     ah, 0
        int     1Ah
        mov     bx, dx
.lp:
        mov     ah, 0
        int     1Ah
        sub     dx, bx
        cmp     dx, 1
        jb      .lp
.done:
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

; ============================================================================
; PC SPEAKER SOUND
; ============================================================================
SpkOn:
        push    ax
        push    bx
        push    cx
        push    dx
        cmp     ax, 0
        je      .off
        mov     bx, ax
        mov     dx, 0012h
        mov     ax, 348Ch
        div     bx
        mov     bx, ax
        mov     al, 10110110b
        out     43h, al
        mov     al, bl
        out     42h, al
        mov     al, bh
        out     42h, al
        in      al, 61h
        or      al, 3
        out     61h, al
        jmp     .done
.off:
        in      al, 61h
        and     al, 0FCh
        out     61h, al
.done:
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

SpkOff:
        push    ax
        in      al, 61h
        and     al, 0FCh
        out     61h, al
        pop     ax
        ret

PlaySfxSpk:
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
.lp:
        mov     ax, [si]
        cmp     ax, 0
        je      .done
        call    SpkOn
        mov     ax, [si+2]
        call    Delay
        call    SpkOff
        mov     ax, 10
        call    Delay
        add     si, 4
        jmp     .lp
.done:
        call    SpkOff
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

DetectSB:
        push    ax
        push    cx
        push    dx
        mov     dx, SB_RESET
        mov     al, 1
        out     dx, al
        mov     cx, 200
.d1:    loop    .d1
        xor     al, al
        out     dx, al
        mov     cx, 100
.w:
        mov     dx, SB_POLL
        in      al, dx
        test    al, 80h
        jnz     .rd
        loop    .w
        jmp     .nope
.rd:
        mov     dx, SB_READ
        in      al, dx
        cmp     al, 0AAh
        jne     .nope
        mov     byte [g_hassb], 1
        jmp     .done
.nope:
        mov     byte [g_hassb], 0
.done:
        pop     dx
        pop     cx
        pop     ax
        ret

PlaySfx:
        call    BgMusic_Pause
        call    PlaySfxSpk
        call    BgMusic_Resume
        ret

; ============================================================================
; BACKGROUND MUSIC ENGINE  (INT 8h timer hook, ~18.2 Hz)
;
; Music table format: dw freq, ticks   (freq=0 → silence; ticks=0 → loop)
; ============================================================================

; --- Install: save old INT 8h, hook ours ---
BgMusic_Install:
        push    ax
        push    bx
        push    es

        ; Save old INT 8h vector
        mov     ax, 3508h
        int     21h
        mov     [bg_old8_off], bx
        mov     [bg_old8_seg], es

        ; Install new ISR
        push    ds
        mov     ax, cs
        mov     ds, ax
        mov     dx, BgMusic_ISR
        mov     ax, 2508h
        int     21h
        pop     ds

        ; Init state
        mov     word [bg_note_ptr], bg_melody
        mov     word [bg_tick_cnt], 1

        pop     es
        pop     bx
        pop     ax
        ret

; --- Remove: restore old INT 8h, silence speaker ---
BgMusic_Remove:
        push    ax
        push    dx
        push    ds

        call    SpkOff

        mov     ax, [bg_old8_seg]
        mov     ds, ax
        mov     dx, [bg_old8_off]
        mov     ax, 2508h
        int     21h

        pop     ds
        pop     dx
        pop     ax
        ret

; --- Start: enable music playback ---
BgMusic_Start:
        mov     byte [bg_active], 1
        ret

; --- Stop: disable music playback (silences speaker) ---
BgMusic_Stop:
        mov     byte [bg_active], 0
        call    SpkOff
        ret

; --- Pause: mute speaker but keep position (used during SFX) ---
BgMusic_Pause:
        push    ax
        inc     byte [bg_paused]
        call    SpkOff
        pop     ax
        ret

; --- Resume: un-mute (re-enable ISR-driven output) ---
BgMusic_Resume:
        push    ax
        cmp     byte [bg_paused], 0
        je      .done
        dec     byte [bg_paused]
.done:
        pop     ax
        ret

; --- ISR: called ~18 times per second by hardware timer ---
BgMusic_ISR:
        push    ax
        push    bx
        push    si
        push    ds

        ; Point DS at our data segment (CS = DS for .COM files)
        mov     ax, cs
        mov     ds, ax

        ; Check if active and not paused
        cmp     byte [bg_active], 0
        je      .chain
        cmp     byte [bg_paused], 0
        jne     .chain

        ; Decrement tick counter
        dec     word [bg_tick_cnt]
        jnz     .chain

        ; Advance to next note
        mov     si, [bg_note_ptr]

        ; Read ticks (second word). ticks=0 means loop back.
        mov     bx, [si+2]
        cmp     bx, 0
        jne     .play
        ; Loop: reset pointer to start of melody
        mov     si, bg_melody
        mov     bx, [si+2]

.play:
        ; Store new tick count
        mov     [bg_tick_cnt], bx

        ; Read frequency (first word)
        mov     ax, [si]
        cmp     ax, 0
        je      .silence

        ; Program speaker with this frequency
        ; divisor = 0x1234DC / freq  (we use 0x348C / freq as approx for timer2)
        push    bx
        mov     bx, ax
        mov     dx, 0012h
        mov     ax, 348Ch
        div     bx
        mov     bx, ax
        mov     al, 10110110b
        out     43h, al
        mov     al, bl
        out     42h, al
        mov     al, bh
        out     42h, al
        in      al, 61h
        or      al, 3
        out     61h, al
        pop     bx
        jmp     .advance

.silence:
        call    SpkOff

.advance:
        ; Move pointer to next entry (4 bytes per note)
        add     si, 4
        mov     [bg_note_ptr], si

.chain:
        pop     ds
        pop     si
        pop     bx
        pop     ax

        ; Chain to old INT 8h
        pushf
        call    far [cs:bg_old8_off]
        iret

; ============================================================================
; FILE I/O - HIGH SCORES
; ============================================================================
; ============================================================================
; LoadSingleScores: read SINGLE_SCORES.DAT into g_single_scores
; ============================================================================
LoadSingleScores:
        push    ax
        push    bx
        push    cx
        push    dx
        mov     ax, 3D00h
        mov     dx, SINGLE_SCORES_FILE
        int     21h
        jc      .none
        mov     bx, ax
        mov     ah, 3Fh
        mov     cx, 10*18
        mov     dx, g_single_scores
        int     21h
        mov     ah, 3Eh
        int     21h
.none:
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

; ============================================================================
; SaveSingleScores: write g_single_scores to SINGLE_SCORES.DAT
; ============================================================================
SaveSingleScores:
        push    ax
        push    bx
        push    cx
        push    dx
        mov     ah, 3Ch
        mov     cx, 0
        mov     dx, SINGLE_SCORES_FILE
        int     21h
        jc      .done
        mov     bx, ax
        mov     ah, 40h
        mov     cx, 10*18
        mov     dx, g_single_scores
        int     21h
        mov     ah, 3Eh
        int     21h
.done:
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

; ============================================================================
; LoadDuelScores: read DUEL_SCORES.DAT into g_duel_scores
; ============================================================================
LoadDuelScores:
        push    ax
        push    bx
        push    cx
        push    dx
        mov     ax, 3D00h
        mov     dx, DUEL_SCORES_FILE
        int     21h
        jc      .none
        mov     bx, ax
        mov     ah, 3Fh
        mov     cx, 10*18
        mov     dx, g_duel_scores
        int     21h
        mov     ah, 3Eh
        int     21h
.none:
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

; ============================================================================
; SaveDuelScores: write g_duel_scores to DUEL_SCORES.DAT
; ============================================================================
SaveDuelScores:
        push    ax
        push    bx
        push    cx
        push    dx
        mov     ah, 3Ch
        mov     cx, 0
        mov     dx, DUEL_SCORES_FILE
        int     21h
        jc      .done
        mov     bx, ax
        mov     ah, 40h
        mov     cx, 10*18
        mov     dx, g_duel_scores
        int     21h
        mov     ah, 3Eh
        int     21h
.done:
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret


; ============================================================================
; AddSingleScore / AddDuelScore
;   Thin wrappers: set the active score table then call the shared core.
;   SI -> name string, AX = score (half-tokens)
; ============================================================================
AddSingleScore:
        mov     word [score_tbl_base], g_single_scores
        jmp     AddScoreToTable

AddDuelScore:
        mov     word [score_tbl_base], g_duel_scores
        jmp     AddScoreToTable

; ============================================================================
; AddScoreToTable: Add/update a score entry.
;   SI -> name string (up to 15 chars + null)
;   AX = score (half-tokens)
;   score_tbl_base must be set by caller (via AddSingleScore/AddDuelScore)
;
; Rules:
;   1. If the player already exists in the table, update only if new score
;      is strictly higher; otherwise ignore.
;   2. If the player does not exist and all 10 slots are filled, only insert
;      if the new score beats the lowest entry (slot 9 after sort).
;   3. After inserting or updating, re-sort the table descending by score.
AddScoreToTable:
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    es

        ; BX = new score,  SI = name pointer (caller-provided)
        mov     bx, ax

        ; ------------------------------------------------------------------
        ; Phase 1: search for an existing entry with the same name.
        ; ------------------------------------------------------------------
        push    ds
        pop     es                      ; ES = DS for string ops

        mov     di, [score_tbl_base]
        xor     cx, cx                  ; cx = slot index
.find_dup:
        cmp     cx, 10
        jae     .no_dup
        cmp     byte [di], 0            ; empty slot -> stop searching
        je      .no_dup

        ; Compare name: up to 15 chars (we only care about first 15 + null)
        push    cx
        push    si
        push    di
        mov     cx, 15
.cmp_name:
        mov     al, [si]
        mov     ah, [di]
        cmp     al, ah
        jne     .cmp_ne
        cmp     al, 0
        je      .cmp_eq             ; both null -> strings match
        inc     si
        inc     di
        loop    .cmp_name
        ; fell through 15 chars without difference -> treat as match
.cmp_eq:
        pop     di
        pop     si
        pop     cx
        ; Found a duplicate. Update only if new score is higher.
        cmp     bx, [di+16]
        jbe     .done               ; new score not better -> ignore
        mov     [di+16], bx         ; overwrite score in place
        jmp     .sort               ; re-sort
.cmp_ne:
        pop     di
        pop     si
        pop     cx
        add     di, 18
        inc     cx
        jmp     .find_dup

.no_dup:
        ; ------------------------------------------------------------------
        ; Phase 2: player not found. Find insertion point.
        ;   - If fewer than 10 entries exist, write into the first empty slot.
        ;   - Otherwise replace slot 9 only if new score > slot 9's score.
        ; ------------------------------------------------------------------
        ; Find first empty slot (name byte = 0) or end of table.
        mov     di, [score_tbl_base]
        xor     cx, cx
.find_empty:
        cmp     cx, 10
        jae     .table_full
        cmp     byte [di], 0
        je      .write_slot
        add     di, 18
        inc     cx
        jmp     .find_empty

.table_full:
        ; All 10 slots used. Replace slot 9 only if new score > slot 9.
        mov     di, [score_tbl_base]
        add     di, 9*18
        cmp     bx, [di+16]
        jbe     .done               ; new score not better than worst -> drop

.write_slot:
        ; Write new entry at DI (either empty slot or slot 9 being replaced).
        push    si
        push    di
        push    cx
        ; Copy name (up to 15 chars + ensure null terminator at byte 15)
        mov     cx, 15
.cp_name:
        mov     al, [si]
        mov     [di], al
        cmp     al, 0
        je      .cp_pad
        inc     si
        inc     di
        loop    .cp_name
        ; force null terminator at position 15
        mov     byte [di], 0
        jmp     .cp_done
.cp_pad:
        ; already wrote null; zero remaining bytes
        inc     di
        dec     cx
        jz      .cp_done
.cp_pad_lp:
        mov     byte [di], 0
        inc     di
        loop    .cp_pad_lp
.cp_done:
        pop     cx
        pop     di
        pop     si
        mov     [di+16], bx         ; store score word

        ; ------------------------------------------------------------------
        ; Phase 3: Bubble-sort the table descending by score.
        ;   Only occupied entries (name[0] != 0) are considered; empty slots
        ;   naturally sink to the bottom (score 0).
        ; ------------------------------------------------------------------
.sort:
        ; Simple bubble sort over 10 slots.
        mov     dx, 10              ; outer pass count
.outer:
        dec     dx
        jz      .done
        mov     di, [score_tbl_base]
        mov     cx, dx              ; inner compare count
.inner:
        cmp     cx, 0
        je      .outer
        mov     ax, [di+16]         ; score of slot i
        mov     bx, [di+16+18]      ; score of slot i+1
        cmp     ax, bx
        jae     .no_swap            ; already in order
        ; Swap the two 18-byte entries at DI and DI+18
        push    cx
        push    dx
        push    di
        mov     cx, 9               ; 9 words = 18 bytes
.swap_lp:
        mov     ax,  [di]
        mov     bx,  [di+18]
        mov     [di],    bx
        mov     [di+18], ax
        add     di, 2
        loop    .swap_lp
        pop     di
        pop     dx
        pop     cx
.no_swap:
        add     di, 18
        dec     cx
        jmp     .inner

.done:
        pop     es
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

; ============================================================================
; ANIMAL SPRITES
; ============================================================================

DrawChicken:
        push    ax
        push    bx
        mov     ax, [gfx_x]
        mov     [tmp_x], ax
        mov     ax, [gfx_y]
        mov     [tmp_y], ax

        mov     ax, [tmp_x]
        add     ax, 6
        mov     [gfx_x], ax
        mov     ax, [tmp_y]
        mov     [gfx_y], ax
        mov     word [gfx_w], 6
        mov     word [gfx_h], 2
        mov     byte [gfx_color], C_COMB
        call    FillRect

        mov     ax, [tmp_x]
        add     ax, 6
        mov     [gfx_x], ax
        mov     ax, [tmp_y]
        sub     ax, 1
        mov     [gfx_y], ax
        mov     word [gfx_w], 2
        mov     word [gfx_h], 1
        call    FillRect
        mov     ax, [tmp_x]
        add     ax, 10
        mov     [gfx_x], ax
        call    FillRect

        mov     ax, [tmp_x]
        add     ax, 4
        mov     [gfx_x], ax
        mov     ax, [tmp_y]
        add     ax, 2
        mov     [gfx_y], ax
        mov     word [gfx_w], 10
        mov     word [gfx_h], 9
        mov     byte [gfx_color], C_WHITE
        call    FillRect

        mov     ax, [tmp_x]
        add     ax, 11
        mov     [gfx_x], ax
        mov     ax, [tmp_y]
        add     ax, 4
        mov     [gfx_y], ax
        mov     word [gfx_w], 1
        mov     word [gfx_h], 1
        mov     byte [gfx_color], C_BLACK
        call    FillRect

        mov     ax, [tmp_x]
        add     ax, 14
        mov     [gfx_x], ax
        mov     ax, [tmp_y]
        add     ax, 5
        mov     [gfx_y], ax
        mov     word [gfx_w], 2
        mov     word [gfx_h], 2
        mov     byte [gfx_color], C_BEAK
        call    FillRect

        mov     ax, [tmp_x]
        add     ax, 6
        mov     [gfx_x], ax
        mov     ax, [tmp_y]
        add     ax, 11
        mov     [gfx_y], ax
        mov     word [gfx_w], 1
        mov     word [gfx_h], 4
        call    FillRect
        mov     ax, [tmp_x]
        add     ax, 11
        mov     [gfx_x], ax
        call    FillRect

        mov     ax, [tmp_x]
        mov     [gfx_x], ax
        mov     ax, [tmp_y]
        mov     [gfx_y], ax
        pop     bx
        pop     ax
        ret

DrawCow:
        push    ax
        push    bx
        mov     ax, [gfx_x]
        mov     [tmp_x], ax
        mov     ax, [gfx_y]
        mov     [tmp_y], ax

        mov     ax, [tmp_x]
        add     ax, 14
        mov     [gfx_x], ax
        mov     ax, [tmp_y]
        add     ax, 1
        mov     [gfx_y], ax
        mov     word [gfx_w], 6
        mov     word [gfx_h], 6
        mov     byte [gfx_color], C_WHITE
        call    FillRect

        mov     ax, [tmp_x]
        add     ax, 16
        mov     [gfx_x], ax
        mov     ax, [tmp_y]
        add     ax, 2
        mov     [gfx_y], ax
        mov     word [gfx_w], 3
        mov     word [gfx_h], 2
        mov     byte [gfx_color], C_COW_BLACK
        call    FillRect

        mov     ax, [tmp_x]
        add     ax, 17
        mov     [gfx_x], ax
        mov     ax, [tmp_y]
        add     ax, 5
        mov     [gfx_y], ax
        mov     word [gfx_w], 1
        mov     word [gfx_h], 1
        call    FillRect

        mov     ax, [tmp_x]
        mov     [gfx_x], ax
        mov     ax, [tmp_y]
        add     ax, 4
        mov     [gfx_y], ax
        mov     word [gfx_w], 14
        mov     word [gfx_h], 7
        mov     byte [gfx_color], C_WHITE
        call    FillRect

        mov     ax, [tmp_x]
        add     ax, 2
        mov     [gfx_x], ax
        mov     ax, [tmp_y]
        add     ax, 5
        mov     [gfx_y], ax
        mov     word [gfx_w], 4
        mov     word [gfx_h], 3
        mov     byte [gfx_color], C_COW_BLACK
        call    FillRect

        mov     ax, [tmp_x]
        add     ax, 8
        mov     [gfx_x], ax
        mov     ax, [tmp_y]
        add     ax, 6
        mov     [gfx_y], ax
        mov     word [gfx_w], 4
        mov     word [gfx_h], 3
        call    FillRect

        mov     ax, [tmp_x]
        add     ax, 1
        mov     [gfx_x], ax
        mov     ax, [tmp_y]
        add     ax, 11
        mov     [gfx_y], ax
        mov     word [gfx_w], 2
        mov     word [gfx_h], 3
        mov     byte [gfx_color], C_WHITE
        call    FillRect
        mov     ax, [tmp_x]
        add     ax, 11
        mov     [gfx_x], ax
        call    FillRect

        mov     ax, [tmp_x]
        mov     [gfx_x], ax
        mov     ax, [tmp_y]
        mov     [gfx_y], ax
        pop     bx
        pop     ax
        ret

DrawPig:
        push    ax
        push    bx
        mov     ax, [gfx_x]
        mov     [tmp_x], ax
        mov     ax, [gfx_y]
        mov     [tmp_y], ax

        mov     ax, [tmp_x]
        mov     [gfx_x], ax
        mov     ax, [tmp_y]
        add     ax, 2
        mov     [gfx_y], ax
        mov     word [gfx_w], 12
        mov     word [gfx_h], 7
        mov     byte [gfx_color], C_PINK
        call    FillRect

        mov     ax, [tmp_x]
        add     ax, 11
        mov     [gfx_x], ax
        mov     ax, [tmp_y]
        add     ax, 1
        mov     [gfx_y], ax
        mov     word [gfx_w], 5
        mov     word [gfx_h], 6
        call    FillRect

        mov     ax, [tmp_x]
        add     ax, 12
        mov     [gfx_x], ax
        mov     ax, [tmp_y]
        mov     [gfx_y], ax
        mov     word [gfx_w], 2
        mov     word [gfx_h], 2
        call    FillRect

        mov     ax, [tmp_x]
        add     ax, 15
        mov     [gfx_x], ax
        mov     ax, [tmp_y]
        add     ax, 3
        mov     [gfx_y], ax
        mov     word [gfx_w], 2
        mov     word [gfx_h], 3
        mov     byte [gfx_color], C_PIG_DK
        call    FillRect

        mov     ax, [tmp_x]
        add     ax, 13
        mov     [gfx_x], ax
        mov     ax, [tmp_y]
        add     ax, 3
        mov     [gfx_y], ax
        mov     word [gfx_w], 1
        mov     word [gfx_h], 1
        mov     byte [gfx_color], C_BLACK
        call    FillRect

        mov     ax, [tmp_x]
        add     ax, 1
        mov     [gfx_x], ax
        mov     ax, [tmp_y]
        add     ax, 9
        mov     [gfx_y], ax
        mov     word [gfx_w], 2
        mov     word [gfx_h], 3
        mov     byte [gfx_color], C_PIG_DK
        call    FillRect
        mov     ax, [tmp_x]
        add     ax, 9
        mov     [gfx_x], ax
        call    FillRect

        mov     ax, [tmp_x]
        mov     [gfx_x], ax
        mov     ax, [tmp_y]
        mov     [gfx_y], ax
        pop     bx
        pop     ax
        ret

DrawAnimal:
        push    ax
        cmp     al, ANIM_CHICKEN
        jne     .ck_cow
        call    DrawChicken
        jmp     .done
.ck_cow:
        cmp     al, ANIM_COW
        jne     .pig
        call    DrawCow
        jmp     .done
.pig:
        call    DrawPig
.done:
        pop     ax
        ret

; ============================================================================
; UI HELPERS
; ============================================================================

DrawFooter:
        push    ax
        push    bx

        ; Green bar y=183..199
        mov     word [gfx_x], 0
        mov     word [gfx_y], 183
        mov     word [gfx_w], 320
        mov     word [gfx_h], 17
        mov     byte [gfx_color], C_GRASS
        call    FillRect
        ; Inner dark inset
        mov     word [gfx_x], 2
        mov     word [gfx_y], 185
        mov     word [gfx_w], 316
        mov     word [gfx_h], 13
        mov     byte [gfx_color], C_GRASS_DK
        call    FillRect

        ; All text scale 1, same y=191
        ; Left half: "ENTER" (35px) + 4px gap + "OK" (14px) = 53px total
        ;   centered in 0..160 -> start x = (160-53)/2 = 53
        ; Right half: "ESC" (21px) + 4px gap + "BACK" (28px) = 53px total
        ;   centered in 160..320 -> start x = 160 + (160-53)/2 = 213
        mov     byte [gfx_scale], 1

        ; "ENTER" in gold
        mov     byte [gfx_color], C_GOLD
        mov     word [gfx_x], 53
        mov     word [gfx_y], 191
        mov     word [gfx_strptr], str_key_enter
        call    DrawString

        ; "OK" in white
        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_x], 92
        mov     word [gfx_y], 191
        mov     word [gfx_strptr], str_lbl_ok
        call    DrawString

        ; vertical separator in the middle
        mov     word [gfx_x], 159
        mov     word [gfx_y], 187
        mov     word [gfx_w], 2
        mov     word [gfx_h], 9
        mov     byte [gfx_color], C_GRASS
        call    FillRect

        ; "ESC" in gold
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_GOLD
        mov     word [gfx_x], 213
        mov     word [gfx_y], 191
        mov     word [gfx_strptr], str_key_esc
        call    DrawString

        ; "BACK" in white
        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_x], 238
        mov     word [gfx_y], 191
        mov     word [gfx_strptr], str_lbl_back
        call    DrawString

        pop     bx
        pop     ax
        ret

DrawTitleBig:
        push    ax
        push    bx
        mov     bx, ax

        mov     byte [gfx_scale], 3
        mov     byte [gfx_color], C_TITLE_O
        mov     word [gfx_strptr], str_title1
        mov     [gfx_y], bx
        call    DrawStringCenter

        add     bx, 28
        mov     byte [gfx_color], C_TITLE_G
        mov     word [gfx_strptr], str_title2
        mov     [gfx_y], bx
        call    DrawStringCenter

        add     bx, 28
        mov     byte [gfx_color], C_TITLE_Y
        mov     word [gfx_strptr], str_title3
        mov     [gfx_y], bx
        call    DrawStringCenter

        pop     bx
        pop     ax
        ret

DrawButton:
        push    ax
        call    FillRect
        mov     al, [gfx_color2]
        mov     ah, [gfx_color]
        mov     [tmp_save_color], ah
        mov     [gfx_color], al
        call    FrameRect
        mov     al, [tmp_save_color]
        mov     [gfx_color], al

        push    word [gfx_y]
        mov     ax, [gfx_h]
        sub     ax, 16
        shr     ax, 1
        add     ax, [gfx_y]
        mov     [gfx_y], ax
        mov     byte [gfx_scale], 2
        mov     byte [gfx_color], C_WHITE
        call    DrawStringCenter
        pop     word [gfx_y]
        pop     ax
        ret

; ----------------------------------------------------------------------------
; DrawScorePanels: P1 panel always; P2 panel only if 2P mode
; Highlights the active player's panel with bright border + arrow
; Shows tokens with .5 suffix when applicable
; ----------------------------------------------------------------------------
DrawScorePanels:
        push    ax
        push    bx

        ; ---- P1 panel ----
        mov     word [gfx_x], 8
        mov     word [gfx_y], 175
        mov     word [gfx_w], 110
        mov     word [gfx_h], 22
        mov     byte [gfx_color], C_GREEN
        call    FillRect

        ; Border: bright gold if active in 2P, else white
        mov     byte [gfx_color], C_WHITE
        cmp     byte [g_mode], MODE_2P
        jne     .p1_bord
        cmp     byte [g_curplayer], 1
        jne     .p1_bord
        mov     byte [gfx_color], C_GOLD
        ; Draw double border by drawing once, expanding, drawing again
        call    FrameRect
        mov     word [gfx_x], 7
        mov     word [gfx_y], 174
        mov     word [gfx_w], 112
        mov     word [gfx_h], 24
        call    FrameRect
        mov     word [gfx_x], 8
        mov     word [gfx_y], 175
        mov     word [gfx_w], 110
        mov     word [gfx_h], 22
        jmp     .p1_label
.p1_bord:
        call    FrameRect

.p1_label:
        ; Player name (max 8 chars displayed at scale 1)
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_strptr], g_p1name
        mov     word [gfx_x], 12
        mov     word [gfx_y], 178
        cmp     byte [g_p1name], 0
        jne     .p1_drawname
        mov     word [gfx_strptr], str_p1lbl
.p1_drawname:
        call    DrawString

        ; Tokens label
        mov     byte [gfx_color], C_GOLD
        mov     word [gfx_strptr], str_tok
        mov     word [gfx_x], 12
        mov     word [gfx_y], 188
        call    DrawString

        ; Token count (scale 1, draw with .5)
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_x], 50
        mov     word [gfx_y], 188
        xor     ah, ah
        mov     al, [g_p1score]
        call    DrawTokens

        ; Round indicator on right (scale 1)
        mov     byte [gfx_color], C_DKGRAY
        mov     word [gfx_strptr], str_r_lbl
        mov     word [gfx_x], 80
        mov     word [gfx_y], 188
        call    DrawString

        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_x], 95
        mov     word [gfx_y], 188
        xor     ah, ah
        mov     al, [g_p1correct]
        call    DrawNumber
        mov     al, '/'
        call    DrawCh
        mov     al, [gfx_scale]
        xor     ah, ah
        mov     bx, 7
        mul     bx
        add     [gfx_x], ax
        xor     ah, ah
        mov     al, [g_p1total]
        call    DrawNumber

        cmp     byte [g_mode], MODE_2P
        je      .draw_p2
        ; ---- 1P mode: show STRIKES on right side ----
        mov     word [gfx_x], 200
        mov     word [gfx_y], 175
        mov     word [gfx_w], 110
        mov     word [gfx_h], 22
        mov     byte [gfx_color], C_RED
        call    FillRect
        mov     byte [gfx_color], C_WHITE
        call    FrameRect

        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_strptr], str_lives
        mov     word [gfx_x], 206
        mov     word [gfx_y], 178
        call    DrawString

        ; Draw 3 X marks, red filled = remaining lives, gray = lost
        mov     bx, 0
.life_lp:
        cmp     bx, MAX_STRIKES
        jae     .life_done
        ; pos x = 206 + bx*22
        mov     ax, bx
        push    bx
        mov     bx, 22
        mul     bx
        pop     bx
        add     ax, 206
        mov     [gfx_x], ax
        mov     word [gfx_y], 188

        ; lives remaining = MAX_STRIKES - g_strikes
        ; if bx < (MAX_STRIKES - strikes): show heart (red), else gray X
        push    bx
        xor     bh, bh
        mov     bl, [g_strikes]
        mov     ax, MAX_STRIKES
        sub     ax, bx
        pop     bx
        cmp     bx, ax
        jb      .life_full
        mov     byte [gfx_color], C_DKGRAY
        jmp     .life_dr
.life_full:
        mov     byte [gfx_color], C_TITLE_O
.life_dr:
        ; draw small heart-like 6x6 block
        mov     word [gfx_w], 8
        mov     word [gfx_h], 8
        call    FillRect
        ; black "v" cut
        push    word [gfx_x]
        push    word [gfx_y]
        mov     ax, [gfx_x]
        add     ax, 3
        mov     [gfx_x], ax
        mov     ax, [gfx_y]
        mov     [gfx_y], ax
        mov     word [gfx_w], 2
        mov     word [gfx_h], 2
        mov     byte [gfx_color], C_BLACK
        call    FillRect
        pop     word [gfx_y]
        pop     word [gfx_x]

        inc     bx
        jmp     .life_lp
.life_done:
        jmp     .done

.draw_p2:
        ; ---- P2 panel ----
        mov     word [gfx_x], 200
        mov     word [gfx_y], 175
        mov     word [gfx_w], 112
        mov     word [gfx_h], 22
        mov     byte [gfx_color], C_PURPLE
        call    FillRect

        mov     byte [gfx_color], C_WHITE
        cmp     byte [g_curplayer], 2
        jne     .p2_bord
        mov     byte [gfx_color], C_GOLD
        call    FrameRect
        mov     word [gfx_x], 199
        mov     word [gfx_y], 174
        mov     word [gfx_w], 114
        mov     word [gfx_h], 24
        call    FrameRect
        mov     word [gfx_x], 200
        mov     word [gfx_y], 175
        mov     word [gfx_w], 112
        mov     word [gfx_h], 22
        jmp     .p2_label
.p2_bord:
        call    FrameRect

.p2_label:
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_strptr], g_p2name
        mov     word [gfx_x], 204
        mov     word [gfx_y], 178
        cmp     byte [g_p2name], 0
        jne     .p2_drawname
        mov     word [gfx_strptr], str_p2lbl
.p2_drawname:
        call    DrawString

        mov     byte [gfx_color], C_GOLD
        mov     word [gfx_strptr], str_tok
        mov     word [gfx_x], 204
        mov     word [gfx_y], 188
        call    DrawString

        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_x], 242
        mov     word [gfx_y], 188
        xor     ah, ah
        mov     al, [g_p2score]
        call    DrawTokens

        mov     byte [gfx_color], C_DKGRAY
        mov     word [gfx_strptr], str_r_lbl
        mov     word [gfx_x], 272
        mov     word [gfx_y], 188
        call    DrawString

        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_x], 287
        mov     word [gfx_y], 188
        xor     ah, ah
        mov     al, [g_p2correct]
        call    DrawNumber
        mov     al, '/'
        call    DrawCh
        mov     al, [gfx_scale]
        xor     ah, ah
        mov     bx, 7
        mul     bx
        add     [gfx_x], ax
        xor     ah, ah
        mov     al, [g_p2total]
        call    DrawNumber
.done:
        pop     bx
        pop     ax
        ret

ParseInput:
        push    bx
        push    cx
        push    dx
        push    si
        xor     ax, ax
        mov     si, g_inbuf
.lp:
        mov     bl, [si]
        cmp     bl, 0
        je      .done
        cmp     bl, '0'
        jb      .done
        cmp     bl, '9'
        ja      .done
        sub     bl, '0'
        mov     cx, 10
        mul     cx
        xor     bh, bh
        add     ax, bx
        inc     si
        jmp     .lp
.done:
        pop     si
        pop     dx
        pop     cx
        pop     bx
        ret

CopyName:
        push    ax
        push    cx
        push    di
        push    si
        push    es
        push    ds
        pop     es
        mov     cx, 16
        rep     movsb
        pop     es
        pop     si
        pop     di
        pop     cx
        pop     ax
        ret

; ============================================================================
; STATE: START SCREEN
; ============================================================================
DoStart:
        push    ax
        mov     byte [gfx_color], C_BLACK
        call    ClearBack
        call    DrawScene

        mov     ax, 18
        call    DrawTitleBig

        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_strptr], str_press_start
        mov     word [gfx_y], 130
        call    DrawStringCenter

        mov     word [gfx_x], 80
        mov     word [gfx_y], 138
        mov     word [gfx_w], 14
        mov     word [gfx_h], 5
        mov     byte [gfx_color], C_GOLD
        call    FillRect
        mov     word [gfx_x], 226
        call    FillRect

        call    Flip
        call    FlushKeys
        call    WaitKey

        cmp     al, 27
        jne     .go
        mov     byte [g_state], ST_QUIT
        pop     ax
        ret
.go:
        call    TransFadeOut
        mov     si, sfx_start
        call    PlaySfx
        mov     byte [g_state], ST_TUTORIAL
        pop     ax
        ret

; ============================================================================
; STATE: TUTORIAL
; ============================================================================
DoTutorial:
        push    ax
        mov     byte [gfx_color], C_BLACK
        call    ClearBack
        call    DrawScene

        mov     byte [gfx_scale], 3
        mov     byte [gfx_color], C_TITLE_O
        mov     word [gfx_strptr], str_how_play
        mov     word [gfx_y], 8
        call    DrawStringCenter

        mov     word [gfx_x], 16
        mov     word [gfx_y], 44
        mov     word [gfx_w], 288
        mov     word [gfx_h], 110
        mov     byte [gfx_color], C_PANEL
        call    FillRect
        mov     byte [gfx_color], C_PANEL_BD
        call    FrameRect

        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_BLACK

        mov     word [gfx_strptr], str_tut1
        mov     word [gfx_y], 52
        call    DrawStringCenter

        mov     word [gfx_strptr], str_tut2
        mov     word [gfx_y], 64
        call    DrawStringCenter

        mov     word [gfx_strptr], str_tut3
        mov     word [gfx_y], 76
        call    DrawStringCenter

        mov     byte [gfx_color], C_BARN
        mov     word [gfx_strptr], str_tut4
        mov     word [gfx_y], 92
        call    DrawStringCenter

        mov     byte [gfx_color], C_BLACK
        mov     word [gfx_strptr], str_tut5
        mov     word [gfx_y], 108
        call    DrawStringCenter

        mov     word [gfx_strptr], str_tut6
        mov     word [gfx_y], 120
        call    DrawStringCenter

        mov     byte [gfx_color], C_BARN
        mov     word [gfx_strptr], str_tut7
        mov     word [gfx_y], 136
        call    DrawStringCenter

        call    DrawFooter
        call    Flip
        call    TransFadeIn

        call    FlushKeys
        call    WaitKey
        cmp     al, 27
        jne     .next
        call    TransFadeOut
        mov     byte [g_state], ST_START
        pop     ax
        ret
.next:
        call    TransFadeOut
        mov     si, sfx_click
        call    PlaySfx
        mov     byte [g_state], ST_MODE
        pop     ax
        ret

; ============================================================================
; STATE: MODE SELECT
; ============================================================================
DoMode:
        push    ax
        push    bx
        xor     bx, bx          ; BL=selection, BH=first-draw flag
        mov     bh, 1           ; 1 = first draw (do fade-in)
.redraw:
        mov     byte [gfx_color], C_BLACK
        call    ClearBack
        call    DrawScene

        mov     byte [gfx_scale], 3
        mov     byte [gfx_color], C_TITLE_O
        mov     word [gfx_strptr], str_select_mode
        mov     word [gfx_y], 14
        call    DrawStringCenter

        mov     word [gfx_x], 60
        mov     word [gfx_y], 60
        mov     word [gfx_w], 200
        mov     word [gfx_h], 22
        cmp     bl, 0
        je      .b1_sel
        mov     byte [gfx_color], C_GRAY
        jmp     .b1_set
.b1_sel:
        mov     byte [gfx_color], C_ORANGE
.b1_set:
        mov     byte [gfx_color2], C_WHITE
        mov     word [gfx_strptr], str_single
        call    DrawButton

        mov     word [gfx_x], 60
        mov     word [gfx_y], 95
        mov     word [gfx_w], 200
        mov     word [gfx_h], 22
        cmp     bl, 1
        je      .b2_sel
        mov     byte [gfx_color], C_GRAY
        jmp     .b2_set
.b2_sel:
        mov     byte [gfx_color], C_TEAL
.b2_set:
        mov     byte [gfx_color2], C_WHITE
        mov     word [gfx_strptr], str_duel
        call    DrawButton

        call    DrawFooter
        call    Flip

        ; Fade in only on first draw
        cmp     bh, 1
        jne     .no_fadein
        mov     bh, 0
        call    TransFadeIn
.no_fadein:

        call    FlushKeys
        call    WaitKey
        cmp     al, 27
        je      .back
        cmp     ah, 48h
        je      .up
        cmp     ah, 50h
        je      .dn
        cmp     al, 13
        je      .sel
        jmp     .redraw
.up:
        cmp     bl, 0
        jbe     .redraw
        dec     bl
        push    bx
        mov     si, sfx_click
        call    PlaySfx
        pop     bx
        jmp     .redraw
.dn:
        cmp     bl, 1
        jae     .redraw
        inc     bl
        push    bx
        mov     si, sfx_click
        call    PlaySfx
        pop     bx
        jmp     .redraw
.back:
        call    TransFadeOut
        mov     byte [g_state], ST_TUTORIAL
        pop     bx
        pop     ax
        ret
.sel:
        cmp     bl, 0
        jne     .duel
        mov     byte [g_mode], MODE_1P
        jmp     .done
.duel:
        mov     byte [g_mode], MODE_2P
.done:
        call    TransFadeOut
        mov     byte [g_state], ST_DIFFICULTY
        mov     si, sfx_click
        call    PlaySfx
        pop     bx
        pop     ax
        ret

; ============================================================================
; STATE: DIFFICULTY
; ============================================================================
DoDifficulty:
        push    ax
        push    bx
        xor     bx, bx
        mov     bh, 1           ; first-draw flag
.redraw:
        mov     byte [gfx_color], C_BLACK
        call    ClearBack
        call    DrawScene

        mov     byte [gfx_scale], 2
        mov     byte [gfx_color], C_TITLE_O
        mov     word [gfx_strptr], str_select_diff
        mov     word [gfx_y], 16
        call    DrawStringCenter

        mov     word [gfx_x], 70
        mov     word [gfx_y], 50
        mov     word [gfx_w], 180
        mov     word [gfx_h], 22
        cmp     bl, 0
        je      .e_sel
        mov     byte [gfx_color], C_GRAY
        jmp     .e_set
.e_sel:
        mov     byte [gfx_color], C_GREEN
.e_set:
        mov     byte [gfx_color2], C_WHITE
        mov     word [gfx_strptr], str_easy
        call    DrawButton

        mov     word [gfx_x], 70
        mov     word [gfx_y], 80
        mov     word [gfx_w], 180
        mov     word [gfx_h], 22
        cmp     bl, 1
        je      .m_sel
        mov     byte [gfx_color], C_GRAY
        jmp     .m_set
.m_sel:
        mov     byte [gfx_color], C_PURPLE
.m_set:
        mov     byte [gfx_color2], C_WHITE
        mov     word [gfx_strptr], str_medium
        call    DrawButton

        mov     word [gfx_x], 70
        mov     word [gfx_y], 110
        mov     word [gfx_w], 180
        mov     word [gfx_h], 22
        cmp     bl, 2
        je      .h_sel
        mov     byte [gfx_color], C_GRAY
        jmp     .h_set
.h_sel:
        mov     byte [gfx_color], C_RED
.h_set:
        mov     byte [gfx_color2], C_WHITE
        mov     word [gfx_strptr], str_hard
        call    DrawButton

        call    DrawFooter
        call    Flip

        cmp     bh, 1
        jne     .no_fi
        mov     bh, 0
        call    TransFadeIn
.no_fi:

        call    FlushKeys
        call    WaitKey
        cmp     al, 27
        je      .back
        cmp     ah, 48h
        je      .up
        cmp     ah, 50h
        je      .dn
        cmp     al, 13
        je      .sel
        jmp     .redraw
.up:
        cmp     bl, 0
        jbe     .redraw
        dec     bl
        push    bx
        mov     si, sfx_click
        call    PlaySfx
        pop     bx
        jmp     .redraw
.dn:
        cmp     bl, 2
        jae     .redraw
        inc     bl
        push    bx
        mov     si, sfx_click
        call    PlaySfx
        pop     bx
        jmp     .redraw
.back:
        call    TransFadeOut
        mov     byte [g_state], ST_MODE
        pop     bx
        pop     ax
        ret
.sel:
        inc     bl
        mov     [g_diff], bl
        ; Reset all game state
        mov     byte [g_p1score], 0
        mov     byte [g_p2score], 0
        mov     byte [g_p1total], 0
        mov     byte [g_p2total], 0
        mov     byte [g_p1correct], 0
        mov     byte [g_p2correct], 0
        mov     byte [g_strikes], 0
        mov     word [g_round], 1
        mov     byte [g_p1played], 0
        mov     byte [g_p2played], 0
        mov     byte [g_p1answered], 0
        mov     byte [g_p2answered], 0
        mov     word [g_p1time], 0
        mov     word [g_p2time], 0
        mov     byte [g_curplayer], 1
        mov     byte [g_p1name], 0
        mov     byte [g_p2name], 0
        call    TransFadeOut
        mov     byte [g_state], ST_P1PASS
        mov     si, sfx_click
        call    PlaySfx
        pop     bx
        pop     ax
        ret

; ============================================================================
; STATE: NAME ENTRY
; ============================================================================
DoNameEntry:
        push    ax
        push    bx
        push    cx
        push    di
        mov     bl, al

        cmp     bl, 1
        jne     .clr_p2
        mov     di, g_p1name
        jmp     .clr_do
.clr_p2:
        mov     di, g_p2name
.clr_do:
        mov     cx, 16
        xor     al, al
        push    es
        push    ds
        pop     es
        rep     stosb
        pop     es
        mov     byte [g_inlen], 0
        mov     byte [tr_firstdraw], 1  ; flag: fade in on first draw

.redraw:
        mov     byte [gfx_color], C_BLACK
        call    ClearBack
        call    DrawScene

        mov     byte [gfx_scale], 2
        mov     byte [gfx_color], C_TITLE_O
        mov     word [gfx_strptr], str_enter_name
        mov     word [gfx_y], 18
        call    DrawStringCenter

        mov     byte [gfx_scale], 2
        cmp     bl, 1
        jne     .lbl_p2
        mov     byte [gfx_color], C_GREEN
        mov     word [gfx_strptr], str_p1lbl
        jmp     .lbl_set
.lbl_p2:
        mov     byte [gfx_color], C_PURPLE
        mov     word [gfx_strptr], str_p2lbl
.lbl_set:
        mov     word [gfx_y], 48
        call    DrawStringCenter

        mov     word [gfx_x], 50
        mov     word [gfx_y], 80
        mov     word [gfx_w], 220
        mov     word [gfx_h], 30
        mov     byte [gfx_color], C_PANEL
        call    FillRect
        mov     byte [gfx_color], C_PANEL_BD
        call    FrameRect

        mov     byte [gfx_scale], 2
        mov     byte [gfx_color], C_BLACK
        cmp     bl, 1
        jne     .txt_p2
        mov     word [gfx_strptr], g_p1name
        jmp     .txt_set
.txt_p2:
        mov     word [gfx_strptr], g_p2name
.txt_set:
        mov     word [gfx_y], 88
        call    DrawStringCenter

        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_DKGRAY
        mov     word [gfx_strptr], str_press_any
        mov     word [gfx_y], 145
        call    DrawStringCenter

        call    DrawFooter
        call    Flip

        cmp     byte [tr_firstdraw], 1
        jne     .no_fi_name
        mov     byte [tr_firstdraw], 0
        call    TransFadeIn
.no_fi_name:

        call    WaitKey
        cmp     al, 27
        je      .back
        cmp     al, 13
        je      .commit
        cmp     al, 8
        je      .bs
        cmp     al, ' '
        jb      .redraw
        cmp     al, 'z'
        ja      .redraw
        cmp     al, 'a'
        jb      .uppered
        sub     al, 32
.uppered:
        cmp     byte [g_inlen], 8
        jae     .redraw
        cmp     bl, 1
        jne     .st_p2
        mov     di, g_p1name
        jmp     .st_do
.st_p2:
        mov     di, g_p2name
.st_do:
        push    bx
        xor     bh, bh
        mov     bl, [g_inlen]
        add     di, bx
        mov     [di], al
        pop     bx
        inc     byte [g_inlen]
        push    bx
        mov     si, sfx_click
        call    PlaySfx
        pop     bx
        jmp     .redraw

.bs:
        cmp     byte [g_inlen], 0
        je      .redraw
        dec     byte [g_inlen]
        cmp     bl, 1
        jne     .bs_p2
        mov     di, g_p1name
        jmp     .bs_do
.bs_p2:
        mov     di, g_p2name
.bs_do:
        push    bx
        xor     bh, bh
        mov     bl, [g_inlen]
        add     di, bx
        mov     byte [di], 0
        pop     bx
        jmp     .redraw

.back:
        mov     byte [g_state], ST_DIFFICULTY
        pop     di
        pop     cx
        pop     bx
        pop     ax
        ret
.commit:
        cmp     byte [g_inlen], 0
        je      .redraw
        cmp     bl, 1
        jne     .c_p2
        mov     byte [g_state], ST_P1PASS
        jmp     .c_done
.c_p2:
        mov     byte [g_state], ST_P2PASS
.c_done:
        push    bx
        mov     si, sfx_namedone
        call    PlaySfx
        pop     bx
        pop     di
        pop     cx
        pop     bx
        pop     ax
        ret

; ============================================================================
; STATE: AUTH ENTRY  (replaces separate Name + Pass entry)
; AL = player number (1 or 2)
; Phase 1: enter username  (stored directly into g_p1name / g_p2name)
; Phase 2: LOGIN or REGISTER choice
;   REGISTER: username must not exist -> enter password -> save to DB
;   LOGIN:    username must exist -> enter password -> verify exact match
; Errors:
;   USERNAME ALREADY EXISTS  (register, duplicate)
;   ACCOUNT NOT FOUND        (login, no such user)
;   INCORRECT PASSWORD       (login, wrong pass)
; On success -> ST_P1BANNER or ST_P2BANNER
; ESC at any phase -> backs up one phase
; ============================================================================
DoPassEntry:
        push    ax
        push    bx
        push    cx
        push    di
        push    si
        mov     bl, al          ; BL = player number (1 or 2)

        ; ---- PHASE 1: USERNAME ENTRY ----
        ; Clear name buffer for this player
        cmp     bl, 1
        jne     .un_clr_p2
        mov     di, g_p1name
        jmp     .un_clr_do
.un_clr_p2:
        mov     di, g_p2name
.un_clr_do:
        mov     cx, 16
        xor     al, al
        push    es
        push    ds
        pop     es
        rep     stosb
        pop     es
        mov     byte [g_inlen], 0
        mov     byte [tr_firstdraw], 1
        mov     byte [auth_errmsg], 0

.un_redraw:
        mov     byte [gfx_color], C_BLACK
        call    ClearBack
        call    DrawScene

        ; Header: "PLAYER 1" or "PLAYER 2"
        mov     byte [gfx_scale], 2
        cmp     bl, 1
        jne     .un_hdr_p2
        mov     byte [gfx_color], C_GREEN
        mov     word [gfx_strptr], str_p1lbl
        jmp     .un_hdr_set
.un_hdr_p2:
        mov     byte [gfx_color], C_PURPLE
        mov     word [gfx_strptr], str_p2lbl
.un_hdr_set:
        mov     word [gfx_y], 12
        call    DrawStringCenter

        ; "ENTER USERNAME" label
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_TITLE_O
        mov     word [gfx_strptr], str_enter_name
        mov     word [gfx_y], 38
        call    DrawStringCenter

        ; Input box
        mov     word [gfx_x], 50
        mov     word [gfx_y], 52
        mov     word [gfx_w], 220
        mov     word [gfx_h], 22
        mov     byte [gfx_color], C_PANEL
        call    FillRect
        mov     byte [gfx_color], C_PANEL_BD
        call    FrameRect

        ; Show typed name
        mov     byte [gfx_scale], 2
        mov     byte [gfx_color], C_BLACK
        cmp     bl, 1
        jne     .un_txt_p2
        mov     word [gfx_strptr], g_p1name
        jmp     .un_txt_set
.un_txt_p2:
        mov     word [gfx_strptr], g_p2name
.un_txt_set:
        mov     word [gfx_y], 58
        call    DrawStringCenter

        ; Error message if any
        cmp     byte [auth_errmsg], 1
        jne     .un_chk2
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_RED
        mov     word [gfx_strptr], str_acct_not_found
        mov     word [gfx_y], 95
        call    DrawStringCenter
        jmp     .un_noerr
.un_chk2:
        cmp     byte [auth_errmsg], 3
        jne     .un_noerr
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_RED
        mov     word [gfx_strptr], str_usr_exists
        mov     word [gfx_y], 95
        call    DrawStringCenter
.un_noerr:
        call    DrawFooter
        call    Flip
        cmp     byte [tr_firstdraw], 1
        jne     .un_no_fi
        mov     byte [tr_firstdraw], 0
        call    TransFadeIn
.un_no_fi:
        call    WaitKey
        cmp     al, 27
        je      .un_back
        cmp     al, 13
        je      .un_commit
        cmp     al, 8
        je      .un_bs
        cmp     al, ' '
        jb      .un_redraw
        cmp     al, 'z'
        ja      .un_redraw
        cmp     byte [g_inlen], 8
        jae     .un_redraw
        ; uppercase
        cmp     al, 'a'
        jb      .un_up_done
        sub     al, 32
.un_up_done:
        cmp     bl, 1
        jne     .un_st_p2
        mov     di, g_p1name
        jmp     .un_st_do
.un_st_p2:
        mov     di, g_p2name
.un_st_do:
        push    bx
        xor     bh, bh
        mov     bl, [g_inlen]
        add     di, bx
        mov     [di], al
        pop     bx
        inc     byte [g_inlen]
        push    bx
        mov     si, sfx_click
        call    PlaySfx
        pop     bx
        jmp     .un_redraw
.un_bs:
        cmp     byte [g_inlen], 0
        je      .un_redraw
        dec     byte [g_inlen]
        cmp     bl, 1
        jne     .un_bs_p2
        mov     di, g_p1name
        jmp     .un_bs_do
.un_bs_p2:
        mov     di, g_p2name
.un_bs_do:
        push    bx
        xor     bh, bh
        mov     bl, [g_inlen]
        add     di, bx
        mov     byte [di], 0
        pop     bx
        jmp     .un_redraw
.un_back:
        ; ESC on username -> back to difficulty
        call    TransFadeOut
        mov     byte [g_state], ST_DIFFICULTY
        pop     si
        pop     di
        pop     cx
        pop     bx
        pop     ax
        ret
.un_commit:
        cmp     byte [g_inlen], 0
        je      .un_redraw
        ; fall through to phase 2

        ; ---- PHASE 2: LOGIN / REGISTER CHOICE ----
        ; BH = 0 -> LOGIN, BH = 1 -> REGISTER
        xor     bh, bh
        mov     byte [tr_firstdraw], 1
        mov     byte [auth_errmsg], 0

.ch_redraw:
        mov     byte [gfx_color], C_BLACK
        call    ClearBack
        call    DrawScene

        ; Player label
        mov     byte [gfx_scale], 2
        cmp     bl, 1
        jne     .ch_hdr_p2
        mov     byte [gfx_color], C_GREEN
        mov     word [gfx_strptr], str_p1lbl
        jmp     .ch_hdr_set
.ch_hdr_p2:
        mov     byte [gfx_color], C_PURPLE
        mov     word [gfx_strptr], str_p2lbl
.ch_hdr_set:
        mov     word [gfx_y], 12
        call    DrawStringCenter

        ; Show username
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_GOLD
        cmp     bl, 1
        jne     .ch_nm_p2
        mov     word [gfx_strptr], g_p1name
        jmp     .ch_nm_set
.ch_nm_p2:
        mov     word [gfx_strptr], g_p2name
.ch_nm_set:
        mov     word [gfx_y], 34
        call    DrawStringCenter

        ; LOGIN button
        mov     word [gfx_x], 60
        mov     word [gfx_y], 52
        mov     word [gfx_w], 200
        mov     word [gfx_h], 22
        cmp     bh, 0
        je      .ch_b1sel
        mov     byte [gfx_color], C_GRAY
        jmp     .ch_b1set
.ch_b1sel:
        mov     byte [gfx_color], C_GREEN
.ch_b1set:
        mov     byte [gfx_color2], C_WHITE
        mov     word [gfx_strptr], str_login
        call    DrawButton

        ; REGISTER button
        mov     word [gfx_x], 60
        mov     word [gfx_y], 82
        mov     word [gfx_w], 200
        mov     word [gfx_h], 22
        cmp     bh, 1
        je      .ch_b2sel
        mov     byte [gfx_color], C_GRAY
        jmp     .ch_b2set
.ch_b2sel:
        mov     byte [gfx_color], C_ORANGE
.ch_b2set:
        mov     byte [gfx_color2], C_WHITE
        mov     word [gfx_strptr], str_register
        call    DrawButton

        ; Errors shown here too (after validation bounce back)
        cmp     byte [auth_errmsg], 1
        jne     .ch_chk3
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_RED
        mov     word [gfx_strptr], str_acct_not_found
        mov     word [gfx_y], 120
        call    DrawStringCenter
        jmp     .ch_noerr
.ch_chk3:
        cmp     byte [auth_errmsg], 3
        jne     .ch_noerr
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_RED
        mov     word [gfx_strptr], str_usr_exists
        mov     word [gfx_y], 120
        call    DrawStringCenter
.ch_noerr:
        call    DrawFooter
        call    Flip
        cmp     byte [tr_firstdraw], 1
        jne     .ch_no_fi
        mov     byte [tr_firstdraw], 0
        call    TransFadeIn
.ch_no_fi:
        call    WaitKey
        cmp     al, 27
        je      .ch_back
        cmp     ah, 48h
        je      .ch_up
        cmp     ah, 50h
        je      .ch_dn
        cmp     al, 13
        je      .ch_sel
        jmp     .ch_redraw
.ch_up:
        cmp     bh, 0
        je      .ch_redraw
        dec     bh
        push    bx
        mov     si, sfx_click
        call    PlaySfx
        pop     bx
        jmp     .ch_redraw
.ch_dn:
        cmp     bh, 1
        jae     .ch_redraw
        inc     bh
        push    bx
        mov     si, sfx_click
        call    PlaySfx
        pop     bx
        jmp     .ch_redraw
.ch_back:
        ; ESC -> back to username entry
        cmp     bl, 1
        jne     .ch_bk_clr_p2
        mov     di, g_p1name
        jmp     .ch_bk_clr_do
.ch_bk_clr_p2:
        mov     di, g_p2name
.ch_bk_clr_do:
        mov     cx, 16
        xor     al, al
        push    es
        push    ds
        pop     es
        rep     stosb
        pop     es
        mov     byte [g_inlen], 0
        mov     byte [tr_firstdraw], 1
        mov     byte [auth_errmsg], 0
        jmp     .un_redraw

.ch_sel:
        ; BH=0 LOGIN, BH=1 REGISTER
        cmp     bh, 1
        je      .reg_check

        ; ---- LOGIN: verify username exists ----
        cmp     bl, 1
        jne     .log_nm_p2
        mov     si, g_p1name
        jmp     .log_nm_set
.log_nm_p2:
        mov     si, g_p2name
.log_nm_set:
        mov     di, db_usernames
        xor     cx, cx
.log_find:
        cmp     cx, DB_MAX_USERS
        jae     .log_notfound
        cmp     byte [di], 0
        je      .log_notfound
        push    cx
        push    si
        push    di
        call    StrCmp16
        pop     di
        pop     si
        pop     cx
        je      .log_found
        add     di, 16
        inc     cx
        jmp     .log_find
.log_notfound:
        mov     byte [auth_errmsg], 1
        mov     byte [tr_firstdraw], 1
        jmp     .ch_redraw
.log_found:
        mov     [auth_slot], cx
        mov     byte [auth_mode], 0
        jmp     .pw_entry

.reg_check:
        ; ---- REGISTER: verify username is unique ----
        cmp     bl, 1
        jne     .reg_nm_p2
        mov     si, g_p1name
        jmp     .reg_nm_set
.reg_nm_p2:
        mov     si, g_p2name
.reg_nm_set:
        mov     di, db_usernames
        xor     cx, cx
.reg_dup_lp:
        cmp     cx, DB_MAX_USERS
        jae     .reg_no_dup
        cmp     byte [di], 0
        je      .reg_no_dup
        push    cx
        push    si
        push    di
        call    StrCmp16
        pop     di
        pop     si
        pop     cx
        je      .reg_dup
        add     di, 16
        inc     cx
        jmp     .reg_dup_lp
.reg_dup:
        mov     byte [auth_errmsg], 3
        mov     byte [tr_firstdraw], 1
        jmp     .ch_redraw
.reg_no_dup:
        ; find free slot
        mov     di, db_usernames
        xor     cx, cx
.reg_slot_lp:
        cmp     cx, DB_MAX_USERS
        jae     .reg_full
        cmp     byte [di], 0
        je      .reg_got_slot
        add     di, 16
        inc     cx
        jmp     .reg_slot_lp
.reg_full:
        mov     byte [auth_errmsg], 3
        mov     byte [tr_firstdraw], 1
        jmp     .ch_redraw
.reg_got_slot:
        mov     [auth_slot], cx
        mov     byte [auth_mode], 1

        ; ---- PHASE 3: PASSWORD ENTRY ----
.pw_entry:
        ; Clear password buffer
        cmp     bl, 1
        jne     .pw_clr_p2
        mov     di, g_p1pass
        jmp     .pw_clr_do
.pw_clr_p2:
        mov     di, g_p2pass
.pw_clr_do:
        mov     cx, 16
        xor     al, al
        push    es
        push    ds
        pop     es
        rep     stosb
        pop     es
        mov     byte [g_inlen], 0
        mov     byte [tr_firstdraw], 1
        mov     byte [auth_errmsg], 0

.pw_redraw:
        mov     byte [gfx_color], C_BLACK
        call    ClearBack
        call    DrawScene

        ; Player label
        mov     byte [gfx_scale], 2
        cmp     bl, 1
        jne     .pw_lbl_p2
        mov     byte [gfx_color], C_GREEN
        mov     word [gfx_strptr], str_p1lbl
        jmp     .pw_lbl_set
.pw_lbl_p2:
        mov     byte [gfx_color], C_PURPLE
        mov     word [gfx_strptr], str_p2lbl
.pw_lbl_set:
        mov     word [gfx_y], 12
        call    DrawStringCenter

        ; Username shown
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_GOLD
        cmp     bl, 1
        jne     .pw_nm_p2
        mov     word [gfx_strptr], g_p1name
        jmp     .pw_nm_set
.pw_nm_p2:
        mov     word [gfx_strptr], g_p2name
.pw_nm_set:
        mov     word [gfx_y], 34
        call    DrawStringCenter

        ; "SET PASSWORD" or "ENTER PASSWORD" label
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_TITLE_O
        mov     word [gfx_strptr], str_set_pass
        mov     word [gfx_y], 50
        call    DrawStringCenter

        ; Input box
        mov     word [gfx_x], 50
        mov     word [gfx_y], 62
        mov     word [gfx_w], 220
        mov     word [gfx_h], 22
        mov     byte [gfx_color], C_PANEL
        call    FillRect
        mov     byte [gfx_color], C_PANEL_BD
        call    FrameRect

        ; Build mask
        push    bx
        xor     bh, bh
        mov     bl, [g_inlen]
        mov     di, pw_mask_buf
        mov     cx, bx
        jcxz    .pw_mask_done
        mov     al, '*'
.pw_mask_lp:
        mov     [di], al
        inc     di
        loop    .pw_mask_lp
.pw_mask_done:
        mov     byte [di], 0
        pop     bx

        mov     byte [gfx_scale], 2
        mov     byte [gfx_color], C_BLACK
        mov     word [gfx_strptr], pw_mask_buf
        mov     word [gfx_y], 66
        call    DrawStringCenter

        ; INCORRECT PASSWORD error
        cmp     byte [auth_errmsg], 2
        jne     .pw_noerr
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_RED
        mov     word [gfx_strptr], str_wrong_pass
        mov     word [gfx_y], 100
        call    DrawStringCenter
.pw_noerr:
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_DKGRAY
        mov     word [gfx_strptr], str_pass_hint
        mov     word [gfx_y], 116
        call    DrawStringCenter

        call    DrawFooter
        call    Flip
        cmp     byte [tr_firstdraw], 1
        jne     .pw_no_fi
        mov     byte [tr_firstdraw], 0
        call    TransFadeIn
.pw_no_fi:
        call    WaitKey
        cmp     al, 27
        je      .pw_back
        cmp     al, 13
        je      .pw_commit
        cmp     al, 8
        je      .pw_bs
        cmp     al, ' '
        jb      .pw_redraw
        cmp     al, '~'
        ja      .pw_redraw
        cmp     byte [g_inlen], 8
        jae     .pw_redraw
        cmp     bl, 1
        jne     .pw_st_p2
        mov     di, g_p1pass
        jmp     .pw_st_do
.pw_st_p2:
        mov     di, g_p2pass
.pw_st_do:
        push    bx
        xor     bh, bh
        mov     bl, [g_inlen]
        add     di, bx
        mov     [di], al
        pop     bx
        inc     byte [g_inlen]
        push    bx
        mov     si, sfx_click
        call    PlaySfx
        pop     bx
        jmp     .pw_redraw
.pw_bs:
        cmp     byte [g_inlen], 0
        je      .pw_redraw
        dec     byte [g_inlen]
        cmp     bl, 1
        jne     .pw_bs_p2
        mov     di, g_p1pass
        jmp     .pw_bs_do
.pw_bs_p2:
        mov     di, g_p2pass
.pw_bs_do:
        push    bx
        xor     bh, bh
        mov     bl, [g_inlen]
        add     di, bx
        mov     byte [di], 0
        pop     bx
        jmp     .pw_redraw
.pw_back:
        ; ESC from password -> back to choice screen
        mov     byte [g_inlen], 0
        ; clear pass buf
        cmp     bl, 1
        jne     .pw_bk_clr_p2
        mov     di, g_p1pass
        jmp     .pw_bk_clr_do
.pw_bk_clr_p2:
        mov     di, g_p2pass
.pw_bk_clr_do:
        push    bx
        mov     cx, 16
        xor     al, al
        push    es
        push    ds
        pop     es
        rep     stosb
        pop     es
        pop     bx
        xor     bh, bh
        mov     byte [tr_firstdraw], 1
        mov     byte [auth_errmsg], 0
        jmp     .ch_redraw

.pw_commit:
        cmp     byte [g_inlen], 0
        je      .pw_redraw

        cmp     byte [auth_mode], 1
        je      .pwc_register

        ; ---- LOGIN: compare entered password against stored ----
        ; SI = entered password buffer
        cmp     bl, 1
        jne     .pwc_si_p2
        mov     si, g_p1pass
        jmp     .pwc_si_set
.pwc_si_p2:
        mov     si, g_p2pass
.pwc_si_set:
        ; DI = db_passwords + auth_slot*16
        push    ax
        mov     ax, [auth_slot]
        mov     cx, 16
        mul     cx
        mov     di, db_passwords
        add     di, ax
        pop     ax
        call    StrCmp16
        jne     .pwc_wrong

        jmp     .pwc_success

.pwc_wrong:
        mov     byte [auth_errmsg], 2
        cmp     bl, 1
        jne     .pwc_wclr_p2
        mov     di, g_p1pass
        jmp     .pwc_wclr_do
.pwc_wclr_p2:
        mov     di, g_p2pass
.pwc_wclr_do:
        push    bx
        mov     cx, 16
        xor     al, al
        push    es
        push    ds
        pop     es
        rep     stosb
        pop     es
        pop     bx
        mov     byte [g_inlen], 0
        mov     byte [tr_firstdraw], 1
        jmp     .pw_redraw

.pwc_register:
        ; ---- REGISTER: save to DB ----
        ; Save username
        push    ax
        mov     ax, [auth_slot]
        mov     cx, 16
        mul     cx              ; ax = slot*16, dx may be set but slot<16 so ax<256 fine

        push    ax              ; save offset for password copy below
        cmp     bl, 1
        jne     .pwc_reg_nm_p2
        mov     si, g_p1name
        jmp     .pwc_reg_nm_set
.pwc_reg_nm_p2:
        mov     si, g_p2name
.pwc_reg_nm_set:
        mov     di, db_usernames
        add     di, ax
        mov     cx, 16
        push    es
        push    ds
        pop     es
        rep     movsb
        pop     es

        ; Save password  -- use fresh SI from player pass buffer, NOT the drifted SI
        pop     ax              ; restore slot*16 offset
        cmp     bl, 1
        jne     .pwc_reg_pw_p2
        mov     si, g_p1pass
        jmp     .pwc_reg_pw_set
.pwc_reg_pw_p2:
        mov     si, g_p2pass
.pwc_reg_pw_set:
        mov     di, db_passwords
        add     di, ax
        mov     cx, 16
        push    es
        push    ds
        pop     es
        rep     movsb
        pop     es

        pop     ax
        call    SaveAccounts
        jmp     .pwc_success

.pwc_success:
        ; Show animated loading screen before entering the game
        push    bx
        call    DoLoading
        pop     bx

        cmp     bl, 1
        jne     .pwc_s_p2
        mov     byte [g_state], ST_P1BANNER
        jmp     .pwc_s_done
.pwc_s_p2:
        mov     byte [g_state], ST_P2BANNER
.pwc_s_done:
        push    bx
        mov     si, sfx_namedone
        call    PlaySfx
        pop     bx
        pop     si
        pop     di
        pop     cx
        pop     bx
        pop     ax
        ret

; ============================================================================
; StrCmp16: compare two null-terminated strings, up to 16 chars.
; SI -> string A,  DI -> string B
; Returns ZF=1 if equal.  Preserves all registers.
; ============================================================================
StrCmp16:
        push    ax
        push    bx
        push    cx
        push    si
        push    di
        mov     cx, 16
.sc_lp:
        mov     al, [si]
        mov     bl, [di]
        cmp     al, bl
        jne     .sc_ne
        cmp     al, 0
        je      .sc_eq
        inc     si
        inc     di
        loop    .sc_lp
.sc_eq:
        pop     di
        pop     si
        pop     cx
        pop     bx
        pop     ax
        xor     ax, ax          ; ZF=1
        ret
.sc_ne:
        pop     di
        pop     si
        pop     cx
        pop     bx
        pop     ax
        or      ax, 1           ; ZF=0
        ret

; ============================================================================
; LoadAccounts / SaveAccounts
; ============================================================================
LoadAccounts:
        push    ax
        push    bx
        push    cx
        push    dx
        mov     ax, 3D00h
        mov     dx, ACCOUNTS_FILE
        int     21h
        jc      .la_none
        mov     bx, ax
        mov     ah, 3Fh
        mov     cx, DB_MAX_USERS*32
        mov     dx, db_usernames
        int     21h
        mov     ah, 3Eh
        int     21h
.la_none:
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

SaveAccounts:
        push    ax
        push    bx
        push    cx
        push    dx
        mov     ah, 3Ch
        xor     cx, cx
        mov     dx, ACCOUNTS_FILE
        int     21h
        jc      .sa_done
        mov     bx, ax
        mov     ah, 40h
        mov     cx, DB_MAX_USERS*32
        mov     dx, db_usernames
        int     21h
        mov     ah, 3Eh
        int     21h
.sa_done:
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
; ============================================================================
; STATE: PLAYER BANNER
; ============================================================================
DoBanner:
        push    ax
        push    bx
        mov     bl, al

        ; === Background: farm scene themed by difficulty ===
        mov     byte [gfx_color], C_SKY
        call    ClearBack
        call    DrawSceneDiff

        ; ============================================================
        ; MAIN CARD PANEL (cream/parchment with wood border)
        ; Outer wood frame
        ; ============================================================
        mov     word [gfx_x], 28
        mov     word [gfx_y], 18
        mov     word [gfx_w], 264
        mov     word [gfx_h], 158
        mov     byte [gfx_color], C_TRUNK
        call    FillRect
        ; Inner cream fill
        mov     word [gfx_x], 32
        mov     word [gfx_y], 22
        mov     word [gfx_w], 256
        mov     word [gfx_h], 150
        mov     byte [gfx_color], C_DIRT
        call    FillRect
        ; Dashed inner border (top line)
        mov     word [gfx_x], 36
        mov     word [gfx_y], 26
        mov     word [gfx_w], 248
        mov     word [gfx_h], 1
        mov     byte [gfx_color], C_DIRT_DK
        call    FillRect
        ; Dashed inner border (bottom line)
        mov     word [gfx_x], 36
        mov     word [gfx_y], 168
        mov     word [gfx_w], 248
        mov     word [gfx_h], 1
        mov     byte [gfx_color], C_DIRT_DK
        call    FillRect
        ; Dashed inner border (left line)
        mov     word [gfx_x], 36
        mov     word [gfx_y], 26
        mov     word [gfx_w], 1
        mov     word [gfx_h], 143
        mov     byte [gfx_color], C_DIRT_DK
        call    FillRect
        ; Dashed inner border (right line)
        mov     word [gfx_x], 283
        mov     word [gfx_y], 26
        mov     word [gfx_w], 1
        mov     word [gfx_h], 143
        mov     byte [gfx_color], C_DIRT_DK
        call    FillRect

        ; ============================================================
        ; WOODEN "PLAYER" SIGN - GREEN fill so YELLOW text pops
        ; ============================================================
        ; Sign outer border (dark brown)
        mov     word [gfx_x], 70
        mov     word [gfx_y], 13
        mov     word [gfx_w], 180
        mov     word [gfx_h], 22
        mov     byte [gfx_color], C_TRUNK
        call    FillRect
        ; Sign inner fill: DARK GREEN for contrast
        mov     word [gfx_x], 72
        mov     word [gfx_y], 14
        mov     word [gfx_w], 176
        mov     word [gfx_h], 20
        mov     byte [gfx_color], C_GRASS_DK
        call    FillRect
        ; Top highlight stripe (lighter green)
        mov     word [gfx_x], 72
        mov     word [gfx_y], 14
        mov     word [gfx_w], 176
        mov     word [gfx_h], 3
        mov     byte [gfx_color], C_GRASS
        call    FillRect
        ; Bottom shadow stripe
        mov     word [gfx_x], 72
        mov     word [gfx_y], 32
        mov     word [gfx_w], 176
        mov     word [gfx_h], 2
        mov     byte [gfx_color], C_TRUNK
        call    FillRect

        ; "PLAYER" YELLOW + dark shadow for bold contrast on green
        mov     byte [gfx_scale], 2
        ; Shadow pass (dark, offset +1)
        mov     byte [gfx_color], C_TRUNK
        mov     word [gfx_strptr], str_player_word
        mov     word [gfx_y], 20
        call    DrawStringCenter
        ; Main YELLOW pass
        mov     byte [gfx_color], C_TITLE_Y
        mov     word [gfx_y], 19
        call    DrawStringCenter
        ; Second pass = thicker/bolder
        call    DrawStringCenter

        ; ============================================================
        ; BIG PLAYER NUMBER - bold (draw twice), P1=green P2=purple
        ; ============================================================
        mov     byte [gfx_scale], 4
        cmp     bl, 1
        jne     .num_color_p2
        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_x], 152
        mov     word [gfx_y], 72
        mov     al, '1'
        call    DrawCh
        mov     byte [gfx_color], C_GRASS_DK
        mov     word [gfx_x], 150
        mov     word [gfx_y], 70
        mov     al, '1'
        call    DrawCh
        call    DrawCh
        jmp     .num_done
.num_color_p2:
        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_x], 152
        mov     word [gfx_y], 72
        mov     al, '2'
        call    DrawCh
        mov     byte [gfx_color], C_PURPLE
        mov     word [gfx_x], 150
        mov     word [gfx_y], 70
        mov     al, '2'
        call    DrawCh
        call    DrawCh
.num_done:

        ; ============================================================
        ; NAME BADGE - full-width dark green pill, YELLOW name text
        ; x=50 w=220 to fit any name at scale 2 (max 12*14=168px)
        ; ============================================================
        mov     word [gfx_x], 50
        mov     word [gfx_y], 138
        mov     word [gfx_w], 220
        mov     word [gfx_h], 18
        mov     byte [gfx_color], C_TRUNK
        call    FillRect
        ; Dark green inner fill
        mov     word [gfx_x], 52
        mov     word [gfx_y], 139
        mov     word [gfx_w], 216
        mov     word [gfx_h], 15
        mov     byte [gfx_color], C_GRASS_DK
        call    FillRect
        ; Lighter green top highlight
        mov     word [gfx_x], 52
        mov     word [gfx_y], 139
        mov     word [gfx_w], 216
        mov     word [gfx_h], 3
        mov     byte [gfx_color], C_GRASS
        call    FillRect
        ; Inner dashed lines top/bottom
        mov     word [gfx_x], 56
        mov     word [gfx_y], 142
        mov     word [gfx_w], 208
        mov     word [gfx_h], 1
        mov     byte [gfx_color], C_GRASS
        call    FillRect
        mov     word [gfx_x], 56
        mov     word [gfx_y], 153
        mov     word [gfx_w], 208
        mov     word [gfx_h], 1
        mov     byte [gfx_color], C_GRASS
        call    FillRect

        ; Player name: YELLOW scale 2 + shadow for bold pop on green
        mov     byte [gfx_scale], 2
        mov     byte [gfx_color], C_TRUNK
        cmp     bl, 1
        jne     .nm_p2
        mov     word [gfx_strptr], g_p1name
        jmp     .nm_set
.nm_p2:
        mov     word [gfx_strptr], g_p2name
.nm_set:
        ; Dark shadow pass
        mov     word [gfx_y], 146
        call    DrawStringCenter
        ; Yellow main pass
        mov     byte [gfx_color], C_TITLE_Y
        mov     word [gfx_y], 145
        call    DrawStringCenter
        call    DrawStringCenter

        call    Flip
        call    TransFadeIn

        push    bx
        mov     si, sfx_start
        call    PlaySfx
        pop     bx

        mov     ax, 1200
        call    Delay

        cmp     bl, 1
        jne     .p2_done
        mov     byte [g_curplayer], 1
        mov     byte [g_state], ST_GAME
        jmp     .done
.p2_done:
        mov     byte [g_curplayer], 2
        mov     byte [g_state], ST_GAME
.done:
        pop     bx
        pop     ax
        ret

; ============================================================================
; STATE: GAME (counting round)
; ============================================================================
DoGame:
        push    ax
        push    bx
        push    cx
        push    di

        ; In 2P mode, both players answer the SAME prompt for fairness.
        ; Pick new prompt only when starting a new round (curplayer=1 and
        ; neither has answered this round). For curplayer=2 in same round,
        ; reuse the existing g_animals/g_animtype.
        cmp     byte [g_mode], MODE_2P
        jne     .pick_new
        cmp     byte [g_curplayer], 1
        jne     .reuse              ; P2 reuses P1's prompt
        cmp     byte [g_p1answered], 0
        jne     .reuse              ; already had a prompt this round
        ; otherwise pick new
.pick_new:
        ; Pick random count based on difficulty
        mov     al, [g_diff]
        cmp     al, DIFF_EASY
        jne     .chk_med
        mov     bx, 5
        jmp     .pick
.chk_med:
        cmp     al, DIFF_MEDIUM
        jne     .hard
        mov     bx, 8
        jmp     .pick
.hard:
        mov     bx, 10
.pick:
        push    bx
        call    RandomRange
        pop     bx
        inc     ax
        mov     [g_animals], al

        mov     bx, 3
        call    RandomRange
        mov     [g_animtype], al

        ; Play a short "new round" chime
        push    si
        mov     si, sfx_roundstart
        call    PlaySfx
        pop     si
.reuse:

        ; Clear input buffer
        mov     byte [g_inlen], 0
        mov     di, g_inbuf
        mov     cx, 5
        xor     al, al
        push    es
        push    ds
        pop     es
        rep     stosb
        pop     es

        ; Record start time for this player's turn
        call    ReadTicks
        cmp     byte [g_curplayer], 1
        jne     .t_p2
        mov     [g_starttime], ax
        jmp     .t_done
.t_p2:
        mov     [g_starttime], ax
.t_done:

.redraw:
        mov     byte [gfx_color], C_BLACK
        call    ClearBack
        call    DrawScene

        ; "HOW MANY ANIMALS?"
        mov     byte [gfx_scale], 2
        mov     byte [gfx_color], C_TITLE_O
        mov     word [gfx_strptr], str_how_many
        mov     word [gfx_y], 6
        call    DrawStringCenter

        ; --- Turn indicator banner (above animals) ---
        cmp     byte [g_mode], MODE_2P
        je      .show_turn
        ; 1P mode: just show round
        mov     word [gfx_x], 110
        mov     word [gfx_y], 24
        mov     word [gfx_w], 100
        mov     word [gfx_h], 12
        mov     byte [gfx_color], C_PANEL
        call    FillRect
        mov     byte [gfx_color], C_PANEL_BD
        call    FrameRect
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_BLACK
        mov     word [gfx_strptr], str_round
        mov     word [gfx_y], 26
        call    DrawStringCenter
        ; round number on the right of label - draw below
        jmp     .turn_done
.show_turn:
        ; turn box - colored by current player
        mov     word [gfx_x], 60
        mov     word [gfx_y], 24
        mov     word [gfx_w], 200
        mov     word [gfx_h], 14
        cmp     byte [g_curplayer], 1
        jne     .turn_p2
        mov     byte [gfx_color], C_GREEN
        jmp     .turn_fill
.turn_p2:
        mov     byte [gfx_color], C_PURPLE
.turn_fill:
        call    FillRect
        mov     byte [gfx_color], C_GOLD
        call    FrameRect

        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_WHITE
        cmp     byte [g_curplayer], 1
        jne     .turn_n_p2
        mov     word [gfx_strptr], str_p1turn
        jmp     .turn_n_set
.turn_n_p2:
        mov     word [gfx_strptr], str_p2turn
.turn_n_set:
        mov     word [gfx_y], 28
        call    DrawStringCenter
.turn_done:

        ; Draw the animals (centered area y=44..90)
        call    DrawAnimalRow

        ; Answer panel
        mov     word [gfx_x], 110
        mov     word [gfx_y], 105
        mov     word [gfx_w], 100
        mov     word [gfx_h], 32
        mov     byte [gfx_color], C_PANEL
        call    FillRect
        mov     byte [gfx_color], C_PANEL_BD
        call    FrameRect

        ; "ANSWER:" small label
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_DKGRAY
        mov     word [gfx_strptr], str_answer_lbl
        mov     word [gfx_x], 116
        mov     word [gfx_y], 108
        call    DrawString

        ; Current input string (centered in panel)
        mov     byte [gfx_scale], 3
        mov     byte [gfx_color], C_BLACK
        mov     word [gfx_strptr], g_inbuf
        mov     word [gfx_y], 116
        call    DrawStringCenter

        call    DrawScorePanels

        ; Footer bar - plain text, no boxes
        mov     word [gfx_x], 0
        mov     word [gfx_y], 147
        mov     word [gfx_w], 320
        mov     word [gfx_h], 17
        mov     byte [gfx_color], C_GRASS
        call    FillRect
        mov     word [gfx_x], 2
        mov     word [gfx_y], 149
        mov     word [gfx_w], 316
        mov     word [gfx_h], 13
        mov     byte [gfx_color], C_GRASS_DK
        call    FillRect
        ; Vertical separator
        mov     word [gfx_x], 159
        mov     word [gfx_y], 151
        mov     word [gfx_w], 2
        mov     word [gfx_h], 9
        mov     byte [gfx_color], C_GRASS
        call    FillRect
        ; All text scale 1, y=155
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_GOLD
        mov     word [gfx_x], 53
        mov     word [gfx_y], 155
        mov     word [gfx_strptr], str_key_enter
        call    DrawString
        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_x], 92
        mov     word [gfx_y], 155
        mov     word [gfx_strptr], str_lbl_ok
        call    DrawString
        mov     byte [gfx_color], C_GOLD
        mov     word [gfx_x], 213
        mov     word [gfx_y], 155
        mov     word [gfx_strptr], str_key_esc
        call    DrawString
        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_x], 238
        mov     word [gfx_y], 155
        mov     word [gfx_strptr], str_lbl_back
        call    DrawString

        call    Flip

        call    WaitKey
        cmp     al, 27
        je      .quit
        cmp     al, 13
        je      .check
        cmp     al, 8
        je      .bs
        cmp     al, '0'
        jb      .redraw
        cmp     al, '9'
        ja      .redraw
        cmp     byte [g_inlen], 3
        jae     .redraw
        push    bx
        xor     bh, bh
        mov     bl, [g_inlen]
        mov     di, g_inbuf
        add     di, bx
        mov     [di], al
        pop     bx
        inc     byte [g_inlen]
        mov     si, sfx_tick
        call    PlaySfx
        jmp     .redraw

.bs:
        cmp     byte [g_inlen], 0
        je      .redraw
        dec     byte [g_inlen]
        push    bx
        xor     bh, bh
        mov     bl, [g_inlen]
        mov     di, g_inbuf
        add     di, bx
        mov     byte [di], 0
        pop     bx
        jmp     .redraw

.check:
        cmp     byte [g_inlen], 0
        je      .redraw
        ; Capture elapsed time
        call    ReadTicks
        sub     ax, [g_starttime]
        ; store for current player
        cmp     byte [g_curplayer], 1
        jne     .et_p2
        mov     [g_p1time], ax
        jmp     .et_done
.et_p2:
        mov     [g_p2time], ax
.et_done:

        ; Increment round total
        cmp     byte [g_curplayer], 1
        jne     .tot_p2
        inc     byte [g_p1total]
        jmp     .tot_done
.tot_p2:
        inc     byte [g_p2total]
.tot_done:

        call    ParseInput
        xor     bh, bh
        mov     bl, [g_animals]
        cmp     ax, bx
        jne     .wrong

        ; --- CORRECT ---
        ; Mark player as correct this round
        cmp     byte [g_curplayer], 1
        jne     .ok_p2
        mov     byte [g_p1answered], 1
        inc     byte [g_p1correct]
        jmp     .ok_done
.ok_p2:
        mov     byte [g_p2answered], 1
        inc     byte [g_p2correct]
.ok_done:
        mov     byte [g_state], ST_CORRECT
        jmp     .done

.wrong:
        ; mark answered (got it wrong = 0 tokens)
        cmp     byte [g_curplayer], 1
        jne     .wr_p2
        mov     byte [g_p1answered], 2  ; 2 = answered wrong
        jmp     .wr_done
.wr_p2:
        mov     byte [g_p2answered], 2
.wr_done:
        ; In 1P mode add a strike
        cmp     byte [g_mode], MODE_2P
        je      .wr_state
        inc     byte [g_strikes]
        cmp     byte [g_strikes], MAX_STRIKES
        jb      .wr_state
        ; Out of strikes
        mov     byte [g_state], ST_GAMEOVER
        jmp     .done
.wr_state:
        mov     byte [g_state], ST_WRONG
        jmp     .done

.quit:
        mov     byte [g_state], ST_GAMEOVER
.done:
        pop     di
        pop     cx
        pop     bx
        pop     ax
        ret

; ----------------------------------------------------------------------------
; DrawAnimalRow: draws g_animals copies of g_animtype centered.
; Adjusted: row1 y=46, row2 y=76 (room for turn banner above)
; ----------------------------------------------------------------------------
DrawAnimalRow:
        push    ax
        push    bx
        push    cx
        push    dx
        push    si

        xor     ch, ch
        mov     cl, [g_animals]
        cmp     cl, 0
        je      .done

        mov     ax, cx
        cmp     ax, 8
        jbe     .one_row
        mov     ax, 8
.one_row:
        mov     [row_cnt1], ax
        mov     ax, cx
        sub     ax, [row_cnt1]
        mov     [row_cnt2], ax

        mov     bx, [row_cnt1]
        cmp     bx, 0
        je      .row2
        mov     ax, bx
        mov     dx, 26
        mul     dx                  ; ax = count*26 (DX clobbered to 0 for small values)
        mov     dx, 320
        sub     dx, ax              ; dx = 320 - count*26
        shr     dx, 1               ; dx = left-margin for centering
        mov     [tmp_x2], dx        ; save centering offset
        xor     si, si
.r1_lp:
        cmp     si, bx
        jae     .row2
        push    bx
        mov     ax, si
        mov     bx, 26
        mul     bx                  ; ax = i*26 (DX clobbered)
        pop     bx
        add     ax, [tmp_x2]        ; add saved centering offset
        mov     [gfx_x], ax
        mov     word [gfx_y], 46
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        mov     al, [g_animtype]
        call    DrawAnimal
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        inc     si
        jmp     .r1_lp

.row2:
        mov     bx, [row_cnt2]
        cmp     bx, 0
        je      .done
        mov     ax, bx
        mov     dx, 26
        mul     dx
        mov     dx, 320
        sub     dx, ax
        shr     dx, 1
        mov     [tmp_x2], dx        ; save centering offset
        xor     si, si
.r2_lp:
        cmp     si, bx
        jae     .done
        push    bx
        mov     ax, si
        mov     bx, 26
        mul     bx
        pop     bx
        add     ax, [tmp_x2]        ; add saved centering offset
        mov     [gfx_x], ax
        mov     word [gfx_y], 76
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        mov     al, [g_animtype]
        call    DrawAnimal
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        inc     si
        jmp     .r2_lp

.done:
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

; ============================================================================
; STATE: CORRECT
; ============================================================================
DoCorrect:
        push    ax
        push    bx
        push    cx
        push    si
        push    di

        mov     byte [gfx_color], C_BLACK
        call    ClearBack
        call    DrawScene

        mov     byte [gfx_scale], 4
        mov     byte [gfx_color], C_TITLE_G
        mov     word [gfx_strptr], str_correct
        mov     word [gfx_y], 50
        call    DrawStringCenter

        mov     byte [gfx_scale], 2
        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_strptr], str_answer_was
        mov     word [gfx_y], 95
        call    DrawStringCenter

        mov     byte [gfx_scale], 3
        mov     byte [gfx_color], C_TITLE_Y
        mov     word [gfx_x], 150
        mov     word [gfx_y], 115
        xor     ah, ah
        mov     al, [g_animals]
        call    DrawNumber

        call    DrawScorePanels
        call    Flip

        ; White flash: 2 frames of pure white overlay
        mov     al, C_WHITE
        mov     cx, 2
        call    TransFlash

        mov     si, sfx_correct
        call    PlaySfx

        mov     ax, 800
        call    Delay

        ; Decide next state per mode
        cmp     byte [g_mode], MODE_2P
        je      .duel_flow

        ; --- Single player ---
        ; Award 2 half-tokens (1 full token)
        add     byte [g_p1score], 2
        ; Check win
        cmp     byte [g_p1score], WIN_TOKENS
        jb      .single_next
        mov     si, g_p1name
        mov     di, g_lastwin
        call    CopyName
        mov     byte [g_state], ST_VICTORY
        jmp     .done
.single_next:
        mov     byte [g_state], ST_GAME
        jmp     .done

.duel_flow:
        ; In duel: just record the correct state. Don't award tokens yet -
        ; tokens are awarded at ROUNDEND based on speed.
        cmp     byte [g_curplayer], 1
        jne     .d_p1_done
        ; P1 just answered. Now hand to P2 (or trigger name entry)
        cmp     byte [g_p2name], 0
        jne     .swp_to_2
        mov     byte [g_state], ST_P2PASS
        jmp     .done
.swp_to_2:
        mov     byte [g_curplayer], 2
        mov     byte [g_state], ST_GAME
        jmp     .done
.d_p1_done:
        ; P2 just answered -> round ends
        mov     byte [g_state], ST_ROUNDEND
        jmp     .done

.done:
        pop     di
        pop     si
        pop     cx
        pop     bx
        pop     ax
        ret

; ============================================================================
; STATE: WRONG
; ============================================================================
DoWrong:
        push    ax
        push    si
        push    di

        mov     byte [gfx_color], C_BLACK
        call    ClearBack
        call    DrawScene

        mov     byte [gfx_scale], 4
        mov     byte [gfx_color], C_RED
        mov     word [gfx_strptr], str_wrong
        mov     word [gfx_y], 50
        call    DrawStringCenter

        mov     byte [gfx_scale], 2
        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_strptr], str_answer_was
        mov     word [gfx_y], 95
        call    DrawStringCenter

        mov     byte [gfx_scale], 3
        mov     byte [gfx_color], C_TITLE_Y
        mov     word [gfx_x], 150
        mov     word [gfx_y], 115
        xor     ah, ah
        mov     al, [g_animals]
        call    DrawNumber

        call    DrawScorePanels
        call    Flip

        ; Red flash: 2 frames of pure red overlay
        mov     al, C_RED
        mov     cx, 2
        call    TransFlash

        mov     si, sfx_wrong
        call    PlaySfx

        mov     ax, 800
        call    Delay

        cmp     byte [g_mode], MODE_2P
        je      .duel_flow

        ; Single player: just continue (strikes already incremented)
        mov     byte [g_state], ST_GAME
        jmp     .done

.duel_flow:
        cmp     byte [g_curplayer], 1
        jne     .p1_done
        cmp     byte [g_p2name], 0
        jne     .swp_to_2
        mov     byte [g_state], ST_P2PASS
        jmp     .done
.swp_to_2:
        mov     byte [g_curplayer], 2
        mov     byte [g_state], ST_GAME
        jmp     .done
.p1_done:
        mov     byte [g_state], ST_ROUNDEND

.done:
        pop     di
        pop     si
        pop     ax
        ret

; ============================================================================
; STATE: ROUND END (2P only) - awards tokens & checks for victory/tiebreak
; ============================================================================
; Token rules:
;   Both correct:   faster +2 (full), slower +1 (half)
;   One correct:    that player +2, other +0
;   Both wrong:     no tokens
DoRoundEnd:
        push    ax
        push    bx
        push    cx
        push    si
        push    di

        ; --- Determine token awards ---
        ; Fair scoring: both correct = both +2 (1 full token each).
        ; This avoids penalizing P2 for answering second (P1 always sees the
        ; prompt first, so timing is structurally unfair).
        mov     al, [g_p1answered]      ; 1=correct, 2=wrong, 0=untouched
        mov     bl, [g_p2answered]
        cmp     al, 1
        jne     .p1wr
        ; P1 correct - award +2
        add     byte [g_p1score], 2
.p1wr:
        cmp     bl, 1
        jne     .show
        ; P2 correct - award +2
        add     byte [g_p2score], 2

.show:
        ; --- Render round summary screen ---
        mov     byte [gfx_color], C_BLACK
        call    ClearBack
        call    DrawScene

        mov     byte [gfx_scale], 3
        mov     byte [gfx_color], C_TITLE_Y
        mov     word [gfx_strptr], str_round_end
        mov     word [gfx_y], 14
        call    DrawStringCenter

        ; Round number
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_strptr], str_round
        mov     word [gfx_x], 130
        mov     word [gfx_y], 44
        call    DrawString
        mov     word [gfx_x], 175
        mov     word [gfx_y], 44
        mov     ax, [g_round]
        call    DrawNumber

        ; Show each player's result on this round
        ; P1 row at y=58
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_GREEN
        mov     word [gfx_strptr], g_p1name
        mov     word [gfx_x], 30
        mov     word [gfx_y], 60
        call    DrawString

        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_x], 110
        mov     word [gfx_y], 60
        cmp     byte [g_p1answered], 1
        jne     .p1_x
        mov     word [gfx_strptr], str_correct_short
        jmp     .p1_dr
.p1_x:
        mov     word [gfx_strptr], str_wrong_short
        mov     byte [gfx_color], C_RED
.p1_dr:
        call    DrawString

        ; P1 award
        mov     byte [gfx_color], C_GOLD
        mov     word [gfx_x], 180
        mov     word [gfx_y], 60
        mov     word [gfx_strptr], str_plus
        call    DrawString
        mov     word [gfx_x], 200
        mov     word [gfx_y], 60
        ; show this round's award (delta) - we computed but didn't save delta
        ; Compute by looking at flags: both correct->2/1, one->2/0
        mov     byte [gfx_color], C_WHITE
        call    ComputeP1Award
        call    DrawTokens

        ; P2 row at y=78
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_PURPLE
        mov     word [gfx_strptr], g_p2name
        mov     word [gfx_x], 30
        mov     word [gfx_y], 78
        call    DrawString

        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_x], 110
        mov     word [gfx_y], 78
        cmp     byte [g_p2answered], 1
        jne     .p2_x
        mov     word [gfx_strptr], str_correct_short
        jmp     .p2_dr
.p2_x:
        mov     word [gfx_strptr], str_wrong_short
        mov     byte [gfx_color], C_RED
.p2_dr:
        call    DrawString

        mov     byte [gfx_color], C_GOLD
        mov     word [gfx_x], 180
        mov     word [gfx_y], 78
        mov     word [gfx_strptr], str_plus
        call    DrawString
        mov     word [gfx_x], 200
        mov     word [gfx_y], 78
        mov     byte [gfx_color], C_WHITE
        call    ComputeP2Award
        call    DrawTokens

        call    DrawScorePanels

        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_DKGRAY
        mov     word [gfx_strptr], str_press_any
        mov     word [gfx_y], 158
        call    DrawStringCenter

        call    Flip
        call    FlushKeys

        ; Play round-end jingle
        mov     si, sfx_roundend
        call    PlaySfx

        call    WaitKey
        mov     byte [g_p1answered], 0
        mov     byte [g_p2answered], 0
        inc     word [g_round]
        mov     byte [g_curplayer], 1

        ; --- Check for victory/tiebreaker ---
        mov     al, [g_p1score]
        mov     bl, [g_p2score]
        cmp     al, WIN_TOKENS
        jb      .check_p2
        cmp     bl, WIN_TOKENS
        jb      .p1_wins
        ; Both >= WIN_TOKENS - need a clear leader
        cmp     al, bl
        ja      .p1_wins
        jb      .p2_wins
        ; Tied at >= WIN_TOKENS -> sudden death (continue playing)
        jmp     .continue
.check_p2:
        cmp     bl, WIN_TOKENS
        jb      .continue
.p2_wins:
        mov     si, g_p2name
        mov     di, g_lastwin
        call    CopyName
        mov     byte [g_state], ST_VICTORY
        jmp     .done
.p1_wins:
        mov     si, g_p1name
        mov     di, g_lastwin
        call    CopyName
        mov     byte [g_state], ST_VICTORY
        jmp     .done
.continue:
        mov     byte [g_state], ST_GAME
.done:
        pop     di
        pop     si
        pop     cx
        pop     bx
        pop     ax
        ret

; ComputeP1Award: returns AX = half-tokens awarded to P1 this round
ComputeP1Award:
        xor     ax, ax
        cmp     byte [g_p1answered], 1
        jne     .done
        mov     ax, 2
.done:
        ret

ComputeP2Award:
        xor     ax, ax
        cmp     byte [g_p2answered], 1
        jne     .done
        mov     ax, 2
.done:
        ret

; ============================================================================
; STATE: VICTORY
; ============================================================================
DoVictory:
        push    ax
        push    bx
        push    si

        mov     byte [gfx_color], C_BLACK
        call    ClearBack
        call    DrawScene

        mov     byte [gfx_scale], 4
        mov     byte [gfx_color], C_TITLE_Y
        mov     word [gfx_strptr], str_winner
        mov     word [gfx_y], 22
        call    DrawStringCenter

        mov     byte [gfx_scale], 3
        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_strptr], g_lastwin
        mov     word [gfx_y], 64
        call    DrawStringCenter

        ; Show stats: tokens earned, accuracy
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_GOLD
        mov     word [gfx_strptr], str_final_tok
        mov     word [gfx_x], 80
        mov     word [gfx_y], 105
        call    DrawString

        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_x], 165
        mov     word [gfx_y], 105
        ; Show winner's tokens (max of two for 2P, p1 for 1P)
        cmp     byte [g_mode], MODE_2P
        jne     .v_solo_tok
        mov     al, [g_p1score]
        cmp     al, [g_p2score]
        jae     .v_use_p1
        mov     al, [g_p2score]
        jmp     .v_tok_dr
.v_use_p1:
        ; AL already set to p1score
        jmp     .v_tok_dr
.v_solo_tok:
        mov     al, [g_p1score]
.v_tok_dr:
        xor     ah, ah
        call    DrawTokens

        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_DKGRAY
        mov     word [gfx_strptr], str_press_any
        mov     word [gfx_y], 130
        call    DrawStringCenter

        call    DrawScorePanels
        call    Flip
        call    TransFadeIn

        mov     si, sfx_victory
        call    PlaySfx

        ; Add to high scores - route to correct table based on mode
        ; 1P goes to single table; 2P goes to duel table
        push    si
        push    di
        cmp     byte [g_mode], MODE_2P
        je      .hs_duel
        ; --- Single Player victory ---
        mov     si, g_p1name
        xor     ah, ah
        mov     al, [g_p1score]
        call    AddSingleScore
        call    SaveSingleScores
        jmp     .hs_done
.hs_duel:
        ; --- Duel victory: save both players ---
        mov     si, g_p1name
        xor     ah, ah
        mov     al, [g_p1score]
        call    AddDuelScore
        mov     si, g_p2name
        xor     ah, ah
        mov     al, [g_p2score]
        call    AddDuelScore
        call    SaveDuelScores
.hs_done:
        pop     di
        pop     si

        call    FlushKeys
        call    WaitKey

        call    TransFadeOut
        mov     byte [g_state], ST_HISCORES
        pop     si
        pop     bx
        pop     ax
        ret

; ============================================================================
; STATE: GAME OVER
; ============================================================================
DoGameOver:
        push    ax
        push    si

        mov     byte [gfx_color], C_BLACK
        call    ClearBack
        call    DrawScene

        mov     byte [gfx_scale], 3
        mov     byte [gfx_color], C_RED
        mov     word [gfx_strptr], str_game_over
        mov     word [gfx_y], 36
        call    DrawStringCenter

        ; Show reason: "OUT OF LIVES" or just nothing for ESC
        cmp     byte [g_strikes], MAX_STRIKES
        jb      .skip_reason
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_strptr], str_out_of_lives
        mov     word [gfx_y], 70
        call    DrawStringCenter
.skip_reason:

        ; Show stats
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_GOLD
        mov     word [gfx_strptr], str_final_tok
        mov     word [gfx_x], 70
        mov     word [gfx_y], 92
        call    DrawString

        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_x], 155
        mov     word [gfx_y], 92
        xor     ah, ah
        mov     al, [g_p1score]
        call    DrawTokens

        ; correct/total
        mov     byte [gfx_color], C_GOLD
        mov     word [gfx_strptr], str_final_acc
        mov     word [gfx_x], 70
        mov     word [gfx_y], 104
        call    DrawString

        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_x], 155
        mov     word [gfx_y], 104
        xor     ah, ah
        mov     al, [g_p1correct]
        call    DrawNumber
        mov     al, '/'
        call    DrawCh
        mov     bx, 7
        add     [gfx_x], bx
        xor     ah, ah
        mov     al, [g_p1total]
        call    DrawNumber

        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_strptr], str_press_any
        mov     word [gfx_y], 130
        call    DrawStringCenter

        call    Flip
        call    TransFadeIn

        mov     si, sfx_lose
        call    PlaySfx

        ; Save score(s) on game over - route to correct table based on mode
        cmp     byte [g_mode], MODE_2P
        je      .go_save_2p
        ; 1P mode: save to single-player table if score > 0
        cmp     byte [g_p1score], 0
        je      .skip_save
        push    si
        mov     si, g_p1name
        xor     ah, ah
        mov     al, [g_p1score]
        call    AddSingleScore
        pop     si
        call    SaveSingleScores
        jmp     .skip_save
.go_save_2p:
        ; 2P mode: save both players to duel table
        push    si
        mov     si, g_p1name
        xor     ah, ah
        mov     al, [g_p1score]
        call    AddDuelScore
        mov     si, g_p2name
        xor     ah, ah
        mov     al, [g_p2score]
        call    AddDuelScore
        pop     si
        call    SaveDuelScores
.skip_save:

        call    FlushKeys
        call    WaitKey

        call    TransFadeOut
        mov     byte [g_state], ST_HISCORES
        pop     si
        pop     ax
        ret

; ============================================================================
; STATE: HIGH SCORES - polished layout
; ============================================================================
DoHiScores:
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di

        ; ---------------------------------------------------------------
        ; Sky-blue background (farm scene feel)
        ; ---------------------------------------------------------------
        mov     byte [gfx_color], C_SKY
        call    ClearBack

        ; ---------------------------------------------------------------
        ; Grass strip at the very bottom
        ; ---------------------------------------------------------------
        mov     word [gfx_x], 0
        mov     word [gfx_y], 190
        mov     word [gfx_w], 320
        mov     word [gfx_h], 10
        mov     byte [gfx_color], C_GRASS
        call    FillRect

        ; ---------------------------------------------------------------
        ; === WOODEN SIGN BANNER (title area) ===
        ; Outer dark-wood backing panel
        ; ---------------------------------------------------------------
        mov     word [gfx_x], 40
        mov     word [gfx_y], 4
        mov     word [gfx_w], 240
        mov     word [gfx_h], 26
        mov     byte [gfx_color], C_TRUNK
        call    FillRect
        ; inner lighter wood fill
        mov     word [gfx_x], 42
        mov     word [gfx_y], 5
        mov     word [gfx_w], 236
        mov     word [gfx_h], 24
        mov     byte [gfx_color], C_FENCE
        call    FillRect
        ; top highlight stripe on wood sign
        mov     word [gfx_x], 42
        mov     word [gfx_y], 5
        mov     word [gfx_w], 236
        mov     word [gfx_h], 2
        mov     byte [gfx_color], C_TITLE_O
        call    FillRect

        ; "HIGH SCORES" title in gold on the wooden sign
        mov     byte [gfx_scale], 2
        mov     byte [gfx_color], C_GOLD
        mov     word [gfx_strptr], str_high_scores
        mov     word [gfx_y], 10
        call    DrawStringCenter

        ; ---------------------------------------------------------------
        ; Mode subtitle badge (rounded pill style)
        ; Outer badge border
        ; ---------------------------------------------------------------
        mov     word [gfx_x], 90
        mov     word [gfx_y], 33
        mov     word [gfx_w], 140
        mov     word [gfx_h], 12
        mov     byte [gfx_color], C_TRUNK
        call    FillRect
        ; Badge fill
        mov     word [gfx_x], 91
        mov     word [gfx_y], 34
        mov     word [gfx_w], 138
        mov     word [gfx_h], 10
        mov     byte [gfx_color], C_DIRT
        call    FillRect

        ; Mode subtitle text centered inside badge
        mov     byte [gfx_scale], 1
        cmp     byte [g_mode], MODE_2P
        je      .hs_duel_hdr
        mov     byte [gfx_color], C_TRUNK
        mov     word [gfx_strptr], str_single
        mov     word [hi_score_tbl_ptr], g_single_scores
        jmp     .hs_hdr_draw
.hs_duel_hdr:
        mov     byte [gfx_color], C_TRUNK
        mov     word [gfx_strptr], str_duel
        mov     word [hi_score_tbl_ptr], g_duel_scores
.hs_hdr_draw:
        mov     word [gfx_y], 37
        call    DrawStringCenter

        ; ---------------------------------------------------------------
        ; === CREAM / PARCHMENT MAIN PANEL ===
        ; Outer border (dark wood tone)
        ; ---------------------------------------------------------------
        mov     word [gfx_x], 8
        mov     word [gfx_y], 48
        mov     word [gfx_w], 304
        mov     word [gfx_h], 130
        mov     byte [gfx_color], C_TRUNK
        call    FillRect
        ; Inner cream panel fill
        mov     word [gfx_x], 10
        mov     word [gfx_y], 49
        mov     word [gfx_w], 300
        mov     word [gfx_h], 128
        mov     byte [gfx_color], C_DIRT
        call    FillRect

        ; ---------------------------------------------------------------
        ; Green header bar for column labels (inside panel)
        ; ---------------------------------------------------------------
        mov     word [gfx_x], 10
        mov     word [gfx_y], 49
        mov     word [gfx_w], 300
        mov     word [gfx_h], 13
        mov     byte [gfx_color], C_GRASS_DK
        call    FillRect

        ; Column header labels in white (scale 1)
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_WHITE

        mov     word [gfx_strptr], str_hdr_rank
        mov     word [gfx_x], 20
        mov     word [gfx_y], 53
        call    DrawString

        mov     word [gfx_strptr], str_hdr_name
        mov     word [gfx_x], 90
        mov     word [gfx_y], 53
        call    DrawString

        mov     word [gfx_strptr], str_hdr_tok
        mov     word [gfx_x], 232
        mov     word [gfx_y], 53
        call    DrawString

        ; ---------------------------------------------------------------
        ; === SCORE ROWS (up to 10) ===
        ; Each row: 12px tall, separated by a 1px dashed-style divider
        ; Start y = 63 (just below header bar)
        ; ---------------------------------------------------------------
        mov     byte [g_has_entries], 0
        xor     bx, bx          ; row index 0..9
        mov     dx, 64          ; current y for row text
.lp:
        cmp     bx, 10
        jae     .done_list

        push    dx
        mov     ax, bx
        mov     cx, 18
        mul     cx
        pop     dx
        mov     si, [hi_score_tbl_ptr]
        add     si, ax
        cmp     byte [si], 0
        je      .skip

        mov     byte [g_has_entries], 1

        ; --- Dashed divider line above each row (except first) ---
        cmp     bx, 0
        je      .no_divider
        push    dx
        push    bx
        dec     dx              ; 1px above row
        ; draw dashes: step 4 px on, 4 px off across full panel width
        mov     bx, 10          ; start x
.dash_lp:
        cmp     bx, 310
        jae     .dash_done
        mov     word [gfx_x], bx
        mov     [gfx_y], dx
        mov     word [gfx_w], 3
        mov     word [gfx_h], 1
        mov     byte [gfx_color], C_DIRT_DK
        call    FillRect
        add     bx, 6
        jmp     .dash_lp
.dash_done:
        pop     bx
        pop     dx
.no_divider:

        ; --- Rank-1 gold highlight row background ---
        cmp     bx, 0
        jne     .not_rank1
        push    dx
        mov     word [gfx_x], 10
        mov     [gfx_y], dx
        mov     word [gfx_w], 300
        mov     word [gfx_h], 11
        mov     byte [gfx_color], C_TITLE_O
        call    FillRect
        pop     dx
.not_rank1:

        ; --- Rank number ---
        mov     byte [gfx_scale], 1
        cmp     bx, 0
        jne     .rk_normal
        mov     byte [gfx_color], C_TRUNK
        jmp     .rk_set
.rk_normal:
        mov     byte [gfx_color], C_DIRT_DK
.rk_set:
        mov     word [gfx_x], 20
        mov     [gfx_y], dx
        push    ax
        push    bx
        push    dx
        mov     ax, bx
        inc     ax
        call    DrawNumber
        pop     dx
        pop     bx
        pop     ax

        ; Period after rank number
        push    bx
        push    dx
        mov     [gfx_y], dx
        mov     al, '.'
        call    DrawCh
        pop     dx
        pop     bx

        ; --- Name ---
        cmp     bx, 0
        jne     .nm_normal
        mov     byte [gfx_color], C_TRUNK
        jmp     .nm_set
.nm_normal:
        mov     byte [gfx_color], C_DIRT_DK
.nm_set:
        mov     word [gfx_x], 90
        mov     [gfx_y], dx
        mov     [gfx_strptr], si
        push    bx
        push    dx
        call    DrawString_Limit12
        pop     dx
        pop     bx

        ; --- Token score ---
        cmp     bx, 0
        jne     .tk_normal
        mov     byte [gfx_color], C_TRUNK
        jmp     .tk_set
.tk_normal:
        mov     byte [gfx_color], C_DIRT_DK
.tk_set:
        mov     word [gfx_x], 232
        mov     [gfx_y], dx
        push    bx
        push    dx
        mov     ax, [si+16]
        call    DrawTokens
        pop     dx
        pop     bx

        ; " TOK" suffix in muted tone
        mov     byte [gfx_color], C_FENCE_DK
        mov     word [gfx_strptr], str_tok_short
        mov     [gfx_y], dx
        push    ax
        mov     ax, [gfx_x]
        add     ax, 2
        mov     [gfx_x], ax
        pop     ax
        push    bx
        push    dx
        call    DrawString
        pop     dx
        pop     bx

        add     dx, 12
.skip:
        inc     bx
        jmp     .lp

        ; ---------------------------------------------------------------
.done_list:
        cmp     byte [g_has_entries], 0
        jne     .has_entries
        ; "NO SCORES YET" centered in the cream panel
        mov     byte [gfx_scale], 2
        mov     byte [gfx_color], C_TRUNK
        mov     word [gfx_strptr], str_no_scores
        mov     word [gfx_y], 100
        call    DrawStringCenter
.has_entries:

        ; ---------------------------------------------------------------
        ; === FOOTER "PRESS ANY KEY" BUTTON ===
        ; Rounded button shape: outer dark ring, inner brown fill
        ; ---------------------------------------------------------------
        ; Outer shadow / border
        mov     word [gfx_x], 80
        mov     word [gfx_y], 182
        mov     word [gfx_w], 160
        mov     word [gfx_h], 14
        mov     byte [gfx_color], C_TRUNK
        call    FillRect
        ; Inner button face
        mov     word [gfx_x], 81
        mov     word [gfx_y], 183
        mov     word [gfx_w], 158
        mov     word [gfx_h], 12
        mov     byte [gfx_color], C_DIRT
        call    FillRect
        ; Top highlight stripe on button
        mov     word [gfx_x], 81
        mov     word [gfx_y], 183
        mov     word [gfx_w], 158
        mov     word [gfx_h], 2
        mov     byte [gfx_color], C_FENCE
        call    FillRect

        ; Button label text
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_TRUNK
        mov     word [gfx_strptr], str_press_any
        mov     word [gfx_y], 187
        call    DrawStringCenter

        ; ---------------------------------------------------------------
        call    Flip
        call    TransFadeIn
        call    FlushKeys
        call    WaitKey

        call    TransWipeDown
        mov     byte [g_state], ST_START
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

; ============================================================================
; DoLoading: Animated loading screen shown after login/register success.
; Draws the full farm scene + title, a wooden "LOADING..." badge, and a
; green progress bar that fills across 20 steps with a short delay each step.
; Call with no arguments; preserves all registers.
; ============================================================================
DoLoading:
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di

        ; --- Draw static background (difficulty-themed) ---
        mov     byte [gfx_color], C_SKY
        call    ClearBack
        call    DrawSceneDiff

        ; --- Draw farm title (FARM / COUNTING / FIESTA) ---
        mov     ax, 10
        call    DrawTitleBig

        ; ---------------------------------------------------------------
        ; Wooden sign badge for "LOADING..."
        ; Outer dark-wood ring
        ; ---------------------------------------------------------------
        mov     word [gfx_x], 85
        mov     word [gfx_y], 95
        mov     word [gfx_w], 150
        mov     word [gfx_h], 18
        mov     byte [gfx_color], C_TRUNK
        call    FillRect
        ; Inner lighter wood fill
        mov     word [gfx_x], 87
        mov     word [gfx_y], 96
        mov     word [gfx_w], 146
        mov     word [gfx_h], 16
        mov     byte [gfx_color], C_FENCE
        call    FillRect
        ; Top highlight stripe
        mov     word [gfx_x], 87
        mov     word [gfx_y], 96
        mov     word [gfx_w], 146
        mov     word [gfx_h], 2
        mov     byte [gfx_color], C_TITLE_O
        call    FillRect

        ; "LOADING..." text in dark brown on the wooden badge
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_TRUNK
        mov     word [gfx_strptr], str_loading
        mov     word [gfx_y], 101
        call    DrawStringCenter

        ; ---------------------------------------------------------------
        ; Progress bar outline (cream panel + dark border)
        ; Bar outer border
        ; ---------------------------------------------------------------
        mov     word [gfx_x], 40
        mov     word [gfx_y], 162
        mov     word [gfx_w], 240
        mov     word [gfx_h], 14
        mov     byte [gfx_color], C_TRUNK
        call    FillRect
        ; Bar inner background (cream)
        mov     word [gfx_x], 42
        mov     word [gfx_y], 163
        mov     word [gfx_w], 236
        mov     word [gfx_h], 12
        mov     byte [gfx_color], C_DIRT
        call    FillRect

        ; ---------------------------------------------------------------
        ; Animate progress bar: 20 steps, each fills 11px of green
        ; Total fill width = 220px  (steps * 11)
        ; ---------------------------------------------------------------
        xor     bx, bx          ; bx = step counter 0..19
.load_lp:
        cmp     bx, 20
        jae     .load_done

        ; Fill green bar segment for this step (x = 43 + bx*11, w=11)
        push    bx
        mov     ax, bx
        mov     cx, 11
        mul     cx              ; ax = bx * 11
        add     ax, 43          ; x start
        mov     [gfx_x], ax
        pop     bx

        mov     word [gfx_y], 164
        mov     word [gfx_w], 11
        mov     word [gfx_h], 10
        mov     byte [gfx_color], C_GRASS
        call    FillRect

        ; Green highlight stripe on top of bar fill
        push    bx
        mov     ax, bx
        mov     cx, 11
        mul     cx
        add     ax, 43
        mov     [gfx_x], ax
        pop     bx
        mov     word [gfx_y], 164
        mov     word [gfx_w], 11
        mov     word [gfx_h], 2
        mov     byte [gfx_color], C_GRASS_DK
        call    FillRect

        ; ---------------------------------------------------------------
        ; Percentage label below bar - fixed positions, no overlap
        ; "LOADING... " = 10 chars * 7 = 70px, percent up to 3 chars+% = 28px
        ; Total ~98px. Center at x=160 -> start at 160-49=111
        ; Clear label area wide enough for "LOADING... 100%"
        ; ---------------------------------------------------------------
        mov     word [gfx_x], 90
        mov     word [gfx_y], 178
        mov     word [gfx_w], 140
        mov     word [gfx_h], 9
        mov     byte [gfx_color], C_SKY_DK
        call    FillRect

        ; "LOADING..." at fixed x=111
        mov     byte [gfx_scale], 1
        mov     byte [gfx_color], C_WHITE
        mov     word [gfx_x], 111
        mov     word [gfx_y], 179
        mov     word [gfx_strptr], str_loading
        call    DrawString

        ; Space then percent number at fixed x=111+70+7=188
        ; (10 chars "LOADING..." + 1 space gap = 11*7=77, so x=111+77=188)
        mov     word [gfx_x], 188
        mov     word [gfx_y], 179
        push    bx
        inc     bx
        mov     ax, bx
        mov     cx, 5
        mul     cx              ; ax = percentage (5..100)
        pop     bx
        push    bx
        push    dx
        call    DrawNumber      ; draws digits, advances gfx_x
        pop     dx
        pop     bx

        ; "%" at gfx_x (already advanced by DrawNumber)
        push    bx
        mov     al, '%'
        call    DrawCh
        pop     bx

        call    Flip

        ; Short delay per step (~50ms each = ~1 second total)
        mov     ax, 50
        call    Delay

        inc     bx
        jmp     .load_lp

.load_done:
        ; Brief pause on 100% before transitioning
        mov     ax, 300
        call    Delay

        ; Do NOT call TransFadeOut here - DoBanner will draw over this
        ; and call TransFadeIn itself, keeping the palette live

        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

; DrawString_Limit12: Same as DrawString but stops after 12 chars to prevent
; overflowing into the score column.
DrawString_Limit12:
        push    ax
        push    bx
        push    cx
        push    dx
        push    si

        mov     si, [gfx_strptr]
        mov     bx, [gfx_x]
        xor     dx, dx              ; char count
.lp:
        cmp     dx, 12
        jae     .done
        mov     al, [si]
        cmp     al, 0
        je      .done
        call    DrawCh
        mov     al, [gfx_scale]
        xor     ah, ah
        mov     cx, 7
        mul     cx
        add     [gfx_x], ax
        inc     si
        inc     dx
        jmp     .lp
.done:
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

; ============================================================================
; DATA
; ============================================================================
g_back_seg:     dw 0

; ----- Game state -----
g_state:        db ST_START
g_mode:         db MODE_1P
g_diff:         db DIFF_EASY
g_p1score:      db 0    ; half-tokens
g_p2score:      db 0    ; half-tokens
g_curplayer:    db 1
g_animals:      db 3
g_animtype:     db 0
g_inbuf:        db 0,0,0,0,0
g_inlen:        db 0
g_seed:         dw 12345
g_hassb:        db 0
g_p1name:       times 16 db 0
g_p2name:       times 16 db 0
g_lastwin:      times 16 db 0
g_p1pass:       times 16 db 0
g_p2pass:       times 16 db 0
pw_mask_buf:    times 16 db 0

; New state for round-based duel & stats
g_round:        dw 1
g_p1answered:   db 0    ; 0=not yet, 1=correct, 2=wrong
g_p2answered:   db 0
g_p1played:     db 0
g_p2played:     db 0
g_p1total:      db 0    ; total rounds attempted
g_p2total:      db 0
g_p1correct:    db 0    ; total rounds correct
g_p2correct:    db 0
g_p1time:       dw 0    ; ticks for last answer
g_p2time:       dw 0
g_starttime:    dw 0
g_strikes:      db 0    ; 1P mode only
g_has_entries:  db 0    ; HiScores: tracks if any entries to display

; High score tables: 10 entries x 18 bytes each, one per mode
SINGLE_SCORES_FILE: db "SINGLE_SCORES.DAT",0
DUEL_SCORES_FILE:   db "DUEL_SCORES.DAT",0
g_single_scores:    times (10*18) db 0   ; single-player leaderboard
g_duel_scores:      times (10*18) db 0   ; duel-mode leaderboard

; Scratch: AddScoreToTable target and DoHiScores display pointer
score_tbl_base:     dw g_single_scores   ; set by AddSingleScore/AddDuelScore
hi_score_tbl_ptr:   dw g_single_scores   ; set by DoHiScores before list loop

; ----- UI Strings -----
str_title1:     db "FARM",0
str_title2:     db "COUNTING",0
str_title3:     db "FIESTA",0
str_press_start: db "PRESS START",0
str_how_play:   db "HOW TO PLAY?",0
str_tut1:       db "COUNT THE ANIMALS ON SCREEN",0
str_tut2:       db "TYPE ANSWER ON KEYBOARD",0
str_tut3:       db "PRESS ENTER TO CONFIRM",0
str_tut4:       db "FIRST TO 5 BARN TOKENS WINS",0
str_tut5:       db "DUEL: BOTH ANSWER SAME PROMPT",0
str_tut6:       db "EACH CORRECT = 1 BARN TOKEN",0
str_tut7:       db "1P MODE: 3 WRONG = GAME OVER",0
str_select_mode: db "SELECT MODE",0
str_single:     db "SINGLE PLAYER",0
str_duel:       db "FARM DUEL",0
str_select_diff: db "SELECT DIFFICULTY",0
str_easy:       db "EASY",0
str_medium:     db "MEDIUM",0
str_hard:       db "HARD",0
str_enter_name: db "ENTER YOUR NAME",0
str_set_pass:   db "SET YOUR PASSWORD",0
str_pass_hint:  db "MAX 8 CHARS  ESC=BACK",0
str_p1lbl:      db "PLAYER 1",0
str_p2lbl:      db "PLAYER 2",0
str_player_word: db "PLAYER",0
str_how_many:   db "HOW MANY ANIMALS?",0
str_correct:    db "CORRECT!",0
str_wrong:      db "WRONG!",0
str_winner:     db "WINNER!",0
str_game_over:  db "GAME OVER",0
str_press_any:  db "PRESS ANY KEY",0
str_high_scores: db "HIGH SCORES",0
str_no_scores:  db "NO SCORES YET",0
str_footer:     db "ENTER=OK  ESC=BACK",0
str_enter_ok:   db "ENTER=OK",0
str_esc_back:   db "ESC=BACK",0
str_key_enter:  db "ENTER",0
str_key_esc:    db "ESC",0
str_lbl_ok:     db "OK",0
str_lbl_back:   db "BACK",0
str_answer_was: db "ANSWER WAS",0
str_answer_lbl: db "ANSWER:",0
str_tok:        db "TOK:",0
str_tok_short:  db " TOK",0
str_r_lbl:      db "R:",0
str_round:      db "ROUND",0
str_round_end:  db "ROUND OVER",0
str_p1turn:     db "PLAYER 1 TURN",0
str_p2turn:     db "PLAYER 2 TURN",0
str_correct_short: db "OK",0
str_wrong_short: db "X",0
str_plus:       db "+",0
str_p1faster:   db "PLAYER 1 WAS FASTER!",0
str_p2faster:   db "PLAYER 2 WAS FASTER!",0
str_lives:      db "LIVES",0
str_out_of_lives: db "TOO MANY WRONG ANSWERS",0
str_final_tok:  db "TOKENS:",0
str_final_acc:  db "CORRECT:",0
str_hdr_rank:   db "RANK",0
str_hdr_name:   db "NAME",0
str_hdr_tok:    db "TOKENS",0
str_loading:    db "LOADING...",0

; SFX tables
sfx_correct:    dw 784,60, 988,60, 1175,80, 1568,120, 0
sfx_wrong:      dw 330,80, 277,80, 220,80, 185,200, 0
sfx_click:      dw 1320,20, 0
sfx_victory:    dw 523,80, 659,80, 784,80, 1047,80, 1319,80, 1047,60, 1319,200, 0
sfx_lose:       dw 392,100, 330,100, 294,100, 247,100, 220,200, 0
sfx_start:      dw 523,60, 659,60, 784,60, 1047,120, 0
sfx_roundstart: dw 659,50, 784,50, 1047,100, 0
sfx_roundend:   dw 784,60, 1047,60, 1319,60, 1047,60, 784,120, 0
sfx_namedone:   dw 880,40, 1047,40, 1319,80, 0
sfx_tick:       dw 1760,15, 0
sfx_bgloop:     dw 523,80, 523,40, 659,80, 659,40, 784,80, 659,40, 523,80, 523,160, 0

; Background music engine state
bg_old8_off:    dw 0            ; saved INT 8h offset
bg_old8_seg:    dw 0            ; saved INT 8h segment
bg_note_ptr:    dw bg_melody    ; pointer into melody table
bg_tick_cnt:    dw 1            ; ticks remaining for current note
bg_active:      db 0            ; 1 = playing
bg_paused:      db 0            ; >0 = paused (during SFX)

; Transition scratch
tr_firstdraw:   db 0            ; used by states that fade in only once

; Background melody table: dw frequency_hz, ticks_at_18hz
; ticks=0 means "loop back to start"
; ~18 ticks = 1 second.  Each note here ~1-4 ticks = ~55-220ms
; Melody: a cheerful farm tune in C major
bg_melody:
        dw  523, 2      ; C5
        dw  523, 1      ; C5 short
        dw  659, 2      ; E5
        dw  784, 2      ; G5
        dw  1047,2      ; C6
        dw  784, 1      ; G5
        dw  659, 2      ; E5
        dw  523, 3      ; C5 hold
        dw  0,   1      ; rest
        dw  698, 2      ; F5
        dw  880, 2      ; A5
        dw  1047,2      ; C6
        dw  880, 1      ; A5
        dw  698, 2      ; F5
        dw  523, 3      ; C5 hold
        dw  0,   1      ; rest
        dw  784, 2      ; G5
        dw  988, 2      ; B5
        dw  1175,2      ; D6
        dw  988, 1      ; B5
        dw  784, 2      ; G5
        dw  659, 2      ; E5
        dw  523, 2      ; C5
        dw  392, 2      ; G4
        dw  523, 4      ; C5 long hold
        dw  0,   2      ; rest
        dw  0,   0      ; ← loop marker (ticks=0)

; Drawing globals
gfx_x:          dw 0
gfx_y:          dw 0
gfx_w:          dw 0
gfx_h:          dw 0
gfx_color:      db 0
gfx_color2:     db 0
gfx_scale:      db 1
gfx_strptr:     dw 0

; Temp scratch
tmp_x:          dw 0
tmp_y:          dw 0
tmp_w:          dw 0
tmp_h:          dw 0
tmp_x2:         dw 0
tmp_save_color: db 0
row_cnt1:       dw 0
row_cnt2:       dw 0

palette_data:
        db  0,0,0
        db  63,63,63
        db  20,40,60
        db  15,30,50
        db  18,50,18
        db  10,32,8
        db  50,40,25
        db  35,25,15
        db  55,15,15
        db  35,8,8
        db  35,35,38
        db  10,40,15
        db  35,20,10
        db  60,55,15
        db  55,55,58
        db  45,30,15
        db  30,18,8
        db  60,40,10
        db  20,55,20
        db  60,60,20
        db  60,50,15
        db  55,30,10
        db  20,55,25
        db  50,15,55
        db  55,15,15
        db  20,50,55
        db  60,45,12
        db  55,45,15
        db  40,40,40
        db  40,40,40
        db  20,20,20
        db  60,40,45
        db  45,25,30
        db  10,10,10
        db  60,40,10
        db  55,15,15

; ---- Account DB (saved to ACCOUNTS.DAT) ----
; Layout: db_usernames[16*16] immediately followed by db_passwords[16*16]
; LoadAccounts reads DB_MAX_USERS*32 bytes starting at db_usernames in one shot.
DB_MAX_USERS    equ 16
ACCOUNTS_FILE:  db "ACCOUNTS.DAT",0
db_usernames:   times (DB_MAX_USERS*16) db 0   ; 16 slots x 16 bytes
db_passwords:   times (DB_MAX_USERS*16) db 0   ; passwords, same layout

; Auth scratch
auth_errmsg:    db 0    ; 0=none 1=not found 2=wrong pass 3=duplicate/full
auth_slot:      dw 0    ; slot index found/chosen during auth
auth_mode:      db 0    ; 0=login, 1=register

; Auth UI strings
str_auth_title:     db "ACCOUNT",0
str_login:          db "LOGIN",0
str_register:       db "REGISTER",0
str_acct_not_found: db "ACCOUNT NOT FOUND",0
str_wrong_pass:     db "INCORRECT PASSWORD",0
str_usr_exists:     db "USERNAME ALREADY EXISTS",0

        align   16
stack_bot:      times 2048 db 0
stack_top       equ $
prog_end:
