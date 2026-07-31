# Mini-CAD
A simple computer graphics program using RISC-V Assembly on RARS simulator.  
Chương trình thiết kế đồ họa máy tính đơn giản sử dụng RISC-V Assembly trên trình giả lập RARS.  
  
[English](#install).  
[Tiếng Việt](#cài_đặt).  
  
# Install
> [!IMPORTANT]
> This program has only been ran on RARS 1.6, and may or may not works properly on other platform.

To install, simply download `Mini_CAD.asm` directly or download from the `main` branch  

# Run
1. Open `Mini_CAD.asm` on your RARS interface.
2. On the `Tools` section of the toolbar, seclect and open `Keyboard and Display MMIO Simulator` and `Bitmap Display`.
3. Set Bimap Display:
  - Unit Width in Pixels: 4
  - Unit Height in Pixels: 4
  - Display Width in Pixels: 512
  - Display Height in Pixels: 512
  - Base address for display: 0x10010000 (static data)
4. Connect both tools using the `Connect to Program` button.
5. Assemble the program (F3)
6. Execute the program (F5)  
In order to use the program, you will need to types specific commands in the `KEYBOARD` section of `Keyboard and Display MMIO Simulator`

# Commands
- line x1 y1 x2 y2  
  with `x1, y1`, `x2, y2` being two ends of your line
- rectangle x1 y1 x2 y2  
  with `x1, y1`, `x2, y2` being two opposite corners of your rectangle
- circle x y r  
  with `x, y` being the center and `r` the diameter of your circle 
- color n  
  change brush color with the corespoding number:
  - 0: black
  - 1: white
  - 2: red
  - 3: green
  - 4: blue
  - 5: yellow
  - 6: magenta
  - 7: cyan
  - 8: orange
  - 9: purple
  - 10: brown
  - 11: gray
  - 12: pink
  - 13: link green
  - 14: light blue 
  - 15: silver
- fill x y  
  to fill in the section that `x, y` is connected to. This command works similar to the "fill" tool in Microsoft`s paint
- clear  
  to clear the entire board  
  
The dimensions of the drawing board are counted left to right, top to bottom, from 0 to 255.

# Cài Đặt
