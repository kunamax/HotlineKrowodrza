"""Append rooms to game.tscn TileMap using Godot format=2 triplets (coord, info, alt)."""
import re
from pathlib import Path

TSCN = Path(__file__).resolve().parent.parent / "scenes" / "game.tscn"

FLOOR = 1
WALL = 65537
DOOR = 131073


def pack(x: int, y: int) -> int:
    return ((y & 0xFFFF) << 16) | (x & 0xFFFF)


def unpack(p: int) -> tuple[int, int]:
    x = p & 0xFFFF
    y = (p >> 16) & 0xFFFF
    if x >= 32768:
        x -= 65536
    if y >= 32768:
        y -= 65536
    return x, y


def read_cells(text: str) -> dict[tuple[int, int], tuple[int, int]]:
    match = re.search(r"layer_0/tile_data = PackedInt32Array\((.*?)\)", text, re.S)
    if not match:
        raise RuntimeError("tile_data not found")
    arr = [int(x.strip()) for x in match.group(1).split(",")]
    if len(arr) % 3 != 0:
        raise RuntimeError(f"tile_data length {len(arr)} is not divisible by 3")

    cells: dict[tuple[int, int], tuple[int, int]] = {}
    for i in range(0, len(arr), 3):
        coord, info, alt = arr[i], arr[i + 1], arr[i + 2]
        cells[unpack(coord)] = (info, alt)
    return cells


def write_cells(text: str, cells: dict[tuple[int, int], tuple[int, int]]) -> str:
    triplets: list[int] = []
    for (x, y), (info, alt) in sorted(cells.items(), key=lambda item: (item[0][1], item[0][0])):
        triplets.extend([pack(x, y), info, alt])

    payload = ", ".join(str(v) for v in triplets)
    return re.sub(
        r"layer_0/tile_data = PackedInt32Array\(.*?\)",
        f"layer_0/tile_data = PackedInt32Array({payload})",
        text,
        count=1,
        flags=re.S,
    )


def fill_room(
    cells: dict[tuple[int, int], tuple[int, int]],
    x0: int,
    y0: int,
    width: int,
    height: int,
    alt: int = 0,
) -> None:
    for x in range(x0, x0 + width):
        for y in range(y0, y0 + height):
            on_edge = x == x0 or x == x0 + width - 1 or y == y0 or y == y0 + height - 1
            cells[(x, y)] = (WALL if on_edge else FLOOR, alt)


def carve(cells: dict[tuple[int, int], tuple[int, int]], x: int, y: int) -> None:
    if (x, y) in cells:
        info, alt = cells[(x, y)]
        cells[(x, y)] = (FLOOR if info == WALL else info, alt)


def corridor(
    cells: dict[tuple[int, int], tuple[int, int]],
    x0: int,
    y0: int,
    length: int,
    horizontal: bool,
) -> None:
    for i in range(length):
        x = x0 + (i if horizontal else 0)
        y = y0 + (0 if horizontal else i)
        cells[(x, y)] = (FLOOR, 0)
        if horizontal:
            cells[(x, y - 1)] = (WALL, 0)
            cells[(x, y + 1)] = (WALL, 0)
        else:
            cells[(x - 1, y)] = (WALL, 0)
            cells[(x + 1, y)] = (WALL, 0)


def main() -> None:
    text = TSCN.read_text(encoding="utf-8")
    cells = read_cells(text)
    original_count = len(cells)

    # South room below the existing south corridor (y=49).
    fill_room(cells, -19, 58, 17, 13)
    carve(cells, -11, 58)
    corridor(cells, -11, 50, 9, horizontal=False)

    # East room beyond x=96.
    fill_room(cells, 105, 2, 15, 17)
    carve(cells, 105, 10)
    corridor(cells, 97, 10, 9, horizontal=True)

    # West room beyond x=-99.
    fill_room(cells, -131, 2, 15, 17)
    carve(cells, -115, 2)
    corridor(cells, -98, 10, 9, horizontal=True)

    # Small north-east annex connected to y=26 corridor.
    fill_room(cells, 45, -22, 13, 11)
    carve(cells, 45, -11)
    corridor(cells, 45, -14, 4, horizontal=False)

    TSCN.write_text(write_cells(text, cells), encoding="utf-8")
    print(f"Added {len(cells) - original_count} tiles ({original_count} -> {len(cells)})")


if __name__ == "__main__":
    main()
