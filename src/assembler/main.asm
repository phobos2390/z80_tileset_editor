; file: main.asm

#include assembler_constants.asm

#define key_buffer_size $E000
#define key_buffer ram_start + 1
#define cursor_val ram_start + 2
#define view_key ram_start + 3
#define color_value ram_start + 4
#define charedit_row ram_start + 5
#define charedit_col ram_start + 6
#define charedit_save_color ram_start + 7
#define tick_value_buffer + 8
#define grid_width_h grid_width / 2
#define cursor_key $8F
#define tileset_size (tileset_width_bytes * tileset_height)
#define tileset_finish tileset_start + (tileset_size * $100)

#define charlist_row_start $A
#define charlist_col_start $1

#define charlist_width  $10
#define charlist_height $10

#define tileset_pixels_row_start $1
#define tileset_pixels_col_start $1
#define tileset_pixels_start display_start + (tileset_pixels_col_start) + (tileset_pixels_row_start * grid_width)

#define char_select_row $0
#define char_select_col $B
#define char_select_addr display_start + char_select_col + (char_select_row * grid_width) 

#define red_location   display_start + $0B + ($2 * grid_width)
#define green_location display_start + $0D + ($2 * grid_width)
#define blue_location  display_start + $0F + ($2 * grid_width)
#define color_location  display_start + $0D + ($4 * grid_width)
#define select_char_location  display_start + $0D + ($6 * grid_width)

#define red_mask   $30
#define inv_red_mask $CF
#define green_mask $0C
#define inv_green_mask $F3
#define blue_mask  $03
#define inv_blue_mask $FC

#define two_bit_mask $03

#define charedit_mask $07

start:
  jp main

isr_table:
.db isr_start
.db $0

isr_start:
  di
  ex af,af'
  exx

  ld a, (key_input_location)
  ld (key_buffer), a
  ld a, $0  
  ld (key_input_location), a

  exx
  ex af,af'  
  ret
  
main:
  call print_pixel_enclosure
  call load_tileset
  im 2
  ld hl, isr_table
  ld a, h
  ld i, a
  ld a, l
  ld (interrupt_data), a
  call create_solid_pixel_colors
  call write_complete_tileset
  ld a, '0'
  ld (red_location), a
  ld (green_location), a
  ld (blue_location), a
  ld a, $C0
  ld (color_value), a
  ld (color_location), a
  ld a, $0
  ld (view_key), a
  ld b, a
  call write_tile_b_to_view
  push hl
  ld hl, sprite_table_start
  ; sprite 0 Y
  ld a, $8
  ld (hl), a
  inc hl
  ; sprite 0 X
  ld (hl), a
  inc hl
  ; sprite 0 character
  ld a, $94
  ld (hl), a
  inc hl
  ; sprite 0 flags
  ld a, $80
  ld (hl), a
  inc hl
  ; sprite 1 Y
  ld a, $50
  ld (hl), a
  ; sprite 1 X
  ld a, $8
  ld (hl), a
  inc hl
  ; sprite 1 character
  ld a, $94
  ld (hl), a
  inc hl
  ; sprite 1 flags
  ld a, $A0 ; reversed
  ld (hl), a
  pop hl
main_loop:
  ei
  halt
main_process_input:
  ld a, (key_buffer)
  sub $01
  jp z, main_up
  add a, $01
  sub $02
  jp z, main_down
  add a, $02
  sub $03
  jp z, main_left
  add a, $03
  sub $04
  jp z, main_right
  add a, $04
  sub 'j'
  jp z, main_red_up
  add a, 'j'
  sub 'k'
  jp z, main_green_up
  add a, 'k'
  sub 'l'
  jp z, main_blue_up
  add a, 'l'
  sub 'a'
  jp z, main_charedit_left
  add a, 'a'
  sub 'd'
  jp z, main_charedit_right
  add a, 'd'
  sub 'w'
  jp z, main_charedit_up
  add a, 'w'
  sub 's'
  jp z, main_charedit_down
  add a, 's'
  sub 'h'
  jp z, main_set_pixel
  add a, 'h'
  sub '0'
  jp z, main_save_tileset
  add a, '0'
  jp main_loop

main_save_tileset:
  call write_full_tileset_persistence
  jp main_loop

main_set_pixel:
  call set_charedit
  jp main_loop

main_charedit_up:
;  call put_color
  ld a, (charedit_row)
  dec a
  and charedit_mask
  ld (charedit_row), a
  jp charedit_end

