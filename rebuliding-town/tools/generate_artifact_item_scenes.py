from pathlib import Path


OUTPUT = Path("artifacts/items")

ITEMS = [
    ("phoenix_pillow", "PhoenixPillow", "embroidered_phoenix_pillow_end_256.png"),
    ("phoenix_vase", "PhoenixVase", "blue_white_phoenix_vase_item_256.png"),
    ("celadon_phoenix", "CeladonPhoenix", "celadon_inlaid_bowl.png"),
    ("phoenix_paintings", "PhoenixPaintings", "painting_sun_pine_phoenix_pair_256.png"),
    ("octagonal_brush_holder", "OctagonalBrushHolder", "octagonal_lacquer_brush_holder_256.png"),
    ("deer_lunch_box", "DeerLunchBox", "lacquer_deer_pine_crane_box_256.png"),
    ("embroidered_board", "EmbroideredBoard", "embroidered_flower_bird_board.png"),
    ("zodiac_sundial", "ZodiacSundial", "blue_white_zodiac_sundial_256.png"),
    ("round_textile", "RoundTextile", "large_gold_mythical_textile_256.png"),
    ("dragon_roundel", "DragonRoundel", "dragon_round_fan.png"),
    ("tiger_norigae", "TigerNorigae", "tiger_claw_tassel_ornament.png"),
    ("longevity_pouch", "LongevityPouch", "red_phoenix_embroidered_pouch_256.png"),
    ("guardian_tile", "GuardianTile", "gray_fanged_guardian_tile_256.png"),
    ("mother_of_pearl_brush_stand", "MotherOfPearlBrushStand", "mother_of_pearl_hexagonal_brush_stand_256.png"),
]


TEMPLATE = """[gd_scene load_steps=3 format=3]

[ext_resource type="PackedScene" path="res://artifact_item.tscn" id="1_base"]
[ext_resource type="Texture2D" path="res://assets/items_museum/{texture}" id="2_texture"]

[node name="{node_name}" instance=ExtResource("1_base")]
artifact_id = &"{artifact_id}"

[node name="Sprite2D" parent="." index="1"]
texture = ExtResource("2_texture")
"""


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for artifact_id, node_name, texture in ITEMS:
        path = OUTPUT / f"{artifact_id}.tscn"
        path.write_text(
            TEMPLATE.format(
                artifact_id=artifact_id,
                node_name=node_name,
                texture=texture,
            ),
            encoding="utf-8",
        )
    print(f"Generated {len(ITEMS)} artifact item scenes")


if __name__ == "__main__":
    main()
