# Mini CAD - RISC-V Assembly for RARS 1.6
# ============================================================
# Bitmap Display: Base=0x10010000 (static data)
#   Unit Width=4, Unit Height=4, Display=512x512
# Commands:
#   line x1 y1 x2 y2
#   rectangle x1 y1 x2 y2
#   circle x y r
#   color n        (n=0-15)
#   fill x y
#   clear          (reset bitmap to white)
# ============================================================

.eqv KBD_READY   0xFFFF0000
.eqv KBD_DATA    0xFFFF0004
.eqv DSP_DATA    0xFFFF000C
.eqv WHITE       0x00FFFFFF

.data
# bitmap_buf MUST be first
bitmap_buf: .space 65536
cmd_buf:    .space 80
cur_color:  .word 0x00FF0000

colors:
    .word 0x00000000   # 0  black
    .word 0x00FFFFFF   # 1  white
    .word 0x00FF0000   # 2  red
    .word 0x0000FF00   # 3  green
    .word 0x000000FF   # 4  blue
    .word 0x00FFFF00   # 5  yellow
    .word 0x00FF00FF   # 6  magenta
    .word 0x0000FFFF   # 7  cyan
    .word 0x00FF8000   # 8  orange
    .word 0x00800080   # 9  purple
    .word 0x00804000   # 10 brown
    .word 0x00808080   # 11 gray
    .word 0x00FFC0CB   # 12 pink
    .word 0x0090EE90   # 13 light green
    .word 0x00ADD8E6   # 14 light blue
    .word 0x00C0C0C0   # 15 silver

fill_stack: .space 131072

msg_welcome: .asciz "\n=== Mini CAD RISC-V ===\n"
msg_prompt:  .asciz "> "
msg_ok_ln:   .asciz "[OK] line\n"
msg_ok_rc:   .asciz "[OK] rectangle\n"
msg_ok_ci:   .asciz "[OK] circle\n"
msg_ok_co:   .asciz "[OK] color\n"
msg_ok_fi:   .asciz "[OK] fill\n"
msg_ok_cl:   .asciz "[OK] cleared\n"
msg_err_sy:  .asciz "[ERR] unknown command\n"
msg_err_ar:  .asciz "[ERR] bad arguments\n"
msg_err_bn:  .asciz "[ERR] out of bounds\n"
msg_err_co:  .asciz "[ERR] color 0-15\n"
msg_nl:      .asciz "\n"

s_line:      .asciz "line"
s_rect:      .asciz "rectangle"
s_circle:    .asciz "circle"
s_color:     .asciz "color"
s_fill:      .asciz "fill"
s_clear:     .asciz "clear"

.text
.globl main

# ============================================================
# MAIN
# ============================================================
main:
    la   a0, msg_welcome
    call puts
    call clear_bmp          # fill white at startup

main_loop:
    la   a0, msg_prompt
    call puts
    la   a0, cmd_buf
    li   a1, 76
    call readline
    la   t0, cmd_buf
    lb   t1, 0(t0)
    beqz t1, main_loop      # empty line, re-prompt
    call dispatch
    j    main_loop

# ============================================================
# clear_bmp: fill entire bitmap with WHITE
# ============================================================
clear_bmp:
    la   t0, bitmap_buf
    li   t1, 65536
    add  t1, t0, t1
    li   t2, WHITE
cbm_lp:
    bge  t0, t1, cbm_done
    sw   t2, 0(t0)
    addi t0, t0, 4
    j    cbm_lp
cbm_done:
    ret

# ============================================================
# readline: read one line, handle Backspace
# a0=buf, a1=maxlen
# Backspace (8 or 127): removes last char from buffer & display
# ============================================================
readline:
    mv   t0, a0             # t0 = buffer base
    li   t3, 0              # t3 = current char count
rl_lp:
    # wait keyboard ready
    li   t4, KBD_READY