main_charedit_left:
;  call put_color
  ld a, (charedit_col)
  dec a
  and charedit_mask
  ld (charedit_col), a
  jp charedit_end

main_charedit_right:
;  call put_color
  ld a, (charedit_col)
  inc a
  and charedit_mask
  ld (charedit_col), a
  jp charedit_end

main_charedit_down:
;  call put_color
  ld a, (charedit_row)
  inc a
  and charedit_mask
  ld (charedit_row), a
  jp charedit_end

put_color:
  push bc
    ld a, (charedit_col)
    ld b, a
    ld a, (charedit_row)
    ld c, a
    push hl
      call get_charedit_hl_b_c
;      ld a, (charedit_save_color)
;      ld (hl), a
    pop hl
  pop bc
  ret

charedit_put_view_pixel:
  push bc
    ld a, (charedit_col)
    ld b, a
    ld a, (charedit_row)
    ld c, a
    push hl
      call get_charedit_hl_b_c
      ld a, (color_value)
      ld (hl), a
    pop hl
  pop bc
  ret

charedit_end:
  push bc
    ld a, (charedit_col)
    ld b, a
    ld a, (charedit_row)
    ld c, a
    push hl
      call get_charedit_hl_b_c
;      ld a, (hl)
;      ld (charedit_save_color), a
;      ld a, (color_value)
;      ld (hl), a
    pop hl
    push hl
      push de
        ld a, $0
        ld h, a
        ld a, $8
        ld l, a
        ld a, b
_charedit_sprite_col_loop:
        push de
          push af
            ld a, $0
            ld d, a
            ld a, $8
            ld e, a
            adc hl, de
          pop af
        pop de
        dec a
        jp nz, _charedit_sprite_col_loop
        
        ld e, l
        
        ld a, $0
        ld h, a
        ld a, $8
        ld l, a
        ld a, c
_charedit_sprite_row_loop:
        push de
          push af
            ld a, $0
            ld d, a
            ld a, $8
            ld e, a
            adc hl, de
          pop af
        pop de
        dec a
        jp nz, _charedit_sprite_row_loop
        
        ld d, l
        
        push hl
          ld hl, sprite_table_start
          ld (hl), d
          inc hl
          ld (hl), e
        pop hl
      pop de
    pop hl
  pop bc
  jp main_loop

; b - col
; c - row
; returns hl
get_charedit_hl_b_c:
  ld a, b
  ld hl, tileset_pixels_start
  sub $0
  jp z, _get_charedit_hl_b_c_row_start
_get_charedit_hl_b_c_col_loop:
  inc hl
  dec a
  jp nz, _get_charedit_hl_b_c_col_loop
_get_charedit_hl_b_c_row_start:
  ld a, c
  sub $0
  jp z, _get_charedit_hl_b_c_end
_get_charedit_hl_b_c_row_loop:
  push de
    ld de, grid_width
    add hl, de
  pop de
  dec a
  jp nz, _get_charedit_hl_b_c_row_loop
_get_charedit_hl_b_c_end:
  ret

set_charedit:
  push de
    push bc
      ld a, (charedit_col)
      ld b, a
      ld a, (charedit_row)
      ld c, a
      push bc
        ld a, (view_key)
        ld b, a
        push hl
          call get_character_tileset_b_in_hl
          push hl
          pop de
        pop hl
      pop bc
      ld a, b
      sub $0
      jp z, _charedit_col_end
_charedit_col_loop:
      inc de
      dec a
      jp nz, _charedit_col_loop
_charedit_col_end:
      ld a, c
      sub $0
      jp z, _charedit_row_end
_charedit_row_loop:
      push hl
        push de
        pop hl
        ld de, tileset_width_bytes
        add hl, de
        push hl
        pop de
      pop hl
      dec a
      jp nz, _charedit_row_loop
_charedit_row_end:
      ld a, (color_value)
      sub $C0
      jp z, _char_edit_place
      add a, $C0
_char_edit_place:
      ld (de), a
      ld (charedit_save_color), a
      call charedit_put_view_pixel
    pop bc
  pop de
  ret

main_red_up:
  push bc
    ld a, (color_value)
    ld b, a
    and red_mask
    rra 
    rra 
    rra 
    rra 
    inc a
    ld c, a
    and two_bit_mask
    add a, '0'
    ld (red_location), a
    ld a, c
    rla
    rla
    rla
    rla
    and red_mask
    ld c, a
    ld a, b
    and inv_red_mask
    or c
    ld (color_value), a
    ld (color_location), a
  pop bc
  jp main_loop

