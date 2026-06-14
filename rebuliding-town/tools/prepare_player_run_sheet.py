from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "unused_images" / "player_run_source_6frames.png"
OUTPUT = ROOT / "assets" / "player_run_6frames.png"

FRAME_COUNT = 6
FRAME_SIZE = (357, 408)
FOOT_Y = 399
MAX_SUBJECT_WIDTH = 315
MAX_SUBJECT_HEIGHT = 390
BODY_ANCHOR = (204, 189)


def remove_green_background(frame: Image.Image) -> Image.Image:
    rgba = frame.convert("RGBA")
    pixels = rgba.load()

    for y in range(rgba.height):
        for x in range(rgba.width):
            red, green, blue, _ = pixels[x, y]
            dominance = green - max(red, blue)

            if green > 135 and dominance >= 80:
                alpha = 0
            elif green > 100 and dominance >= 35:
                alpha = round(255 * (80 - dominance) / 45)
                alpha = max(0, min(alpha, 255))
            else:
                alpha = 255

            if alpha < 255:
                green = min(green, max(red, blue))
            elif dominance > 12 and green > 55:
                green = min(green, max(red, blue) + 4)
            pixels[x, y] = (red, green, blue, alpha)

    return rgba


def normalize_frame(frame: Image.Image) -> Image.Image:
    frame = remove_green_background(frame)
    alpha = frame.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return Image.new("RGBA", FRAME_SIZE, (0, 0, 0, 0))

    subject = frame.crop(bbox)
    scale = min(
        MAX_SUBJECT_WIDTH / subject.width,
        MAX_SUBJECT_HEIGHT / subject.height,
    )
    size = (
        max(1, round(subject.width * scale)),
        max(1, round(subject.height * scale)),
    )
    subject = subject.resize(size, Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", FRAME_SIZE, (0, 0, 0, 0))
    paste_x = (FRAME_SIZE[0] - subject.width) // 2
    paste_y = FOOT_Y - subject.height
    canvas.alpha_composite(subject, (paste_x, paste_y))
    cover_eyes_with_hat_shadow(canvas, paste_x, paste_y, subject.width, subject.height)
    return align_body_center(canvas)


def align_body_center(frame: Image.Image) -> Image.Image:
    belt_pixels: list[tuple[int, int]] = []
    for y in range(165, 211):
        for x in range(frame.width):
            red, green, blue, alpha = frame.getpixel((x, y))
            if (
                alpha > 180
                and blue > 45
                and blue > red * 1.15
                and blue > green * 1.05
            ):
                belt_pixels.append((x, y))

    if not belt_pixels:
        return frame

    anchor_x = round(
        sum(point[0] for point in belt_pixels) / len(belt_pixels)
    )
    anchor_y = round(
        sum(point[1] for point in belt_pixels) / len(belt_pixels)
    )
    offset = (
        BODY_ANCHOR[0] - anchor_x,
        BODY_ANCHOR[1] - anchor_y,
    )
    aligned = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    aligned.alpha_composite(frame, offset)
    return aligned


def cover_eyes_with_hat_shadow(
    frame: Image.Image,
    subject_x: int,
    subject_y: int,
    subject_width: int,
    subject_height: int,
) -> None:
    left = subject_x + round(subject_width * 0.61)
    right = subject_x + round(subject_width * 0.84)
    top = subject_y + round(subject_height * 0.14)
    bottom = subject_y + round(subject_height * 0.215)
    height = max(bottom - top, 1)

    shadow_layer = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_layer, "RGBA")
    for offset in range(height):
        progress = offset / height
        alpha = round(82 * (1.0 - progress * 0.8))
        inset = round(progress * subject_width * 0.018)
        shadow_draw.line(
            (left + inset, top + offset, right - inset, top + offset),
            fill=(48, 38, 31, alpha),
            width=1,
        )
    frame.alpha_composite(shadow_layer)


def main() -> None:
    source = Image.open(SOURCE).convert("RGB")
    sheet = Image.new(
        "RGBA",
        (FRAME_SIZE[0] * FRAME_COUNT, FRAME_SIZE[1]),
        (0, 0, 0, 0),
    )

    for output_index, source_index in enumerate(reversed(range(FRAME_COUNT))):
        left = round(source.width * source_index / FRAME_COUNT)
        right = round(source.width * (source_index + 1) / FRAME_COUNT)
        frame = source.crop((left, 0, right, source.height))
        normalized = normalize_frame(frame)
        sheet.alpha_composite(
            normalized,
            (output_index * FRAME_SIZE[0], 0),
        )

    sheet.save(OUTPUT)
    print(OUTPUT)


if __name__ == "__main__":
    main()
