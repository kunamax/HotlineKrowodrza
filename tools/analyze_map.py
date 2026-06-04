"""Quick stats for both TileMap layers in game.tscn."""
import re
from pathlib import Path

TSCN = Path(__file__).resolve().parent.parent / "scenes" / "game.tscn"


def unpack(p: int) -> tuple[int, int]:
    x = p & 0xFFFF
    y = (p >> 16) & 0xFFFF
    if x >= 32768:
        x -= 65536
    if y >= 32768:
        y -= 65536
    return x, y


def read_all_layers(text: str) -> list[dict[tuple[int, int], tuple[int, int]]]:
    layers: list[dict[tuple[int, int], tuple[int, int]]] = []
    for match in re.finditer(r"layer_0/tile_data = PackedInt32Array\((.*?)\)", text, re.S):
        arr = [int(x.strip()) for x in match.group(1).split(",")]
        cells: dict[tuple[int, int], tuple[int, int]] = {}
        for i in range(0, len(arr), 3):
            coord, info, alt = arr[i], arr[i + 1], arr[i + 2]
            cells[unpack(coord)] = (info, alt)
        layers.append(cells)
    return layers


def main() -> None:
    text = TSCN.read_text(encoding="utf-8")
    layers = read_all_layers(text)
    names = ["TileMap (floor)", "TileMap2 (walls)"]
    for name, cells in zip(names, layers):
        xs = [p[0] for p in cells]
        ys = [p[1] for p in cells]
        infos = sorted({v[0] for v in cells.values()})
        alts = sorted({v[1] for v in cells.values()})
        print(f"{name}: {len(cells)} cells")
        print(f"  bounds x={min(xs)}..{max(xs)} y={min(ys)}..{max(ys)}")
        print(f"  info values ({len(infos)}): {infos[:20]}")
        print(f"  alts: {alts}")

    if len(layers) >= 2:
        floor_only = set(layers[0]) - set(layers[1])
        wall_only = set(layers[1]) - set(layers[0])
        both = set(layers[0]) & set(layers[1])
        print(f"\nFloor without overlay: {len(floor_only)}")
        print(f"Overlay without floor: {len(wall_only)}")
        print(f"Both layers: {len(both)}")
        if floor_only:
            sample = sorted(floor_only)[:8]
            print(f"  sample floor-only: {sample}")


if __name__ == "__main__":
    main()
