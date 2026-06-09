"""Study how TileMap2 walls relate to floor cells."""
import re
from pathlib import Path
from collections import Counter

TSCN = Path(__file__).resolve().parent.parent / "scenes" / "game.tscn"


def unpack(p: int) -> tuple[int, int]:
    x = p & 0xFFFF
    y = (p >> 16) & 0xFFFF
    if x >= 32768:
        x -= 65536
    if y >= 32768:
        y -= 65536
    return x, y


def read_layers(text: str) -> list[dict]:
    layers = []
    for match in re.finditer(r"layer_0/tile_data = PackedInt32Array\((.*?)\)", text, re.S):
        arr = [int(x.strip()) for x in match.group(1).split(",")]
        cells = {}
        for i in range(0, len(arr), 3):
            cells[unpack(arr[i])] = (arr[i + 1], arr[i + 2])
        layers.append(cells)
    return layers


def main() -> None:
    floor, walls = read_layers(TSCN.read_text(encoding="utf-8"))
    FLOOR, WALL_FLOOR = 1, 65537

    # Original-ish area (before expansion rooms)
    orig_floor = {(x, y) for (x, y), (info, _) in floor.items() if info == FLOOR and -100 <= x <= 100 and -60 <= y <= 60}

    print("Wall tiles on edges of original floor rooms:")
    edge_patterns: Counter[tuple[int, int]] = Counter()
    for (x, y) in orig_floor:
        for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            n = (x + dx, y + dy)
            if n not in orig_floor and n in walls:
                edge_patterns[walls[n]] += 1
    for (info, alt), count in edge_patterns.most_common(15):
        print(f"  info={info} alt={alt}: {count}")

    print("\nWall-only cells (collision borders) sample:")
    wall_only = set(walls) - set(floor)
    for pos in sorted(wall_only)[:20]:
        print(f"  {pos} -> {walls[pos]}")

    print("\nFloor at (-99,-54) area - wall overlay:")
    for y in range(-58, -48):
        row = ""
        for x in range(-102, -88):
            f = floor.get((x, y), (None,))[0]
            w = walls.get((x, y))
            if w:
                row += "W"
            elif f == FLOOR:
                row += "."
            elif f == WALL_FLOOR:
                row += "#"
            else:
                row += " "
        print(f"{y:4d} {row}")

    # Room at -99 to -51: corner tiles
    print("\nCorner wall tile IDs at room (-99,-54):")
    corners = [(-99, -54), (-51, -54), (-99, -38), (-51, -38)]
    for c in corners:
        print(c, walls.get(c, floor.get(c)))


if __name__ == "__main__":
    main()
