"""Draws the Brick Breaker logo as 32x32 pixel art and writes every branding asset from it.

Run from the project root:  python tools/branding/make_logo.py
Outputs:
  icon.svg                                  project icon (editor, web favicon), one rect per pixel run
  assets/branding/logo_128.png              logo for the main menu
  assets/branding/splash.png                boot splash (also the web loading screen)
  assets/branding/icon.ico                  Windows .exe icon (16..256 px)
  assets/branding/android_192.png           Android launcher icon
  assets/branding/android_fg_432.png        Android adaptive icon, foreground
  assets/branding/android_bg_432.png        Android adaptive icon, background
  assets/branding/android_mono_432.png      Android 13+ themed (monochrome) icon
"""
import io
import os
import struct

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "branding")
FONT = os.path.join(ROOT, "assets", "fonts", "press_start_2p.ttf")

SIZE = 32
# Same colors as the game: arena background, steel frame with teal rivets, brick colors.
BG = (18, 20, 32, 255)
FRAME = (125, 134, 166, 255)
FRAME_DARK = (70, 78, 108, 255)
RIVET = (47, 181, 181, 255)
RED = (217, 83, 95)
ORANGE = (239, 143, 62)
YELLOW = (242, 200, 75)
BALL = (255, 243, 214)
PADDLE = (195, 201, 220)
PADDLE_LIGHT = (227, 231, 242)
TITLE = (242, 200, 75, 255)
TITLE_SHADOW = (217, 83, 95, 255)


def mix(color, other, amount):
    return tuple(round(c + (o - c) * amount) for c, o in zip(color, other))


def logo() -> Image.Image:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    px = img.load()

    def inside(x, y, inset):
        lo, hi = inset, SIZE - 1 - inset
        if not (lo <= x <= hi and lo <= y <= hi):
            return False
        # Cut the corners so the square looks rounded.
        corner = 2
        dx = min(x - lo, hi - x)
        dy = min(y - lo, hi - y)
        return dx + dy >= corner

    for y in range(SIZE):
        for x in range(SIZE):
            if inside(x, y, 0):
                px[x, y] = FRAME if (x < 16 and y < 16) or x + y < 31 else FRAME_DARK
            if inside(x, y, 2):
                px[x, y] = BG
    for x in (8, 16, 23):
        px[x, 1] = RIVET
    for y in (8, 16, 23):
        px[1, y] = RIVET
        px[SIZE - 2, y] = RIVET

    # Three rows of bevelled bricks; the middle yellow one is already broken.
    rows = [(5, RED), (9, ORANGE), (13, YELLOW)]
    columns = [(4, 10), (12, 19), (21, 27)]
    for top, color in rows:
        for left, right in columns:
            if color == YELLOW and left == 12:
                continue
            for x in range(left, right + 1):
                px[x, top] = mix(color, (255, 255, 255), 0.45) + (255,)
                px[x, top + 1] = color + (255,)
                px[x, top + 2] = mix(color, (0, 0, 0), 0.35) + (255,)

    # Ball flying up into the gap, with a fading trail.
    for x, y in [(17, 18), (18, 18), (16, 19), (17, 19), (18, 19), (19, 19), (16, 20), (17, 20),
                 (18, 20), (19, 20), (17, 21), (18, 21)]:
        px[x, y] = BALL + (255,)
    px[17, 19] = (255, 255, 255, 255)
    for (x, y), alpha in [((15, 22), 150), ((14, 23), 150), ((15, 23), 110), ((12, 25), 80),
                          ((13, 24), 110)]:
        px[x, y] = mix(BG[:3], BALL, alpha / 255) + (255,)

    # Paddle with red end caps.
    for x in range(9, 23):
        cap = x <= 10 or x >= 21
        px[x, 26] = (mix(RED, (255, 255, 255), 0.4) if cap else PADDLE_LIGHT) + (255,)
        px[x, 27] = (RED if cap else PADDLE) + (255,)
    return img


def scaled(img: Image.Image, factor: int) -> Image.Image:
    return img.resize((img.width * factor, img.height * factor), Image.NEAREST)


