"""Add light occlusion polygons to wall tilesets (mirrors existing physics polygons)."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

FULL_TILE_POLY = (
    "PackedVector2Array(-127.5, -127.5, 127.5, -127.5, 127.5, 127.5, -127.5, 127.5)"
)


def _add_occlusion_layer_to_tileset(text: str, tileset_id: str) -> str:
    needle = f'[sub_resource type="TileSet" id="{tileset_id}"]\n'
    if needle not in text:
        return text
    if "occlusion_layer_0/layers" in text.split(needle, 1)[1].split("\n\n", 1)[0]:
        return text
    return text.replace(
        needle,
        needle + "occlusion_layer_0/layers = 1\n",
        1,
    )


def _mirror_physics_to_occlusion(lines: list[str], in_section: bool) -> tuple[list[str], int]:
    out: list[str] = []
    count = 0
    for i, line in enumerate(lines):
        out.append(line)
        if not in_section:
            continue
        if "/physics_layer_0/polygon_0/points = " not in line:
            continue
        next_line = lines[i + 1] if i + 1 < len(lines) else ""
        if "occlusion_layer_0" in next_line:
            continue
        occluder = line.replace(
            "/physics_layer_0/polygon_0/points = ",
            "/occlusion_layer_0/polygon_0/points = ",
        )
        out.append(occluder)
        count += 1
    return out, count


def patch_starting_room() -> None:
    path = ROOT / "scenes" / "game_starting_room.tscn"
    lines = path.read_text(encoding="utf-8").splitlines()
    out: list[str] = []
    in_fn075 = False
    count = 0

    for i, line in enumerate(lines):
        if line.startswith('[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_fn075"]'):
            in_fn075 = True
        elif in_fn075 and line.startswith('[sub_resource type="TileSet" id="TileSet_3xtta"]'):
            in_fn075 = False

        out.append(line)

        if not in_fn075:
            continue
        if "/physics_layer_0/polygon_0/points = " not in line:
            continue
        next_line = lines[i + 1] if i + 1 < len(lines) else ""
        if "occlusion_layer_0" in next_line:
            continue
        occluder = line.replace(
            "/physics_layer_0/polygon_0/points = ",
            "/occlusion_layer_0/polygon_0/points = ",
        )
        out.append(occluder)
        count += 1

    text = "\n".join(out)
    text = _add_occlusion_layer_to_tileset(text, "TileSet_3xtta")
    path.write_text(text, encoding="utf-8")
    print(f"game_starting_room: added {count} occlusion polygons")


def patch_game() -> None:
    path = ROOT / "scenes" / "game.tscn"
    lines = path.read_text(encoding="utf-8").splitlines()
    out: list[str] = []
    in_vtaks = False
    count = 0

    for i, line in enumerate(lines):
        if line.startswith('[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_vtaks"]'):
            in_vtaks = True
        elif in_vtaks and line.startswith("[sub_resource type="):
            in_vtaks = False

        out.append(line)

        if not in_vtaks:
            continue
        if "/physics_layer_0/polygon_0/points = " not in line:
            continue
        next_line = lines[i + 1] if i + 1 < len(lines) else ""
        if "occlusion_layer_0" in next_line:
            continue
        occluder = line.replace(
            "/physics_layer_0/polygon_0/points = ",
            "/occlusion_layer_0/polygon_0/points = ",
        )
        out.append(occluder)
        count += 1

    text = "\n".join(out)
    text = _add_occlusion_layer_to_tileset(text, "TileSet_kvpfn")
    path.write_text(text, encoding="utf-8")
    print(f"game.tscn: added {count} occlusion polygons")


if __name__ == "__main__":
    patch_starting_room()
    patch_game()
