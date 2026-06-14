from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "player_thrust_effect_sheet.png"
OUTPUT = ROOT / "assets" / "player_thrust_effect_frame_2.png"

FRAME_SIZE = 512
FRAME_INDEX = 1
RIGHT_ARTIFACT_START = 420
FADE_START = 384


def main() -> None:
    sheet = Image.open(SOURCE).convert("RGBA")
    frame = sheet.crop(
        (
            FRAME_INDEX * FRAME_SIZE,
            0,
            (FRAME_INDEX + 1) * FRAME_SIZE,
            FRAME_SIZE,
        )
    )
    pixels = frame.load()

    for x in range(FADE_START, FRAME_SIZE):
        if x >= RIGHT_ARTIFACT_START:
            opacity = 0.0
        else:
            opacity = 1.0 - (
                (x - FADE_START)
                / (RIGHT_ARTIFACT_START - FADE_START)
            )
        for y in range(FRAME_SIZE):
            red, green, blue, alpha = pixels[x, y]
            pixels[x, y] = (
                red,
                green,
                blue,
                round(alpha * opacity),
            )

    frame.save(OUTPUT)
    print(OUTPUT)


if __name__ == "__main__":
    main()
