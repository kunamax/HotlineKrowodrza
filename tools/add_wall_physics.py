"""Add physics and light occlusion to wall tiles in game_starting_room."""
from pathlib import Path

path = Path(__file__).resolve().parent.parent / "scenes" / "game_starting_room.tscn"
text = path.read_text(encoding="utf-8")
poly_suffix = (
    "physics_layer_0/polygon_0/points = "
    "PackedVector2Array(-127.5, -127.5, 127.5, -127.5, 127.5, 127.5, -127.5, 127.5)"
)
occlusion_suffix = (
    "occlusion_layer_0/polygon_0/points = "
    "PackedVector2Array(-127.5, -127.5, 127.5, -127.5, 127.5, 127.5, -127.5, 127.5)"
)

lines = text.splitlines()
out: list[str] = []
in_fn075 = False
physics_count = 0
occlusion_count = 0

for i, line in enumerate(lines):
    if line.startswith('[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_fn075"]'):
        in_fn075 = True
    elif in_fn075 and line.startswith('[sub_resource type="TileSet" id="TileSet_3xtta"]'):
        in_fn075 = False

    out.append(line)

    if not in_fn075 or not line.endswith("/0 = 0") or "physics_layer_" in line:
        continue

    next_line = lines[i + 1] if i + 1 < len(lines) else ""
    if "physics_layer_0" not in next_line:
        atlas_line = line.split("/0 = 0")[0]
        out.append(f"{atlas_line}/0/{poly_suffix}")
        physics_count += 1
        next_line = f"{atlas_line}/0/{poly_suffix}"

    if "occlusion_layer_0" not in next_line:
        atlas_line = line.split("/0 = 0")[0]
        out.append(f"{atlas_line}/0/{occlusion_suffix}")
        occlusion_count += 1

text2 = "\n".join(out)

tileset_header = '[sub_resource type="TileSet" id="TileSet_3xtta"]\n'
if tileset_header in text2:
    block_start = text2.index(tileset_header)
    block_end = text2.index("\n\n", block_start)
    block = text2[block_start:block_end]
    if "physics_layer_0/collision_layer" not in block:
        block = block.replace(
            "tile_size = Vector2i(255, 255)\n",
            "tile_size = Vector2i(255, 255)\n"
            "physics_layer_0/collision_layer = 1\n"
            "physics_layer_0/collision_mask = 2\n",
            1,
        )
    if "occlusion_layer_0/layers" not in block:
        block = block.replace(
            '[sub_resource type="TileSet" id="TileSet_3xtta"]\n',
            '[sub_resource type="TileSet" id="TileSet_3xtta"]\n'
            "occlusion_layer_0/layers = 1\n",
            1,
        )
    text2 = text2[:block_start] + block + text2[block_end:]

path.write_text(text2, encoding="utf-8")
print(f"added physics to {physics_count} tiles, occlusion to {occlusion_count} tiles")
