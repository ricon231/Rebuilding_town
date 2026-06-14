from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter, ImageOps


SOURCE = Path(r"C:\Users\User\OneDrive\사진\문서\카카오톡 받은 파일")
OUTPUT = Path("artifacts/museum_text/crops")
OUTPUT.mkdir(parents=True, exist_ok=True)

ROTATIONS = {
    "KakaoTalk_20260602_115926323.jpg": 0,
    "KakaoTalk_20260602_115927231.jpg": 0,
    "KakaoTalk_20260602_115928090.jpg": 0,
    "KakaoTalk_20260602_115928880.jpg": 0,
    "KakaoTalk_20260602_115930339.jpg": 0,
    "KakaoTalk_20260602_115932259.jpg": 0,
    "KakaoTalk_20260602_115933116.jpg": 0,
    "KakaoTalk_20260602_115937039.jpg": 0,
    "KakaoTalk_20260602_115938950.jpg": 0,
    "KakaoTalk_20260602_115939827.jpg": 0,
    "KakaoTalk_20260602_115944232.jpg": 0,
    "KakaoTalk_20260602_115949403.jpg": 0,
    "KakaoTalk_20260602_120040575.jpg": 0,
    "KakaoTalk_20260602_120053317.jpg": 0,
}


for name, rotation in ROTATIONS.items():
    image = Image.open(SOURCE / name)
    image = ImageOps.exif_transpose(image)
    if rotation:
        image = image.rotate(-rotation, expand=True)
    image.save(OUTPUT / name.replace(".jpg", "_upright.jpg"), quality=94)
