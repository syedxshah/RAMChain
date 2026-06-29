import PIL
from PIL import Image, ImageDraw
import sys

def draw_chip(draw, cx, cy, size):
    # Chip body (rounded rect)
    body_size = size * 0.5
    bx1 = cx - body_size/2
    by1 = cy - body_size/2
    bx2 = cx + body_size/2
    by2 = cy + body_size/2
    draw.rounded_rectangle((bx1, by1, bx2, by2), radius=size*0.08, outline=(255, 255, 255, 255), width=int(size*0.08))
    
    # Inner square
    inner_size = size * 0.15
    ix1 = cx - inner_size/2
    iy1 = cy - inner_size/2
    ix2 = cx + inner_size/2
    iy2 = cy + inner_size/2
    draw.rectangle((ix1, iy1, ix2, iy2), fill=(255, 255, 255, 255), outline=(255, 255, 255, 255))
    
    # Pins
    pin_len = size * 0.15
    pin_thick = size * 0.08
    gap = size * 0.15
    
    for i in [-1, 1]:
        # Top and bottom pins
        px = cx + i * gap
        draw.line((px, by1, px, by1 - pin_len), fill=(255, 255, 255, 255), width=int(pin_thick))
        draw.line((px, by2, px, by2 + pin_len), fill=(255, 255, 255, 255), width=int(pin_thick))
        
        # Left and right pins
        py = cy + i * gap
        draw.line((bx1, py, bx1 - pin_len, py), fill=(255, 255, 255, 255), width=int(pin_thick))
        draw.line((bx2, py, bx2 + pin_len, py), fill=(255, 255, 255, 255), width=int(pin_thick))

def generate_ico(path):
    img = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Background (dark purple/blue)
    draw.rectangle((0, 0, 256, 256), fill=(13, 13, 26, 255))
    
    # Circle outline
    draw.ellipse((30, 30, 226, 226), outline=(255, 255, 255, 120), width=6)
    
    # Glow behind chip (simulated by a couple of semi-transparent circles)
    draw.ellipse((80, 80, 176, 176), fill=(123, 97, 255, 90))
    
    # Reflection pill at top left
    # Arc and lines
    draw.rounded_rectangle((50, 40, 120, 70), radius=15, fill=(255, 255, 255, 90))
    
    # Draw the CPU chip in the center
    draw_chip(draw, 128, 128, 120)
    
    # Save as ICO (requires multiple sizes for best OS support)
    sizes = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)]
    img.save(path, format="ICO", sizes=sizes)

if __name__ == "__main__":
    generate_ico(sys.argv[1])
