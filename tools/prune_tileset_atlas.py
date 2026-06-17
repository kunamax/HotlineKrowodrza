#!/usr/bin/env python3
"""Prune bloated TileSetAtlasSource blocks to tiles actually used on TileMapLayers."""

from __future__ import annotations

import base64
import re
import struct
import sys
from pathlib import Path

TILE_SIZE = 255
MAX_ATLAS_INDEX = 10  # 2805 / 255 = 11 tiles -> indices 0..10


def decode_tile_map_coords(b64: str) -> dict[int, set[tuple[int, int]]]:
    raw = base64.b64decode(b64)
    by_source: dict[int, set[tuple[int, int]]] = {}
    i = 2
    while i + 12 <= len(raw):
        _x, _y, source, ax, ay, _alt = struct.unpack_from("<hhHHHH", raw, i)
        by_source.setdefault(source, set()).add((ax, ay))
        i += 12
    return by_source


def parse_atlas_sources(text: str) -> dict[str, tuple[int, int, list[str]]]:
    """Return id -> (start_line, end_line_exclusive, lines)."""
    lines = text.splitlines(keepends=True)
    sources: dict[str, tuple[int, int, list[str]]] = {}
    i = 0
    while i < len(lines):
        match = re.match(
            r'^\[sub_resource type="TileSetAtlasSource" id="([^"]+)"\]\n$', lines[i]
        )
        if match:
            source_id = match.group(1)
            start = i
            i += 1
            while i < len(lines) and not lines[i].startswith("[sub_resource"):
                i += 1
            sources[source_id] = (start, i, lines[start:i])
        else:
            i += 1
    return sources, lines


def parse_tileset_source_map(text: str) -> dict[str, dict[int, str]]:
    """TileSet id -> {source_index: atlas_source_id}."""
    tilesets: dict[str, dict[int, str]] = {}
    for match in re.finditer(
        r'\[sub_resource type="TileSet" id="([^"]+)"\](.*?)(?=\n\[sub_resource|\n\[node|\Z)',
        text,
        re.S,
    ):
        tileset_id = match.group(1)
        body = match.group(2)
        mapping: dict[int, str] = {}
        for src_match in re.finditer(
            r"sources/(\d+) = SubResource\(\"([^\"]+)\"\)", body
        ):
            mapping[int(src_match.group(1))] = src_match.group(2)
        tilesets[tileset_id] = mapping
    return tilesets


def parse_layer_usage(text: str, tilesets: dict[str, dict[int, str]]) -> dict[str, set[tuple[int, int]]]:
    """Atlas source id -> set of used atlas coords."""
    usage: dict[str, set[tuple[int, int]]] = {}
    for match in re.finditer(
        r'tile_map_data = PackedByteArray\("([^"]+)"\)\ntile_set = SubResource\("([^"]+)"\)',
        text,
    ):
        b64 = match.group(1)
        tileset_id = match.group(2)
        if tileset_id not in tilesets:
            continue
        source_map = tilesets[tileset_id]
        for source_idx, coords in decode_tile_map_coords(b64).items():
            atlas_id = source_map.get(source_idx)
            if atlas_id is None:
                continue
            usage.setdefault(atlas_id, set()).update(coords)
    return usage


def split_tile_entries(atlas_lines: list[str]) -> tuple[list[str], dict[tuple[int, int], list[str]]]:
    header: list[str] = []
    tiles: dict[tuple[int, int], list[str]] = {}
    i = 0
    while i < len(atlas_lines):
        line = atlas_lines[i]
        if i == 0:
            i += 1
            continue
        coord_match = re.match(r"^(\d+):(\d+)/0 = ", line)
        if coord_match:
            key = (int(coord_match.group(1)), int(coord_match.group(2)))
            entry = [line]
            i += 1
            while i < len(atlas_lines):
                if re.match(r"^\d+:\d+/0 = ", atlas_lines[i]):
                    break
                entry.append(atlas_lines[i])
                i += 1
            tiles[key] = entry
        else:
            header.append(line)
            i += 1
    return header, tiles


def rebuild_atlas_block(
    source_id: str,
    header: list[str],
    tiles: dict[tuple[int, int], list[str]],
    keep: set[tuple[int, int]],
) -> list[str]:
    out = [f'[sub_resource type="TileSetAtlasSource" id="{source_id}"]\n']
    out.extend(header)
    for key in sorted(keep):
        if key in tiles:
            out.extend(tiles[key])
        else:
            ax, ay = key
            out.append(f"{ax}:{ay}/0 = 0\n")
    return out


def prune_scene(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    sources, lines = parse_atlas_sources(text)
    tilesets = parse_tileset_source_map(text)
    usage = parse_layer_usage(text, tilesets)

    if not sources:
        print(f"{path}: no TileSetAtlasSource blocks found")
        return

    replacements: list[tuple[int, int, list[str]]] = []
    for source_id, (start, end, atlas_lines) in sources.items():
        header, tiles = split_tile_entries(atlas_lines)
        keep = usage.get(source_id, set())
        if not keep:
            # Fallback: keep only in-bounds tiles that already exist.
            keep = {k for k in tiles if k[0] <= MAX_ATLAS_INDEX and k[1] <= MAX_ATLAS_INDEX}
        else:
            keep = {k for k in keep if k[0] <= MAX_ATLAS_INDEX and k[1] <= MAX_ATLAS_INDEX}

        new_block = rebuild_atlas_block(source_id, header, tiles, keep)
        replacements.append((start, end, new_block))
        print(
            f"{path.name}: {source_id} {end - start} lines -> {len(new_block)} lines "
            f"({len(keep)} tiles)"
        )

    replacements.sort(key=lambda item: item[0], reverse=True)
    for start, end, new_block in replacements:
        lines[start:end] = new_block

    path.write_text("".join(lines), encoding="utf-8")


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    targets = sys.argv[1:] or [
        str(root / "scenes/game_starting_room.tscn"),
        str(root / "scenes/game.tscn"),
    ]
    for target in targets:
        prune_scene(Path(target))


if __name__ == "__main__":
    main()