main_green_up:
  push bc
    ld a, (color_value)
    ld b, a
    and green_mask
    rra 
    rra 
    inc a
    ld c, a
    and two_bit_mask
    add a, '0'
    ld (green_location), a
    ld a, c
    rla
    rla
    and green_mask
    ld c, a
    ld a, b
    and inv_green_mask
    or c
    ld (color_value), a
    ld (color_location), a
  pop bc
  jp main_loop

main_blue_up:
  push bc
    ld a, (color_value)
    ld b, a
    and blue_mask
    inc a
    ld c, a
    and two_bit_mask
    add a, '0'
    ld (blue_location), a
    ld a, c
    and blue_mask
    ld c, a
    ld a, b
    and inv_blue_mask
    or c
    ld (color_value), a
    ld (color_location), a
  pop bc
  jp main_loop

main_right:
  ld a, (view_key)
  inc a
  ld (select_char_location), a
  ld (view_key), a
  ld b, a
  call write_tile_b_to_view
  jp main_move_finish

main_left:
  ld a, (view_key)
  dec a
  ld (select_char_location), a
  ld (view_key), a
  ld b, a
  call write_tile_b_to_view
  jp main_move_finish

main_up:
  ld a, (view_key)
  sub charlist_width
  ld (select_char_location), a
  ld (view_key), a
  ld b, a
  call write_tile_b_to_view
  jp main_move_finish

main_down:
  ld a, (view_key)
  add a, charlist_width
  ld (select_char_location), a
  ld (view_key), a
  ld b, a
  call write_tile_b_to_view
  jp main_move_finish

main_move_finish:
  push bc
    ld a, (view_key)
    and $F0
    rra
    rra
    rra
    rra
    ld b, a
    ld a, charlist_row_start
    add a, b
    ld b, a
    ld a, (view_key)
    and $0F
    ld c, a
    ld a, charlist_col_start
    add a, c
    ld c, a
    push de
      ld a, $1
      ld d, a
      call set_sprite_d_to_xy_bc
    pop de
  pop bc
  jp main_loop

set_sprite_d_to_xy_bc:
  ld a, d
  push hl
  ld hl, sprite_table_start
_set_sprite_d_to_xy_bc_loop:
    sub $0
    jp z, _set_sprite_d_to_xy_bc_end
    inc hl
    inc hl
    inc hl
    inc hl
    dec a
    jp _set_sprite_d_to_xy_bc_loop
_set_sprite_d_to_xy_bc_end:
    ld a, b
    rla
    rla
    rla
    ld (hl), a
    inc hl
    ld a, c
    rla
    rla
    rla
    ld (hl), a
  pop hl
  ret

write_tile_b_to_view:
  push hl
    push de
      call get_character_tileset_b_in_hl
      push bc
        ld a, tileset_size
        push hl
        pop de
        ld hl, tileset_pixels_start
        call _write_tile_view_row_col
      pop bc
    pop de
  pop hl
  ret

_write_tile_view_row_col:
  call _write_tile_view_row
  call _write_tile_view_row
  call _write_tile_view_row
  call _write_tile_view_row
  call _write_tile_view_row
  call _write_tile_view_row
  call _write_tile_view_row
  call _write_tile_view_row
  ret

_write_tile_view_row:
  call _write_tile_view
  call _write_tile_view
  call _write_tile_view
  call _write_tile_view
  call _write_tile_view
  call _write_tile_view
  call _write_tile_view
  call _write_tile_view
  call _write_tile_view_return_column
  ret

_write_tile_view_return_column:
  push de
  ld de, grid_width
  add hl, de
  ld de, tileset_width_bytes
  sbc hl, de
  pop de
  ret

_write_tile_view:
  ld a, (de)
  ld (hl), a
  inc hl
  inc de
  ret

create_solid_pixel_colors:
  push hl
    push de
      push bc
        ld b, $C0
        call get_character_tileset_b_in_hl
_create_solid_pixel_colors_loop:
        call write_b_color_to_hl_tile
        inc b
        ld a, b
        sub $0
        jp nz, _create_solid_pixel_colors_loop

      pop bc
    pop de
  pop hl
  ret

write_b_color_to_hl_tile:
  ld a, tileset_size
_write_b_color_to_hl_tile_loop:
  ld (hl), b
  inc hl
  dec a
  jp nz, _write_b_color_to_hl_tile_loop
  ret