rl_wt:
    lw   t5, 0(t4)
    andi t5, t5, 1
    beqz t5, rl_wt

    li   t4, KBD_DATA
    lw   t5, 0(t4)
    andi t5, t5, 0xFF

    # Enter (10 or 13) -> done
    li   t6, 10
    beq  t5, t6, rl_done
    li   t6, 13
    beq  t5, t6, rl_done

    # Backspace (8) or Delete (127)
    li   t6, 8
    beq  t5, t6, rl_bs
    li   t6, 127
    beq  t5, t6, rl_bs

    # filter other non-printable
    li   t6, 32
    blt  t5, t6, rl_lp

    # buffer full?
    bge  t3, a1, rl_lp

    # store char and echo
    add  t6, t0, t3
    sb   t5, 0(t6)
    addi t3, t3, 1
    li   t6, DSP_DATA
    sw   t5, 0(t6)
    j    rl_lp

rl_bs:
    # ignore if buffer empty
    beqz t3, rl_lp
    # remove last char from buffer
    addi t3, t3, -1
    add  t6, t0, t3
    sb   zero, 0(t6)
    # send backspace sequence to display: BS SPACE BS
    li   t6, DSP_DATA
    li   t5, 8
    sw   t5, 0(t6)
    li   t5, 32
    sw   t5, 0(t6)
    li   t5, 8
    sw   t5, 0(t6)
    j    rl_lp

rl_done:
    # null-terminate
    add  t6, t0, t3
    sb   zero, 0(t6)
    # newline on display
    li   t6, DSP_DATA
    li   t5, 10
    sw   t5, 0(t6)
    ret

# ============================================================
# dispatch: parse cmd_buf and call handler
# ============================================================
dispatch:
    addi sp, sp, -60
    sw   ra, 56(sp)
    sw   s0, 52(sp)
    sw   s1, 48(sp)
    sw   s2, 44(sp)
    sw   s3, 40(sp)
    sw   s4, 36(sp)
    sw   s5, 32(sp)

    la   s0, cmd_buf

    # split at first space
    mv   t0, s0
dp_sp:
    lb   t1, 0(t0)
    beqz t1, dp_eol
    li   t2, 32
    beq  t1, t2, dp_spl
    addi t0, t0, 1
    j    dp_sp
dp_spl:
    sb   zero, 0(t0)
    addi s1, t0, 1
    j    dp_cmp
dp_eol:
    mv   s1, t0

dp_cmp:
    la   a0, s_line
    mv   a1, s0
    call streq
    bnez a0, cmd_line

    la   a0, s_rect
    mv   a1, s0
    call streq
    bnez a0, cmd_rect

    la   a0, s_circle
    mv   a1, s0
    call streq
    bnez a0, cmd_circle

    la   a0, s_color
    mv   a1, s0
    call streq
    bnez a0, cmd_color

    la   a0, s_fill
    mv   a1, s0
    call streq
    bnez a0, cmd_fill

    la   a0, s_clear
    mv   a1, s0
    call streq
    bnez a0, cmd_clear

    la   a0, msg_err_sy
    call puts
    j    dp_ret

# ---- LINE ----
cmd_line:
    mv   a0, s1
    call pint
    li   t0, -1
    beq  a0, t0, dp_ea
    mv   s2, a0
    mv   s1, a1

    mv   a0, s1
    call pint
    li   t0, -1
    beq  a0, t0, dp_ea
    mv   s3, a0
    mv   s1, a1

    mv   a0, s1
    call pint
    li   t0, -1
    beq  a0, t0, dp_ea
    mv   s4, a0
    mv   s1, a1

    mv   a0, s1
    call pint
    li   t0, -1
    beq  a0, t0, dp_ea
    mv   s5, a0

    mv   a0, s2
    mv   a1, s3
    mv   a2, s4
    mv   a3, s5
    call chk4
    bnez a0, dp_eb

    la   a0, msg_ok_ln
    call puts
    mv   a0, s2
    mv   a1, s3
    mv   a2, s4
    mv   a3, s5
    call draw_line
    j    dp_ret

