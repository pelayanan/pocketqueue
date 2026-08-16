from pathlib import Path
from PIL import Image

mapping = {
    'welcome.png': '/home/ubuntu/screenshots/8080-iwxbzf7fq5v2s9d_2026-08-16_12-00-19_8806.webp',
    'setup.png': '/home/ubuntu/screenshots/8080-iwxbzf7fq5v2s9d_2026-08-16_12-00-29_7841.webp',
    'queue.png': '/home/ubuntu/screenshots/8080-iwxbzf7fq5v2s9d_2026-08-16_12-00-49_8276.webp',
    'queue_add.png': '/home/ubuntu/screenshots/8080-iwxbzf7fq5v2s9d_2026-08-16_12-00-49_8276.webp',
    'queue_serving.png': '/home/ubuntu/screenshots/8080-iwxbzf7fq5v2s9d_2026-08-16_12-01-08_9444.webp',
    'display.png': '/home/ubuntu/screenshots/8080-iwxbzf7fq5v2s9d_2026-08-16_11-54-17_5351.webp',
    'history.png': '/home/ubuntu/screenshots/8080-iwxbzf7fq5v2s9d_2026-08-16_11-54-27_5875.webp',
    'queue_detail.png': '/home/ubuntu/screenshots/8080-iwxbzf7fq5v2s9d_2026-08-16_11-55-16_1104.webp',
    'statistics.png': '/home/ubuntu/screenshots/8080-iwxbzf7fq5v2s9d_2026-08-16_11-54-55_2273.webp',
    'settings.png': '/home/ubuntu/screenshots/8080-iwxbzf7fq5v2s9d_2026-08-16_11-55-06_1839.webp',
}

target = Path('/home/ubuntu/pocketqueue/docs/screenshots')
target.mkdir(parents=True, exist_ok=True)
for name, source in mapping.items():
    image = Image.open(source).convert('RGB')
    image.save(target / name, format='PNG', optimize=True)
    print(f'{name}: {image.width}x{image.height}')