write_complete_tileset:
  push hl
    push bc
      push de
        ld b, charlist_row_start
        ld c, charlist_col_start
      
        call put_hl_to_row_col_bc
        ld a, 0
        call _write_tileset_row_column
      pop de
    pop bc
  pop hl
  ret

_write_tileset_row_column:
  ; 0-3
  call _write_tileset_row
  call _write_tileset_row
  call _write_tileset_row
  call _write_tileset_row

  ; 4-7
  call _write_tileset_row
  call _write_tileset_row
  call _write_tileset_row
  call _write_tileset_row

  ; 8-11
  call _write_tileset_row
  call _write_tileset_row
  call _write_tileset_row
  call _write_tileset_row

  ; 12-15
  call _write_tileset_row
  call _write_tileset_row
  call _write_tileset_row
  call _write_tileset_row

  ret

_write_tileset_row:
  ; 0-3
  call _write_tile
  call _write_tile
  call _write_tile
  call _write_tile

  ; 4-7
  call _write_tile
  call _write_tile
  call _write_tile
  call _write_tile

  ; 8-11
  call _write_tile
  call _write_tile
  call _write_tile
  call _write_tile

  ; 12-15
  call _write_tile
  call _write_tile
  call _write_tile
  call _write_tile

  call _write_tileset_return_column
  ret

_write_tileset_return_column:
  push de
  ld de, grid_width
  add hl, de
  ld de, charlist_width
  sbc hl, de
  pop de
  ret

_write_tile:
  ld (hl), a
  inc hl
  inc a
  ret

; b - row
; c - col
; returns value in hl
put_hl_to_row_col_bc:
  push de
    ld hl, display_start
    ld de, grid_width
    
put_hl_to_row_col_bc_row_start:
    ld a, b
put_hl_to_row_col_bc_row_loop:
    sub $0
    jp z, put_hl_to_row_col_bc_col_start
    sub $1
    add hl, de
    jp put_hl_to_row_col_bc_row_loop

put_hl_to_row_col_bc_col_start:
    ld a, c
put_hl_to_row_col_bc_col_loop:
    sub $0
    jp z, put_hl_to_row_col_bc_end
    sub $1
    inc hl
    jp put_hl_to_row_col_bc_col_loop
    
put_hl_to_row_col_bc_end:
  pop de
  ret

write_full_tileset_persistence:
  push hl
    push de
      push bc
        ld hl, _tileset_origin_str
        call write_pers_hl
        ld de, tileset_start ; tileset_finish
;        ld hl, tileset_start
;_write_full_tileset_persistence_loop:
        push bc
          ld c, 0
          call write_tile_pers_line_from_de
          call write_tile_pers_line_from_de
          call write_tile_pers_line_from_de
          call write_tile_pers_line_from_de
          call write_tile_pers_line_from_de
          call write_tile_pers_line_from_de
          call write_tile_pers_line_from_de
          call write_tile_pers_line_from_de
          call write_tile_pers_line_from_de
          call write_tile_pers_line_from_de
          call write_tile_pers_line_from_de
          call write_tile_pers_line_from_de
          call write_tile_pers_line_from_de
          call write_tile_pers_line_from_de
          call write_tile_pers_line_from_de
          call write_tile_pers_line_from_de
;          ld bc, tileset_size
;          adc hl, bc
        pop bc
;        or a
;        sbc hl, de
;        jp nc, _write_full_tileset_persistence_end
;        or a
;        add hl, de
;        jp _write_full_tileset_persistence_loop
_write_full_tileset_persistence_end:
;        ld b, c
;        call write_de_tile_b
;        ld a, c
;        inc a
;        ld c, a
;        sub $0
;        jp nz, _write_full_tileset_persistence_loop
        ld hl, _tileset_end_str
        call write_pers_hl
      pop bc
    pop de
  pop hl
  ret

write_tile_pers_line_from_de:
  call write_tile_pers_tile_from_de
  call write_tile_pers_tile_from_de
  call write_tile_pers_tile_from_de
  call write_tile_pers_tile_from_de
  call write_tile_pers_tile_from_de
  call write_tile_pers_tile_from_de
  call write_tile_pers_tile_from_de
  call write_tile_pers_tile_from_de
  call write_tile_pers_tile_from_de
  call write_tile_pers_tile_from_de
  call write_tile_pers_tile_from_de
  call write_tile_pers_tile_from_de
  call write_tile_pers_tile_from_de
  call write_tile_pers_tile_from_de
  call write_tile_pers_tile_from_de
  call write_tile_pers_tile_from_de
  ret