# ---- RECTANGLE ----
cmd_rect:
    mv   a0, s1
    call pint
    li   t0, -1
    beq  a0, t0, dp_ea
    mv   s2, a0
    mv   s1, a1

    mv   a0, s1
    call pint
    li   t0, -1
    beq  a0, t0, dp_ea
    mv   s3, a0
    mv   s1, a1

    mv   a0, s1
    call pint
    li   t0, -1
    beq  a0, t0, dp_ea
    mv   s4, a0
    mv   s1, a1

    mv   a0, s1
    call pint
    li   t0, -1
    beq  a0, t0, dp_ea
    mv   s5, a0

    mv   a0, s2
    mv   a1, s3
    mv   a2, s4
    mv   a3, s5
    call chk4
    bnez a0, dp_eb

    la   a0, msg_ok_rc
    call puts
    mv   a0, s2
    mv   a1, s3
    mv   a2, s4
    mv   a3, s5
    call draw_rect
    j    dp_ret

# ---- CIRCLE ----
cmd_circle:
    mv   a0, s1
    call pint
    li   t0, -1
    beq  a0, t0, dp_ea
    mv   s2, a0
    mv   s1, a1

    mv   a0, s1
    call pint
    li   t0, -1
    beq  a0, t0, dp_ea
    mv   s3, a0
    mv   s1, a1

    mv   a0, s1
    call pint
    li   t0, -1
    beq  a0, t0, dp_ea
    mv   s4, a0

    li   t0, 0
    li   t1, 127
    blt  s2, t0, dp_eb
    bgt  s2, t1, dp_eb
    blt  s3, t0, dp_eb
    bgt  s3, t1, dp_eb
    blt  s4, t0, dp_eb

    la   a0, msg_ok_ci
    call puts
    mv   a0, s2
    mv   a1, s3
    mv   a2, s4
    call draw_circle
    j    dp_ret

# ---- COLOR ----
cmd_color:
    mv   a0, s1
    call pint
    li   t0, -1
    beq  a0, t0, dp_ea
    mv   s2, a0

    li   t0, 0
    li   t1, 15
    blt  s2, t0, dp_ec
    bgt  s2, t1, dp_ec

    la   t0, colors
    slli t1, s2, 2
    add  t0, t0, t1
    lw   t2, 0(t0)
    la   t3, cur_color
    sw   t2, 0(t3)

    la   a0, msg_ok_co
    call puts
    j    dp_ret

# ---- FILL ----
cmd_fill:
    mv   a0, s1
    call pint
    li   t0, -1
    beq  a0, t0, dp_ea
    mv   s2, a0
    mv   s1, a1

    mv   a0, s1
    call pint
    li   t0, -1
    beq  a0, t0, dp_ea
    mv   s3, a0

    li   t0, 0
    li   t1, 127
    blt  s2, t0, dp_eb
    bgt  s2, t1, dp_eb
    blt  s3, t0, dp_eb
    bgt  s3, t1, dp_eb

    la   a0, msg_ok_fi
    call puts
    mv   a0, s2
    mv   a1, s3
    call flood_fill
    j    dp_ret

# ---- CLEAR ----
cmd_clear:
    call clear_bmp
    la   a0, msg_ok_cl
    call puts
    j    dp_ret

dp_ea:
    la   a0, msg_err_ar
    call puts
    j    dp_ret
dp_eb:
    la   a0, msg_err_bn
    call puts
    j    dp_ret
dp_ec:
    la   a0, msg_err_co
    call puts

dp_ret:
    lw   ra, 56(sp)
    lw   s0, 52(sp)
    lw   s1, 48(sp)
    lw   s2, 44(sp)
    lw   s3, 40(sp)
    lw   s4, 36(sp)
    lw   s5, 32(sp)
    addi sp, sp, 60
    ret

# ============================================================
# chk4: x1,y1,x2,y2 all in [0,127] -> a0=0 ok, 1 fail
# ============================================================
chk4:
    li   t0, 0
    li   t1, 127
    blt  a0, t0, chk4f
    bgt  a0, t1, chk4f
    blt  a1, t0, chk4f
    bgt  a1, t1, chk4f
    blt  a2, t0, chk4f
    bgt  a2, t1, chk4f
    blt  a3, t0, chk4f
    bgt  a3, t1, chk4f
    li   a0, 0
    ret
