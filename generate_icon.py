from PIL import Image, ImageDraw, ImageFont
import math

SIZE = 1024
cx, cy = SIZE // 2, SIZE // 2

img = Image.new('RGB', (SIZE, SIZE))
draw = ImageDraw.Draw(img)

# 1. White background
draw.rectangle([(0, 0), (SIZE, SIZE)], fill=(255, 255, 255))

# 2. Sun rays — 16 triangular spikes radiating outward
sun_yellow = (255, 210, 0)
ray_body_r = 295   # where rays originate (just outside sun body)
ray_tip_r  = 490   # how far rays extend
num_rays = 16
half_gap = math.pi / num_rays * 0.52  # angular half-width of each ray

# Draw rays on a separate RGBA layer so we can composite with slight transparency
ray_layer = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
rdraw = ImageDraw.Draw(ray_layer)

for i in range(num_rays):
    angle = i * (2 * math.pi / num_rays) - math.pi / 2
    tip_x = cx + ray_tip_r * math.cos(angle)
    tip_y = cy + ray_tip_r * math.sin(angle)
    bl_x = cx + ray_body_r * math.cos(angle - half_gap)
    bl_y = cy + ray_body_r * math.sin(angle - half_gap)
    br_x = cx + ray_body_r * math.cos(angle + half_gap)
    br_y = cy + ray_body_r * math.sin(angle + half_gap)
    rdraw.polygon([(tip_x, tip_y), (bl_x, bl_y), (br_x, br_y)], fill=sun_yellow + (220,))

img = Image.alpha_composite(img.convert('RGBA'), ray_layer).convert('RGB')
draw = ImageDraw.Draw(img)

# 3. Sun body
sun_r = 290
glow_color = (255, 190, 0)
for offset in range(18, 0, -1):
    alpha = int(80 * (1 - offset / 18))
    r = sun_r + offset * 2
    draw.ellipse([(cx - r, cy - r), (cx + r, cy + r)],
                 fill=None, outline=glow_color, width=4)
draw.ellipse([(cx - sun_r, cy - sun_r), (cx + sun_r, cy + sun_r)],
             fill=sun_yellow)

# 4. "I AM" + "Enough" stacked, centered within the sun
font_top = ImageFont.truetype('/System/Library/Fonts/Supplemental/Georgia Bold.ttf', 265)
font_bot = ImageFont.truetype('/System/Library/Fonts/Supplemental/Zapfino.ttf', 148)
ink = (59, 38, 17)  # #3B2611

# Use anchor='mm' (horizontal + vertical center of text) for reliable placement
# "I AM" centered slightly above sun center; "Enough" below
draw.text((cx, cy - 80), "I AM", font=font_top, fill=ink, anchor='mm')

# Zapfino has no bold — simulate by drawing twice with 1px offset
for dx, dy in [(-2,0),(2,0),(0,-2),(0,2),(-1,-1),(1,-1),(-1,1),(1,1),(0,0)]:
    draw.text((cx + dx, cy + 190 + dy), "Enough", font=font_bot, fill=ink, anchor='mm')

# 5. Warm vignette at edges — each edge composited independently so corners accumulate
shadow = (191, 158, 96)  # #BF9E60
edge = 130
base = img.convert('RGBA')
for axis, forward in [('h', True), ('h', False), ('v', True), ('v', False)]:
    layer = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    ldraw = ImageDraw.Draw(layer)
    for i in range(edge):
        a = int(55 * (1 - i / edge))
        if axis == 'h':
            y = i if forward else SIZE - 1 - i
            ldraw.line([(0, y), (SIZE, y)], fill=shadow + (a,))
        else:
            x = i if forward else SIZE - 1 - i
            ldraw.line([(x, 0), (x, SIZE)], fill=shadow + (a,))
    base = Image.alpha_composite(base, layer)
img = base.convert('RGB')

out = '/Users/chrisli323/Desktop/I AM Enough/AppIcon-1024.png'
img.save(out, 'PNG')
print(f"Saved → {out}")