write_tile_pers_tile_from_de:
  push hl
    ld hl, percistence_addr
    ld (hl), ';'
    ld (hl), ' '
    ld a, c
    push de
      push bc
        ld b, a
        ld de, percistence_addr
        call write_de_b
      pop bc
    pop de
    ld a, c
    inc a
    ld c, a
    ld (hl), '\n'
    call write_line_helper
    call write_line_helper
    call write_line_helper
    call write_line_helper
    call write_line_helper
    call write_line_helper
    call write_line_helper
    call write_line_helper
    ld (hl), '\n'
  pop hl
  ret

write_de_tile_b:
  push hl

    push de
    pop hl
  
    push hl

      call get_character_tileset_b_in_hl
      ld c, (hl)
      push hl
      pop de

    pop hl

    call write_line_helper
    call write_line_helper
    call write_line_helper
    call write_line_helper
    call write_line_helper
    call write_line_helper
    call write_line_helper
    call write_line_helper

  pop hl
  ret

; Not call safe
; hl - file descriptor
write_line_helper:
  ld (hl), '.'
  ld (hl), 'd'
  ld (hl), 'b'
  ld (hl), ' '

  call write_byte_helper
  ld (hl), ','
  ld (hl), ' '
  call write_byte_helper
  ld (hl), ','
  ld (hl), ' '
  call write_byte_helper
  ld (hl), ','
  ld (hl), ' '
  call write_byte_helper
  ld (hl), ','
  ld (hl), ' '
  call write_byte_helper
  ld (hl), ','
  ld (hl), ' '
  call write_byte_helper
  ld (hl), ','
  ld (hl), ' '
  call write_byte_helper
  ld (hl), ','
  ld (hl), ' '
  call write_byte_helper

  ld (hl), '\n'

  ret

; not call safe
; de - location of tileset data
; hl - file descriptor
; b - pixel value
write_byte_helper:
  ld a, (de)
  ld b, a
  inc de
  
  ld (hl), '$'
  
  push de
    push hl
    pop de
    call write_de_b
  pop de
  ret

; b - character to get tileset of
; returns hl as pointer
get_character_tileset_b_in_hl:
  ld hl, tileset_start
  ld a, b
  sub $0
  jp z, get_character_tileset_b_in_hl_end
  push bc
  ld bc, tileset_size
  adc hl, bc
  pop bc
get_character_tileset_b_in_hl_loop:
  sub $1
  jp z, get_character_tileset_b_in_hl_end
  push bc
  ld bc, tileset_size
  adc hl, bc
  pop bc
  jp get_character_tileset_b_in_hl_loop
get_character_tileset_b_in_hl_end:
  ret

write_pers_hl:
  push de
  ld de, percistence_addr
  call write_de_hl
  pop de
  ret

print_hl:
  push de
  ld de, stdout_addr
  call write_de_hl
  pop de
  ret

write_pers_b:
  push de
  ld de, percistence_addr
  call write_de_b
  pop de
  ret

print_b:
  push de
  ld de, stdout_addr
  call write_de_b
  pop de
  ret

; prints b as two hex digits out to de file descriptor
; de - file descriptor
; b - value to output as digit
write_de_b:
  push hl

  ; top nibble print
  ld hl, _hex_digit_start
  ld a, b

  ; bitmask top nibble
  and a, $F0
  srl a
  srl a
  srl a
  srl a

  ; retrieves char from hex digit array and pushes it to fd
  call write_de_b_put_a_helper_de_hl

  ; bottom nibble print
  ld hl, _hex_digit_start
  ld a, b

  ; bitmask bottom nibble
  and a, $0F

  ; retrieves char from hex digit array and pushes it to fd
  call write_de_b_put_a_helper_de_hl

  pop hl
  ret

; c pseudocode for what this is doing
; char* hl = _hex_digit_start;
; *de = *(hl + a)
write_de_b_put_a_helper_de_hl:
  push bc
  ; hl + a
  ld b, 0
  ld c, a
  adc hl, bc
  ld a, (hl)
  ; *de = *(hl + a)
  ld (de), a
  pop bc
  ret

; de - file descriptor address
; hl - string address
write_de_hl:
  ld a,(hl)
  sub $0
  jp z, write_de_hl_end
  inc hl
  ld (de), a
  jp write_de_hl
write_de_hl_end:
  ret