def on_canvas(img: Image.Image, size: int, background=(0, 0, 0, 0)) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), background)
    canvas.alpha_composite(img, ((size - img.width) // 2, (size - img.height) // 2))
    return canvas


def write_svg(img: Image.Image, path: str) -> None:
    """One <rect> per horizontal run of equal pixels; crisp edges keep it pixel art at any size."""
    rects = []
    px = img.load()
    for y in range(SIZE):
        x = 0
        while x < SIZE:
            color = px[x, y]
            run = 1
            while x + run < SIZE and px[x + run, y] == color:
                run += 1
            if color[3] > 0:
                rects.append(f'<rect x="{x}" y="{y}" width="{run}" height="1" '
                              f'fill="#{color[0]:02x}{color[1]:02x}{color[2]:02x}"/>')
            x += run
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" '
           f'viewBox="0 0 {SIZE} {SIZE}" shape-rendering="crispEdges">\n'
           + "\n".join(rects) + "\n</svg>\n")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(svg)


def write_ico(img: Image.Image, path: str) -> None:
    """ICO with PNG-compressed entries (supported since Windows Vista)."""
    sizes = [16, 32, 48, 64, 128, 256]
    blobs = []
    for size in sizes:
        image = img.resize((size, size), Image.NEAREST) if size >= SIZE else img.resize(
            (size, size), Image.LANCZOS)
        buffer = io.BytesIO()
        image.save(buffer, format="PNG")
        blobs.append(buffer.getvalue())
    header = struct.pack("<HHH", 0, 1, len(sizes))
    offset = 6 + 16 * len(sizes)
    entries = b""
    for size, blob in zip(sizes, blobs):
        dim = 0 if size == 256 else size
        entries += struct.pack("<BBBBHHII", dim, dim, 0, 0, 1, 32, len(blob), offset)
        offset += len(blob)
    with open(path, "wb") as f:
        f.write(header + entries + b"".join(blobs))


def splash(img: Image.Image) -> Image.Image:
    """1280x720 like the game, so stretch mode Keep scales it exactly like the game screen."""
    canvas = Image.new("RGBA", (1280, 720), BG)
    big = scaled(img, 8)
    canvas.alpha_composite(big, ((1280 - big.width) // 2, 150))
    draw = ImageDraw.Draw(canvas)
    draw.fontmode = "1"  # no anti-aliasing: the pixel font stays crisp
    font = ImageFont.truetype(FONT, 48)
    text = "BRICK BREAKER"
    width = draw.textlength(text, font=font)
    x = (1280 - width) / 2
    draw.text((x + 4, 454), text, font=font, fill=TITLE_SHADOW)
    draw.text((x, 450), text, font=font, fill=TITLE)
    return canvas


def monochrome(img: Image.Image) -> Image.Image:
    """White silhouette of everything but the dark background, for Android themed icons."""
    mono = Image.new("RGBA", img.size, (0, 0, 0, 0))
    src, dst = img.load(), mono.load()
    for y in range(img.height):
        for x in range(img.width):
            if src[x, y][3] > 0 and src[x, y] != BG:
                dst[x, y] = (255, 255, 255, 255)
    return mono


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    img = logo()
    write_svg(img, os.path.join(ROOT, "icon.svg"))
    scaled(img, 4).save(os.path.join(OUT, "logo_128.png"))
    splash(img).save(os.path.join(OUT, "splash.png"))
    write_ico(img, os.path.join(OUT, "icon.ico"))
    scaled(img, 6).save(os.path.join(OUT, "android_192.png"))
    on_canvas(scaled(img, 6), 432).save(os.path.join(OUT, "android_fg_432.png"))
    Image.new("RGBA", (432, 432), BG).save(os.path.join(OUT, "android_bg_432.png"))
    on_canvas(scaled(monochrome(img), 6), 432).save(os.path.join(OUT, "android_mono_432.png"))
    print("branding written to", OUT)


if __name__ == "__main__":
    main()