chk4f:
    li   a0, 1
    ret

# ============================================================
# pint: parse unsigned integer, skip leading spaces
# a0=ptr -> a0=value(-1 err), a1=ptr after
# ============================================================
pint:
pi_sk:
    lb   t0, 0(a0)
    beqz t0, pi_er
    li   t1, 32
    beq  t0, t1, pi_nx
    li   t1, 9
    beq  t0, t1, pi_nx
    j    pi_dg
pi_nx:
    addi a0, a0, 1
    j    pi_sk
pi_dg:
    li   t2, 0
    li   t3, 0
pi_lp:
    lb   t0, 0(a0)
    beqz t0, pi_ok
    li   t1, 32
    beq  t0, t1, pi_ok
    li   t1, 9
    beq  t0, t1, pi_ok
    li   t1, 48
    blt  t0, t1, pi_er
    li   t1, 57
    bgt  t0, t1, pi_er
    li   t4, 10
    mul  t2, t2, t4
    addi t0, t0, -48
    add  t2, t2, t0
    addi t3, t3, 1
    addi a0, a0, 1
    j    pi_lp
pi_ok:
    beqz t3, pi_er
    mv   a1, a0
    mv   a0, t2
    ret
pi_er:
    li   a0, -1
    ret

# ============================================================
# streq: a0=s1, a1=s2 -> a0=1 if equal
# ============================================================
streq:
sq_lp:
    lb   t0, 0(a0)
    lb   t1, 0(a1)
    bne  t0, t1, sq_no
    beqz t0, sq_yes
    addi a0, a0, 1
    addi a1, a1, 1
    j    sq_lp
sq_yes:
    li   a0, 1
    ret
sq_no:
    li   a0, 0
    ret

# ============================================================
# set_pixel: plot (x,y) with cur_color, clips silently
# a0=x, a1=y
# ============================================================
set_pixel:
    li   t0, 0
    li   t1, 127
    blt  a0, t0, spr
    bgt  a0, t1, spr
    blt  a1, t0, spr
    bgt  a1, t1, spr
    li   t0, 128
    mul  t2, a1, t0
    add  t2, t2, a0
    slli t2, t2, 2
    la   t0, bitmap_buf
    add  t0, t0, t2
    la   t1, cur_color
    lw   t1, 0(t1)
    sw   t1, 0(t0)
spr:
    ret

# ============================================================
# get_pixel: return color at (x,y), -1 if OOB
# a0=x, a1=y -> a0=color
# ============================================================
get_pixel:
    li   t0, 0
    li   t1, 127
    blt  a0, t0, gp_ob
    bgt  a0, t1, gp_ob
    blt  a1, t0, gp_ob
    bgt  a1, t1, gp_ob
    li   t0, 128
    mul  t2, a1, t0
    add  t2, t2, a0
    slli t2, t2, 2
    la   t0, bitmap_buf
    add  t0, t0, t2
    lw   a0, 0(t0)
    ret
gp_ob:
    li   a0, -1
    ret

# ============================================================
# draw_line: Bresenham  a0=x1,a1=y1,a2=x2,a3=y2
# ============================================================
draw_line:
    addi sp, sp, -52
    sw   ra, 48(sp)
    sw   s0, 44(sp)
    sw   s1, 40(sp)
    sw   s2, 36(sp)
    sw   s3, 32(sp)
    sw   s4, 28(sp)
    sw   s5, 24(sp)
    sw   s6, 20(sp)
    sw   s7, 16(sp)
    sw   s8, 12(sp)
    mv   s0, a0
    mv   s1, a1
    mv   s2, a2
    mv   s3, a3
    sub  s4, s2, s0
    bgez s4, dl_d1
    neg  s4, s4