load_tileset:
  ld hl, tileset_orig
  ld bc, tileset_end
  ; starts at ' ' in tileset list
  ld de, ts_space_start  ;$2308
load_tileset_loop:
  ld a, c
  sub l
  jp nz, load_tileset_next
  ld a, b
  sub h
  jp z, load_tileset_end
load_tileset_next:
  ld a, (hl)
  ld (de), a
  inc hl
  inc de
  jp load_tileset_loop
load_tileset_end:
  ret

print_newline:
  push hl
  push de
  ld de, grid_width
  add hl, de
  ld a, l
  and grid_mask_l
  ld l, a
  ld a, h
  and grid_mask_h
  ld h, a
  ld (grid_iter), hl
  pop de
  pop hl
  ret

print_pixel_enclosure:
  ld de, _pixel_enclosure
  ld hl, display_start
  
  ; 0-3
  call _print_pixel_enclosure_line
  call _print_pixel_enclosure_line
  call _print_pixel_enclosure_line
  call _print_pixel_enclosure_line
  
  ; 4-7
  call _print_pixel_enclosure_line
  call _print_pixel_enclosure_line
  call _print_pixel_enclosure_line
  call _print_pixel_enclosure_line
  
  ; 8-11
  call _print_pixel_enclosure_line
  call _print_pixel_enclosure_line
  call _print_pixel_enclosure_line
  call _print_pixel_enclosure_line
  
  ; 12-15
  call _print_pixel_enclosure_line
  call _print_pixel_enclosure_line
  call _print_pixel_enclosure_line
  call _print_pixel_enclosure_line

  ; 16-19
  call _print_pixel_enclosure_line
  call _print_pixel_enclosure_line
  call _print_pixel_enclosure_line
  call _print_pixel_enclosure_line

  ; 20-23
  call _print_pixel_enclosure_line
  call _print_pixel_enclosure_line
  call _print_pixel_enclosure_line
  call _print_pixel_enclosure_line

  ; 24-27
  call _print_pixel_enclosure_line
  call _print_pixel_enclosure_line
  call _print_pixel_enclosure_line
  call _print_pixel_enclosure_line

  ; 28-31
  call _print_pixel_enclosure_line
  call _print_pixel_enclosure_line
  call _print_pixel_enclosure_line
  call _print_pixel_enclosure_line 

  ret

_print_pixel_enclosure_line:
  ; 0-3
  call _print_pixel_enclosure_char
  call _print_pixel_enclosure_char
  call _print_pixel_enclosure_char
  call _print_pixel_enclosure_char
  
  ; 4-7
  call _print_pixel_enclosure_char
  call _print_pixel_enclosure_char
  call _print_pixel_enclosure_char
  call _print_pixel_enclosure_char

  ; 8-11
  call _print_pixel_enclosure_char
  call _print_pixel_enclosure_char
  call _print_pixel_enclosure_char
  call _print_pixel_enclosure_char

  ; 12-15
  call _print_pixel_enclosure_char
  call _print_pixel_enclosure_char
  call _print_pixel_enclosure_char
  call _print_pixel_enclosure_char

  ; 16-19
  call _print_pixel_enclosure_char
  call _print_pixel_enclosure_char
  call _print_pixel_enclosure_char
  call _print_pixel_enclosure_char
 
  ; 20-23 
  call _print_pixel_enclosure_char
  call _print_pixel_enclosure_char
  call _print_pixel_enclosure_char
  call _print_pixel_enclosure_char

  ; 24-27
  call _print_pixel_enclosure_char
  call _print_pixel_enclosure_char
  call _print_pixel_enclosure_char
  call _print_pixel_enclosure_char

  ; 28-31
  call _print_pixel_enclosure_char
  call _print_pixel_enclosure_char
  call _print_pixel_enclosure_char
  call _print_pixel_enclosure_char

  ret

_print_pixel_enclosure_char:
  ld a, (de)
  ld (hl), a
  inc hl
  inc de
  ret

load_tileset_finished:
.db "Load of tileset finished ",0

get_tile_address_finished:
.db "Tile address get finished",0

_pixel_enclosure:
.db $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $20, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $20, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $20, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $20, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $20, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $20, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $20, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $20, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $8F, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
.db $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, 'E', 'N', 'D'
.db 0

_tileset_origin_str:
.db "tileset_orig:\n",0

_tileset_end_str:
.db "tileset_end:\n",0

_hex_digit_start:
.db "0123456789ABCDEF"
#include tileset_defs_new_tetris.asm
