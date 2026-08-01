# Mini-CAD
A simple computer graphics program using RISC-V Assembly on RARS simulator.  
Chương trình thiết kế đồ họa máy tính đơn giản sử dụng RISC-V Assembly trên trình giả lập RARS.  
  
[English](#install)  
[Tiếng Việt](#cài-đặt)  
  
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
  - 13: light green
  - 14: light blue 
  - 15: silver
- fill x y  
  to fill in the section that `x, y` is connected to. This command works similar to the "fill" tool in Microsoft`s paint
- clear  
  to clear the entire board  
  
The dimensions of the drawing board are counted left to right, top to bottom, from 0 to 255.

# Cài Đặt
> [!IMPORTANT]
> Chương trình này mới chỉ được chạy trên giả lập RARS 1.6, và có thể không hoạt động trên các phần mềm khác.

Để cài đặt chương trình, tải trực tiếp file `Mini_CAD.asm` hoặc tải từ nhánh `main`
  
# Chạy
1. Mở file `Mini_CAD.asm` trên trình giả lập RARS.  
2. Trong phần `Tools` của thanh công cụ, mở công cụ `Keyboard and Display MMIO Simulator` và `Bitmap Display`.  
3. Cài đặt Bitmap display:
  - Unit Width in Pixels: 4
  - Unit Height in Pixels: 4
  - Display Width in Pixels: 512
  - Display Height in Pixels: 512
  - Base address for display: 0x10010000 (static data)
4. Kết nối cả hai công cụ với chương trình sử dụng nút `Connect to program`.
5. Biên dịch chương trình (F3).
6. Chạy chương trình (F5).  

Để sử dụng chương trình, bạn cần sử dụng các lệnh đặc biệt trong phần `KEYBOARD` của công cụ `Keyboard and Display MMIO Simulator`.

# Lệnh
- line x1 y1 x2 y2  
 với `x1, y1` và `x2, y2` là hai nút của đoạn thẳng.
- rectangle x1 y1 x2 y2  
 với `x1, y1` và `x2, y2` là 2 đỉnh đối diện nhau của hình chữ nhật.
- circle x y r  
 với `x, y` là tâm và `r` là bán kính hình tròn.
- color n  
  để thay đổi màu vẽ theo danh sách:
  - 0: đen
  - 1: trắng
  - 2: đỏ
  - 3: lục
  - 4: lam
  - 5: vàng
  - 6: đỏ tím
  - 7: xanh lơ
  - 8: cam
  - 9: tím
  - 10: nâu
  - 11: xám
  - 12: hồng
  - 13: lục nhạt
  - 14: lam nhạt
  - 15: bạc
- fill x y  
 để đổ màu vào phần có chứa `x, y`
- clear  
 để xóa toàn bộ bảng  
  
Các ô của bảng vẽ được đánh số thứ tự từ trên xuống dưới, từ trái sang phải, từ 0 - 255.  