dl_d1:
    sub  s5, s3, s1
    bgez s5, dl_d2
    neg  s5, s5
dl_d2:
    sub  t0, s2, s0
    li   s6, 1
    bgtz t0, dl_s1
    li   s6, -1
    bnez t0, dl_s1
    li   s6, 0
dl_s1:
    sub  t0, s3, s1
    li   s7, 1
    bgtz t0, dl_s2
    li   s7, -1
    bnez t0, dl_s2
    li   s7, 0
dl_s2:
    sub  s8, s4, s5
dl_lp:
    mv   a0, s0
    mv   a1, s1
    call set_pixel
    beq  s0, s2, dl_cy
    j    dl_mv
dl_cy:
    beq  s1, s3, dl_dn
dl_mv:
    slli t6, s8, 1
    neg  t0, s5
    ble  t6, t0, dl_sk1
    sub  s8, s8, s5
    add  s0, s0, s6
dl_sk1:
    bge  t6, s4, dl_sk2
    add  s8, s8, s4
    add  s1, s1, s7
dl_sk2:
    j    dl_lp
dl_dn:
    lw   ra, 48(sp)
    lw   s0, 44(sp)
    lw   s1, 40(sp)
    lw   s2, 36(sp)
    lw   s3, 32(sp)
    lw   s4, 28(sp)
    lw   s5, 24(sp)
    lw   s6, 20(sp)
    lw   s7, 16(sp)
    lw   s8, 12(sp)
    addi sp, sp, 52
    ret

# ============================================================
# draw_rect: 4 sides  a0=x1,a1=y1,a2=x2,a3=y2
# ============================================================
draw_rect:
    addi sp, sp, -36
    sw   ra, 32(sp)
    sw   s0, 28(sp)
    sw   s1, 24(sp)
    sw   s2, 20(sp)
    sw   s3, 16(sp)
    mv   s0, a0
    mv   s1, a1
    mv   s2, a2
    mv   s3, a3
    mv   a0, s0
    mv   a1, s1
    mv   a2, s2
    mv   a3, s1
    call draw_line
    mv   a0, s0
    mv   a1, s3
    mv   a2, s2
    mv   a3, s3
    call draw_line
    mv   a0, s0
    mv   a1, s1
    mv   a2, s0
    mv   a3, s3
    call draw_line
    mv   a0, s2
    mv   a1, s1
    mv   a2, s2
    mv   a3, s3
    call draw_line
    lw   ra, 32(sp)
    lw   s0, 28(sp)
    lw   s1, 24(sp)
    lw   s2, 20(sp)
    lw   s3, 16(sp)
    addi sp, sp, 36
    ret

# ============================================================
# draw_circle: midpoint  a0=cx,a1=cy,a2=r
# ============================================================
draw_circle:
    addi sp, sp, -32
    sw   ra, 28(sp)
    sw   s0, 24(sp)
    sw   s1, 20(sp)
    sw   s2, 16(sp)
    sw   s3, 12(sp)
    sw   s4,  8(sp)
    sw   s5,  4(sp)
    mv   s0, a0
    mv   s1, a1
    mv   s2, a2
    li   s3, 0
    mv   s4, a2
    li   s5, 1
    sub  s5, s5, s2
dc_lp:
    bgt  s3, s4, dc_dn
    add  a0, s0, s3
    add  a1, s1, s4
    call set_pixel
    sub  a0, s0, s3
    add  a1, s1, s4
    call set_pixel
    add  a0, s0, s3
    sub  a1, s1, s4
    call set_pixel
    sub  a0, s0, s3
    sub  a1, s1, s4
    call set_pixel
    add  a0, s0, s4
    add  a1, s1, s3
    call set_pixel
    sub  a0, s0, s4
    add  a1, s1, s3
    call set_pixel
    add  a0, s0, s4
    sub  a1, s1, s3
    call set_pixel
    sub  a0, s0, s4
    sub  a1, s1, s3
    call set_pixel
    addi s3, s3, 1
    bgez s5, dc_dy
    slli t0, s3, 1
    add  s5, s5, t0
    addi s5, s5, 1
    j    dc_lp
