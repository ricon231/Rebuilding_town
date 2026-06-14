from pathlib import Path


TRANSCRIPT_DIR = Path("artifacts/museum_text/transcripts")

RENAMES = {
    "KakaoTalk_20260602_115926323": "봉황을 수놓은 베갯모와 자수 봉황도",
    "KakaoTalk_20260602_115927231": "자수 봉황도와 청화백자 봉황문 항아리",
    "KakaoTalk_20260602_115928090": "청자 상감 봉황문 대접과 봉기불탁속",
    "KakaoTalk_20260602_115928880": "봉황 그림 두 점",
    "KakaoTalk_20260602_115930339": "꽃과 새·동물을 새긴 팔각 필통",
    "KakaoTalk_20260602_115932259": "사슴·소나무·박쥐를 새긴 도시락통",
    "KakaoTalk_20260602_115933116": "꽃과 새·동물을 수놓은 인두판과 꽃·나비 주머니",
    "KakaoTalk_20260602_115937039": "십이지 청화백자 해시계와 닭 그림",
    "KakaoTalk_20260602_115938950": "원형 직물 장식과 용무늬 장식",
    "KakaoTalk_20260602_115939827": "용이 새겨진 자수용 판과 용보",
    "KakaoTalk_20260602_115944232": "호랑이 발톱 노리개와 까치호랑이 자수",
    "KakaoTalk_20260602_115949403": "십장생 귀주머니",
    "KakaoTalk_20260602_120040575": "짐승얼굴무늬 기와",
    "KakaoTalk_20260602_120053317": "나전필통과 대나무 필통",
}


def main() -> None:
    renamed = 0
    for old_stem, artifact_name in RENAMES.items():
        for suffix in ("", "(수정본)"):
            source = TRANSCRIPT_DIR / f"{old_stem}{suffix}.txt"
            target = TRANSCRIPT_DIR / f"{artifact_name}{suffix}.txt"
            if not source.exists():
                raise FileNotFoundError(source)
            if target.exists() and target != source:
                raise FileExistsError(target)
            source.rename(target)
            renamed += 1
    print(f"Renamed {renamed} files")


if __name__ == "__main__":
    main()
