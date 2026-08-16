from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path('/home/ubuntu/pocketqueue/android/app/src/main/res')
variants = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
for density, size in variants.items():
    image = Image.new('RGBA', (size, size), (248, 250, 252, 0))
    draw = ImageDraw.Draw(image)
    radius = int(size * .22)
    draw.rounded_rectangle((1, 1, size - 2, size - 2), radius=radius, fill='#2563EB')
    left = int(size * .28)
    top = int(size * .19)
    right = int(size * .72)
    bottom = int(size * .76)
    draw.rounded_rectangle((left, top, right, bottom), radius=max(2, int(size * .06)), fill='white')
    try:
        font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', max(8, int(size * .18)))
    except OSError:
        font = None
    label = '01'
    box = draw.textbbox((0, 0), label, font=font)
    draw.text(((size - (box[2] - box[0])) / 2, size * .39), label, fill='#2563EB', font=font)
    for x in (size * .37, size * .5, size * .63):
        draw.ellipse((x - size * .035, size * .82, x + size * .035, size * .89), fill='white')
    out = root / f'mipmap-{density}' / 'ic_launcher.png'
    out.parent.mkdir(parents=True, exist_ok=True)
    image.save(out)
    print(out)
