"""Generate TileMapLayer data for boss_room.tscn."""
from __future__ import annotations

import base64
import struct
from pathlib import Path

# Arena sized for player (~x5) and boss (~x17) at y~5 with game.tscn tile scale.
ROOM_WIDTH = 22
ROOM_HEIGHT = 6
FLOOR_TILE = (0, 0, 0, 0)
FLIP_H = 4096


def encode_layer(tiles: dict[tuple[int, int], tuple[int, int, int, int]]) -> str:
    raw = bytearray()
    raw += struct.pack("<H", 0)
    for (x, y) in sorted(tiles):
        s, ax, ay, alt = tiles[(x, y)]
        raw += struct.pack("<hhHHHH", x, y, s, ax, ay, alt)
    return base64.b64encode(raw).decode("ascii")


def top_wall_tile(x: int, width: int) -> tuple[int, int, int, int]:
    if x == 0:
        return (0, 0, 1, 0)
    if x == width - 1:
        return (0, 6, 1, 0)
    if x <= 4:
        return (0, 1, 1, 0)
    return (0, 4, 1, 0)


def bottom_wall_tile(x: int, width: int) -> tuple[int, int, int, int]:
    if x == 0:
        return (0, 0, 4, 0)
    if x == width - 1:
        return (0, 0, 4, FLIP_H)
    if x == width // 2:
        return (0, 3, 4, 0)
    return (0, 1, 4, 0)


def left_wall_tile(y: int, height: int) -> tuple[int, int, int, int]:
    if y < height - 2:
        return (0, 0, 2, 0)
    return (0, 0, 3, 0)


def right_wall_tile(y: int, height: int) -> tuple[int, int, int, int]:
    tile = left_wall_tile(y, height)
    return (tile[0], tile[1], tile[2], FLIP_H)


def build_floor() -> dict[tuple[int, int], tuple[int, int, int, int]]:
    tiles: dict[tuple[int, int], tuple[int, int, int, int]] = {}
    for y in range(ROOM_HEIGHT):
        for x in range(ROOM_WIDTH):
            tiles[(x, y)] = FLOOR_TILE
    return tiles


def build_walls() -> dict[tuple[int, int], tuple[int, int, int, int]]:
    tiles: dict[tuple[int, int], tuple[int, int, int, int]] = {}
    width = ROOM_WIDTH
    height = ROOM_HEIGHT

    for x in range(width):
        tiles[(x, -1)] = top_wall_tile(x, width)
        tiles[(x, height)] = bottom_wall_tile(x, width)

    for y in range(height):
        tiles[(0, y)] = left_wall_tile(y, height)
        tiles[(width - 1, y)] = right_wall_tile(y, height)

    return tiles


def main() -> None:
    floor_b64 = encode_layer(build_floor())
    wall_b64 = encode_layer(build_walls())
    print("floor cells:", ROOM_WIDTH * ROOM_HEIGHT)
    print("wall cells:", len(build_walls()))
    print("FLOOR_B64=", floor_b64[:80], "...")
    print("WALL_B64=", wall_b64[:80], "...")


if __name__ == "__main__":
    main()