dc_dy:
    addi s4, s4, -1
    sub  t0, s3, s4
    slli t0, t0, 1
    add  s5, s5, t0
    addi s5, s5, 1
    j    dc_lp
dc_dn:
    lw   ra, 28(sp)
    lw   s0, 24(sp)
    lw   s1, 20(sp)
    lw   s2, 16(sp)
    lw   s3, 12(sp)
    lw   s4,  8(sp)
    lw   s5,  4(sp)
    addi sp, sp, 32
    ret

# ============================================================
# flood_fill: iterative BFS  a0=x, a1=y
# ============================================================
flood_fill:
    addi sp, sp, -36
    sw   ra, 32(sp)
    sw   s0, 28(sp)
    sw   s1, 24(sp)
    sw   s2, 20(sp)
    sw   s3, 16(sp)
    sw   s4, 12(sp)
    sw   s5,  8(sp)
    mv   s0, a0
    mv   s1, a1
    call get_pixel
    mv   s2, a0             # target color
    la   t0, cur_color
    lw   s3, 0(t0)          # fill color
    beq  s2, s3, ff_dn
    la   s4, fill_stack
    li   s5, 0
    slli t0, s1, 16
    or   t0, t0, s0
    sw   t0, 0(s4)
    addi s5, s5, 1
ff_lp:
    beqz s5, ff_dn
    addi s5, s5, -1
    slli t1, s5, 2
    add  t2, s4, t1
    lw   t0, 0(t2)
    slli t3, t0, 16
    srli t3, t3, 16         # x
    srli t4, t0, 16         # y
    mv   a0, t3
    mv   a1, t4
    call get_pixel
    bne  a0, s2, ff_lp
    mv   a0, t3
    mv   a1, t4
    call set_pixel
    li   t6, 32760
    # left
    addi t5, t3, -1
    bltz t5, ff_nL
    bge  s5, t6, ff_dn
    slli t0, t4, 16
    or   t0, t0, t5
    slli t1, s5, 2
    add  t2, s4, t1
    sw   t0, 0(t2)
    addi s5, s5, 1
ff_nL:
    # right
    addi t5, t3, 1
    li   t0, 128
    bge  t5, t0, ff_nR
    bge  s5, t6, ff_dn
    slli t0, t4, 16
    or   t0, t0, t5
    slli t1, s5, 2
    add  t2, s4, t1
    sw   t0, 0(t2)
    addi s5, s5, 1
ff_nR:
    # up
    addi t5, t4, -1
    bltz t5, ff_nU
    bge  s5, t6, ff_dn
    slli t0, t5, 16
    or   t0, t0, t3
    slli t1, s5, 2
    add  t2, s4, t1
    sw   t0, 0(t2)
    addi s5, s5, 1
ff_nU:
    # down
    addi t5, t4, 1
    li   t0, 128
    bge  t5, t0, ff_nD
    bge  s5, t6, ff_dn
    slli t0, t5, 16
    or   t0, t0, t3
    slli t1, s5, 2
    add  t2, s4, t1
    sw   t0, 0(t2)
    addi s5, s5, 1
ff_nD:
    j    ff_lp
ff_dn:
    lw   ra, 32(sp)
    lw   s0, 28(sp)
    lw   s1, 24(sp)
    lw   s2, 20(sp)
    lw   s3, 16(sp)
    lw   s4, 12(sp)
    lw   s5,  8(sp)
    addi sp, sp, 36
    ret

# ============================================================
# puts: print null-terminated string  a0=ptr
# ============================================================
puts:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   s0, 0(sp)
    mv   s0, a0
puts_lp:
    lb   t0, 0(s0)
    beqz t0, puts_dn
    li   t1, DSP_DATA
    sw   t0, 0(t1)
    addi s0, s0, 1
    j    puts_lp
puts_dn:
    lw   ra, 4(sp)
    lw   s0, 0(sp)
    addi sp, sp, 8
    ret
