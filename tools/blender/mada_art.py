"""Làng Vọng's own models, built in Blender (release council 2026-11-03 B7, owner's yes 11-04): Sen, a lost child, Sen's
face and hand, the shrine and its altar, a paper lantern, reeds, a causeway stretch, and village props. One model, one
upload; every item split by material so the game colours it.

  blender -b --python tools/blender/mada_art.py -- <out_dir> [--preview]

Objects are named <Item>_<Part> (Sen_Shirt, Shrine_Roof...). Studs, Z up, front toward -Y (toward -Z in Roblox).
Origins: figures and props stand on the ground at the origin; Face is centred on the face; Hand starts at the wrist and
reaches up; the causeway stretch is 8 wide, 16 long, 1.25 deep. art_lua.py turns the uploaded result into
src/shared/Content/ArtMeshes.luau. Low-poly on purpose: no item over ~2,000 triangles.
"""
import json
import math
import random
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

UP = Vector((0, 0, 1))
V = Vector


# ---------------------------------------------------------------- shapes

def tube(bm, pts, radii, sides=8, cap=True, squash=1.0):
    """A tube along pts; squash flattens it front to back (y)."""
    rings, side = [], None
    for i, p in enumerate(pts):
        d = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        if side is None:
            side = V((1, 0, 0)) if abs(d.x) < 0.9 else V((0, 1, 0))
        side = (side - d * side.dot(d)).normalized()
        other = d.cross(side)
        ring = []
        for k in range(sides):
            t = 2 * math.pi * k / sides
            off = side * math.cos(t) * radii[i] + other * math.sin(t) * radii[i]
            off.y *= squash
            ring.append(bm.verts.new(p + off))
        rings.append(ring)
    for r0, r1 in zip(rings, rings[1:]):
        for k in range(sides):
            bm.faces.new((r0[k], r0[(k + 1) % sides], r1[(k + 1) % sides], r1[k]))
    if cap:
        bm.faces.new(list(reversed(rings[0])))
        bm.faces.new(rings[-1])


def ball(bm, c, r, scale=(1, 1, 1), subdiv=2):
    res = bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=1.0)
    for v in res["verts"]:
        v.co = V((c.x + v.co.x * r * scale[0], c.y + v.co.y * r * scale[1], c.z + v.co.z * r * scale[2]))


def block(bm, lo, hi):
    res = bmesh.ops.create_cube(bm, size=1.0)
    c, s = (lo + hi) / 2, hi - lo
    for v in res["verts"]:
        v.co = V((c.x + v.co.x * s.x, c.y + v.co.y * s.y, c.z + v.co.z * s.z))


def rot_block(bm, center, size, rz=0.0, rx=0.0):
    res = bmesh.ops.create_cube(bm, size=1.0)
    m = Matrix.Translation(center) @ Matrix.Rotation(rz, 4, "Z") @ Matrix.Rotation(rx, 4, "X")
    for v in res["verts"]:
        v.co = m @ V((v.co.x * size.x, v.co.y * size.y, v.co.z * size.z))


def strand(bm, top, bottom, w, rng, thick=0.05, bend=V((0, 0, 0))):
    """A flat lock of wet hair hanging from top to bottom (a thin, slightly wavy ribbon with thickness)."""
    pts = [top.lerp(bottom, t) + bend * math.sin(t * math.pi) + V((rng.uniform(-0.02, 0.02), 0, 0)) for t in (0, 0.25, 0.5, 0.75, 1)]
    widths = [w, w * 1.05, w * 0.95, w * 0.8, w * 0.45]
    tube(bm, pts, widths, sides=4, squash=thick / max(w, 1e-3))


# ---------------------------------------------------------------- figures

SHIRT, PANTS, SKIN, HAIR = (86, 96, 100), (40, 44, 50), (150, 150, 146), (12, 12, 14)


def girl(rng, h=3.4, hair_front=True):
    """A small girl in a loose áo bà ba and dark trousers, long wet hair; feet at the origin, height h."""
    s = h / 3.4
    shirt, pants, skin, hair = bmesh.new(), bmesh.new(), bmesh.new(), bmesh.new()
    for sx in (-1, 1):  # legs, ankles, feet
        tube(pants, [V((sx * 0.17 * s, 0, 0.25 * s)), V((sx * 0.16 * s, 0, 0.9 * s)), V((sx * 0.15 * s, 0, 1.45 * s))], [0.15 * s, 0.17 * s, 0.19 * s], sides=7)
        block(skin, V((sx * 0.17 * s - 0.09 * s, -0.2 * s, 0)), V((sx * 0.17 * s + 0.09 * s, 0.08 * s, 0.12 * s)))
        tube(skin, [V((sx * 0.17 * s, 0, 0.1 * s)), V((sx * 0.17 * s, 0, 0.27 * s))], [0.08 * s, 0.09 * s], sides=6)
    # the shirt: hip-length, loose, a little flared at the hem
    tube(shirt, [V((0, 0, 1.15 * s)), V((0, 0, 1.5 * s)), V((0, 0, 2.05 * s)), V((0, 0, 2.42 * s)), V((0, 0, 2.55 * s))],
         [0.44 * s, 0.4 * s, 0.36 * s, 0.34 * s, 0.16 * s], sides=10, squash=0.68)
    for sx in (-1, 1):  # loose sleeves, hands hanging out of them
        tube(shirt, [V((sx * 0.33 * s, 0, 2.38 * s)), V((sx * 0.43 * s, 0, 1.95 * s)), V((sx * 0.47 * s, -0.02 * s, 1.5 * s))],
             [0.13 * s, 0.14 * s, 0.15 * s], sides=7)
        ball(skin, V((sx * 0.48 * s, -0.03 * s, 1.36 * s)), 0.09 * s, (0.8, 0.6, 1.3), subdiv=1)
    tube(skin, [V((0, 0, 2.5 * s)), V((0, 0, 2.66 * s))], [0.09 * s, 0.09 * s], sides=6)
    ball(skin, V((0, 0, 2.92 * s)), 0.27 * s, (0.92, 0.95, 1.08))
    # the hair: a cap, then long wet locks all round; in front they hang straight over the face
    ball(hair, V((0, 0.02 * s, 2.98 * s)), 0.3 * s, (1.0, 1.0, 0.9))
    for k in range(14):
        a = 2 * math.pi * k / 14
        front = math.sin(a) < -0.35  # facing -y
        if front and not hair_front:
            continue
        r = 0.29 * s
        top = V((math.cos(a) * r * 0.9, math.sin(a) * r * 0.9, 3.05 * s))
        length = (1.05 if front else 1.35) * s + rng.uniform(-0.12, 0.12) * s
        out = V((math.cos(a), math.sin(a), 0)) * (0.06 if front else 0.12) * s
        bottom = V((math.cos(a) * r * 1.1, math.sin(a) * r * (1.25 if front else 1.15), 3.05 * s - length)) + out
        strand(hair, top, bottom, 0.12 * s, rng, thick=0.05 * s, bend=out * 0.5)
    return {"Shirt": (shirt, SHIRT), "Pants": (pants, PANTS), "Skin": (skin, SKIN), "Hair": (hair, HAIR)}


def sen(rng):
    return girl(rng)


def child(rng):
    """One of the lost children, a short-haired kid in shirt and shorts (the game colours them as dark silhouettes)."""
    s = 1.0
    body, skin, hair = bmesh.new(), bmesh.new(), bmesh.new()
    for sx in (-1, 1):
        tube(skin, [V((sx * 0.16, 0, 0.05)), V((sx * 0.16, 0, 0.75))], [0.1, 0.12], sides=6)
        tube(body, [V((sx * 0.16, 0, 0.7)), V((sx * 0.17, 0, 1.2))], [0.16, 0.18], sides=7)  # shorts
        tube(body, [V((sx * 0.32, 0, 2.05)), V((sx * 0.42, 0.02, 1.7))], [0.12, 0.11], sides=6)  # short sleeves
        tube(skin, [V((sx * 0.42, 0.02, 1.72)), V((sx * 0.46, 0, 1.25))], [0.08, 0.07], sides=6)
        block(skin, V((sx * 0.16 - 0.08, -0.16, 0)), V((sx * 0.16 + 0.08, 0.06, 0.1)))
    tube(body, [V((0, 0, 1.1)), V((0, 0, 1.6)), V((0, 0, 2.05)), V((0, 0, 2.15))], [0.36, 0.33, 0.33, 0.14], sides=9, squash=0.7)
    ball(skin, V((0, 0, 2.48)), 0.27, (0.95, 0.95, 1.05))
    ball(hair, V((0, 0.03, 2.58)), 0.28, (1.0, 1.0, 0.75))
    for k in range(5):  # a fringe
        x = -0.16 + k * 0.08
        rot_block(hair, V((x, -0.24, 2.62)), V((0.09, 0.05, 0.16)), rx=0.2)
    return {"Body": (body, (60, 70, 80)), "Skin": (skin, SKIN), "Hair": (hair, HAIR)}


def face(rng):
    """Sen's face for the glimpse under the water: a pale child's face, dark sunken eyes, no mouth, wet hair; centred on
    the face (origin), looking -y. HairL/HairR are the two curtains the game drifts apart."""
    skin, eyes, hair, left, right = bmesh.new(), bmesh.new(), bmesh.new(), bmesh.new(), bmesh.new()
    ball(skin, V((0, 0, 0)), 0.5, (0.88, 0.92, 1.12), subdiv=3)
    ball(skin, V((0, -0.47, -0.02)), 0.05, (0.8, 0.8, 1.2), subdiv=1)  # the nose, barely there
    for sx in (-1, 1):
        ball(eyes, V((sx * 0.17, -0.41, 0.08)), 0.085, (1.25, 0.55, 0.75), subdiv=2)
    ball(hair, V((0, 0.06, 0.18)), 0.54, (0.95, 0.98, 0.9))
    for k in range(8):  # the back
        a = math.pi * (0.1 + 0.8 * k / 7)
        top = V((math.cos(a) * 0.46, math.sin(a) * 0.45, 0.35))
        strand(hair, top, top + V((0, 0.12, -2.3 + rng.uniform(-0.2, 0.2))), 0.18, rng, thick=0.06)
    for sx, bm in ((-1, left), (1, right)):
        for k in range(3):
            x = sx * (0.06 + k * 0.12)
            top = V((x, -0.5, 0.45))
            strand(bm, top, V((x * 1.15, -0.6, -1.7 + rng.uniform(-0.15, 0.15))), 0.13, rng, thick=0.05, bend=V((0, -0.05, 0)))
    return {"Skin": (skin, (196, 204, 202)), "Eyes": (eyes, (8, 10, 12)), "Hair": (hair, HAIR), "HairL": (left, HAIR), "HairR": (right, HAIR)}


def hand(rng):
    """Her hand, small and wet, reaching up out of a sleeve: wrist at the origin, fingers up (+z)."""
    skin, sleeve = bmesh.new(), bmesh.new()
    tube(sleeve, [V((0, 0, -0.75)), V((0, 0, -0.05))], [0.17, 0.15], sides=8)
    tube(skin, [V((0, 0, -0.1)), V((0, 0, 0.12)), V((0, 0, 0.36))], [0.09, 0.13, 0.14], sides=8, squash=0.45)
    for i, (x, l) in enumerate(((-0.1, 0.24), (-0.035, 0.29), (0.035, 0.28), (0.1, 0.22))):
        tube(skin, [V((x, 0, 0.36)), V((x * 1.1, -0.02, 0.36 + l * 0.55)), V((x * 1.15, -0.05, 0.36 + l))], [0.035, 0.032, 0.026], sides=5)
    tube(skin, [V((0.13, 0, 0.12)), V((0.2, -0.04, 0.24)), V((0.22, -0.07, 0.34))], [0.04, 0.035, 0.028], sides=5)
    return {"Skin": (skin, SKIN), "Sleeve": (sleeve, SHIRT)}


# ---------------------------------------------------------------- the shrine

def shrine(rng):
    """The lakeside shrine (đình): a stone platform with steps toward the lane (+y), four lacquered posts on stone
    plinths with carved brackets, a two-tier tiled roof with upturned corners and a ridge. Matches the graybox: 34 x 26
    platform (top at z 1), posts at (±9, ±7) up to z 12, roof at z 12.5 over 24 x 20."""
    stone, wood, tile, trim = bmesh.new(), bmesh.new(), bmesh.new(), bmesh.new()
    block(stone, V((-17, -13, -1)), V((17, 13, 0.8)))
    block(stone, V((-16.4, -12.4, 0.8)), V((16.4, 12.4, 1.0)))  # the top course, slightly in
    for k in range(3):  # steps down toward the lane
        block(stone, V((-4.5, 13 + k * 1.0, -1)), V((4.5, 14 + k * 1.0, 0.8 - (k + 1) * 0.6)))
    for sx in (-1, 1):
        for sy in (-1, 1):
            x, y = sx * 9, sy * 7
            block(stone, V((x - 0.9, y - 0.9, 1)), V((x + 0.9, y + 0.9, 1.6)))
            tube(wood, [V((x, y, 1.6)), V((x, y, 11.2))], [0.55, 0.5], sides=10)
            for d in ((1, 0), (0, 1)):  # brackets under the beams
                rot_block(wood, V((x - sx * d[0] * 0.9, y - sy * d[1] * 0.9, 10.6)), V((1.8 if d[0] else 0.4, 0.4 if d[0] else 1.8, 0.5)))
    for sy in (-1, 1):  # beams and a red frieze
        block(wood, V((-9.6, sy * 7 - 0.4, 11.0)), V((9.6, sy * 7 + 0.4, 11.9)))
        block(trim, V((-9.6, sy * 7 - 0.45, 10.4)), V((9.6, sy * 7 + 0.45, 11.0)))
    for sx in (-1, 1):
        block(wood, V((sx * 9 - 0.4, -7.6, 11.0)), V((sx * 9 + 0.4, 7.6, 11.9)))
        block(trim, V((sx * 9 - 0.45, -7.6, 10.4)), V((sx * 9 + 0.45, 7.6, 11.0)))

    def roof(z0, z1, w0, d0, w1, d1, lift):
        """A hipped roof skin from a wide eave (w0 x d0 at z0) to a narrow top (w1 x d1 at z1); corners lift up."""
        n = 4
        lo, hi = [], []
        for i in range(n * 4):
            t = i / (n * 4)
            side, f = int(t * 4), (t * 4) % 1
            corners = [(-1, -1), (1, -1), (1, 1), (-1, 1), (-1, -1)]
            a, b = corners[side], corners[side + 1]
            cx, cy = a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f
            corner = 1 - min(f, 1 - f) * 2  # 1 at a corner, 0 mid-side
            lo.append(tile.verts.new(V((cx * w0 / 2, cy * d0 / 2, z0 + lift * corner ** 3))))
            hi.append(tile.verts.new(V((cx * w1 / 2, cy * d1 / 2, z1))))
        m = len(lo)
        for i in range(m):
            tile.faces.new((lo[i], lo[(i + 1) % m], hi[(i + 1) % m], hi[i]))
        # the underside of the eave, so it isn't paper-thin from below
        under = [tile.verts.new(V((v.co.x * 0.92, v.co.y * 0.92, v.co.z - 0.35))) for v in lo]
        for i in range(m):
            tile.faces.new((under[(i + 1) % m], under[i], lo[i], lo[(i + 1) % m]))
        return hi

    roof(12.0, 14.6, 26, 21, 15, 10, 1.6)
    top = roof(14.6, 17.0, 15, 10, 8, 1.2, 0.0)
    tile.faces.new(top)
    tube(tile, [V((-5.4, 0, 17.2)), V((-4, 0, 17.0)), V((4, 0, 17.0)), V((5.4, 0, 17.2))], [0.45, 0.4, 0.4, 0.45], sides=6)  # ridge
    for sx in (-1, 1):  # upturned ridge ends (dragon-tail curls, plain)
        tube(trim, [V((sx * 5.3, 0, 17.2)), V((sx * 5.9, 0, 17.8)), V((sx * 5.7, 0, 18.4))], [0.3, 0.24, 0.12], sides=6)
    return {"Stone": (stone, (138, 134, 124)), "Wood": (wood, (96, 34, 28)), "Tile": (tile, (64, 72, 66)), "Trim": (trim, (150, 44, 34))}


def altar(rng):
    """The shrine's altar (bàn thờ), matching the graybox (8 x 3 x 3.5 high): carved apron, an incense bowl with sticks,
    two candle stands, a fruit plate, a tall backboard behind for the photographs."""
    wood, brass, ash, fruit = bmesh.new(), bmesh.new(), bmesh.new(), bmesh.new()
    for sx in (-1, 1):
        for sy in (-1, 1):
            block(wood, V((sx * 3.7 - 0.25, sy * 1.25 - 0.25, 0)), V((sx * 3.7 + 0.25, sy * 1.25 + 0.25, 3.2)))
    block(wood, V((-4.1, -1.6, 3.2)), V((4.1, 1.6, 3.5)))
    block(wood, V((-3.8, -1.55, 2.4)), V((3.8, -1.4, 3.2)))  # the apron
    for k in range(7):
        rot_block(wood, V((-3.0 + k, -1.6, 2.8)), V((0.5, 0.1, 0.5)), rx=0.0, rz=math.pi / 4)  # carved diamonds
    block(wood, V((-3.6, 1.2, 3.5)), V((3.6, 1.5, 7.2)))  # backboard
    block(wood, V((-3.9, 1.1, 7.2)), V((3.9, 1.6, 7.6)))
    tube(brass, [V((0, -0.4, 3.5)), V((0, -0.4, 3.75)), V((0, -0.4, 4.1))], [0.45, 0.6, 0.62], sides=12)  # incense bowl
    tube(ash, [V((0, -0.4, 4.0)), V((0, -0.4, 4.05))], [0.55, 0.55], sides=12)
    for k in range(5):
        x = (k - 2) * 0.12
        tube(ash, [V((x, -0.4, 4.0)), V((x * 1.6, -0.4 - abs(x) * 0.3, 5.1))], [0.025, 0.02], sides=4)
    for sx in (-1, 1):  # candle stands
        tube(brass, [V((sx * 2.4, -0.3, 3.5)), V((sx * 2.4, -0.3, 3.6)), V((sx * 2.4, -0.3, 4.6)), V((sx * 2.4, -0.3, 4.7))], [0.3, 0.1, 0.08, 0.22], sides=8)
        tube(ash, [V((sx * 2.4, -0.3, 4.7)), V((sx * 2.4, -0.3, 5.2))], [0.08, 0.08], sides=6)
    tube(brass, [V((1.3, -0.6, 3.5)), V((1.3, -0.6, 3.6))], [0.5, 0.55], sides=12)  # fruit plate
    for k in range(5):
        a = 2 * math.pi * k / 5
        ball(fruit, V((1.3 + math.cos(a) * 0.22, -0.6 + math.sin(a) * 0.22, 3.75 + (0.2 if k == 0 else 0))), 0.16, subdiv=1)
    return {"Wood": (wood, (88, 30, 26)), "Brass": (brass, (176, 140, 70)), "Ash": (ash, (210, 200, 180)), "Fruit": (fruit, (230, 140, 50))}


def lantern(rng):
    """A paper lantern (đèn lồng): a ribbed oval of paper, dark top and bottom rings, a hanging loop and a red tassel;
    centred on the paper's middle (origin), 1.1 wide, 1.4 tall."""
    paper, frame, tassel = bmesh.new(), bmesh.new(), bmesh.new()
    pts = [V((0, 0, -0.62 + 1.24 * t)) for t in (0, 0.1, 0.3, 0.5, 0.7, 0.9, 1)]
    radii = [0.24 + 0.32 * math.sin(math.pi * t) for t in (0, 0.1, 0.3, 0.5, 0.7, 0.9, 1)]
    tube(paper, pts, radii, sides=12)
    for z in (-0.35, 0.0, 0.35):  # ribs
        r = 0.24 + 0.32 * math.sin(math.pi * (z + 0.62) / 1.24)
        tube(frame, [V((0, 0, z - 0.015)), V((0, 0, z + 0.015))], [r + 0.015, r + 0.015], sides=12)
    tube(frame, [V((0, 0, 0.6)), V((0, 0, 0.74))], [0.27, 0.25], sides=10)
    tube(frame, [V((0, 0, -0.74)), V((0, 0, -0.6))], [0.25, 0.27], sides=10)
    tube(frame, [V((0, 0, 0.74)), V((0, 0, 0.9))], [0.04, 0.04], sides=5)
    tube(tassel, [V((0, 0, -0.74)), V((0, 0, -0.85)), V((0, 0, -1.15))], [0.03, 0.06, 0.09], sides=6)
    return {"Paper": (paper, (214, 120, 70)), "Frame": (frame, (40, 30, 24)), "Tassel": (tassel, (170, 36, 30))}


# ---------------------------------------------------------------- the marsh and the village

def reeds(rng):
    """A clump of reeds and bulrushes about 5 tall, for the shallows (base at the origin, under the water line)."""
    stem, head = bmesh.new(), bmesh.new()
    for _ in range(13):
        a, r = rng.uniform(0, 2 * math.pi), rng.uniform(0, 1.1)
        base = V((math.cos(a) * r, math.sin(a) * r, 0))
        h = rng.uniform(3.2, 5.6)
        lean = V((rng.uniform(-0.5, 0.5), rng.uniform(-0.5, 0.5), 0))
        pts = [base, base + lean * 0.2 + UP * h * 0.5, base + lean + UP * h]
        if rng.random() < 0.45:  # a bulrush: a stem with a brown head
            tube(stem, pts, [0.06, 0.05, 0.03], sides=4)
            top = pts[-1]
            tube(head, [top - UP * 0.75, top - UP * 0.1], [0.11, 0.1], sides=6)
        else:  # a blade
            tube(stem, pts, [0.09, 0.07, 0.01], sides=3, squash=0.25)
    return {"Stem": (stem, (88, 112, 64)), "Head": (head, (92, 62, 40))}


def causeway(rng):
    """16 studs of the causeway: an earth top between rough edging stones, a few moss patches; 8 wide (x), 16 long (y),
    1.25 deep, top at z 1.25 (the graybox top is 1.2)."""
    earth, stone, moss = bmesh.new(), bmesh.new(), bmesh.new()
    block(earth, V((-3.6, -8, 0)), V((3.6, 8, 1.2)))
    for sx in (-1, 1):
        y = -8.0
        while y < 8:
            l = rng.uniform(1.1, 1.9)
            rot_block(stone, V((sx * 3.8, min(y + l / 2, 7.5), 0.55 + rng.uniform(-0.05, 0.1))), V((0.9, l, 1.3 + rng.uniform(0, 0.2))), rz=rng.uniform(-0.08, 0.08))
            y += l + 0.05
    for _ in range(5):
        c = V((rng.uniform(-2.8, 2.8), rng.uniform(-7, 7), 1.2))
        ball(moss, c, rng.uniform(0.6, 1.2), (1.4, 1.0, 0.08), subdiv=1)
    return {"Earth": (earth, (112, 94, 70)), "Stone": (stone, (118, 116, 106)), "Moss": (moss, (70, 92, 54))}


def fish_rack(rng):
    """A rack of fish drying (giàn phơi cá): two A-frames of poles, three bamboo rails, fish hung in rows; 6 long."""
    pole, fish = bmesh.new(), bmesh.new()
    for x in (-3, 3):
        for sy in (-1, 1):
            tube(pole, [V((x, sy * 0.9, 0)), V((x, 0, 3.2))], [0.08, 0.07], sides=5)
    for z, y in ((3.1, 0), (2.2, -0.45), (2.2, 0.45)):
        tube(pole, [V((-3.3, y, z)), V((3.3, y, z))], [0.06, 0.06], sides=5)
    for y, z in ((-0.45, 2.2), (0.45, 2.2)):
        for k in range(9):
            x = -2.6 + k * 0.65
            tube(fish, [V((x, y, z - 0.05)), V((x, y, z - 0.35)), V((x, y, z - 0.75)), V((x, y, z - 0.95))], [0.02, 0.11, 0.08, 0.02], sides=5, squash=0.35)
            rot_block(fish, V((x, y, z - 1.0)), V((0.18, 0.03, 0.1)))  # the tail
    return {"Pole": (pole, (132, 110, 70)), "Fish": (fish, (168, 150, 120))}


def boat(rng):
    """A small sampan (thuyền): a wooden hull with a raised bow and stern, plank seats, a bamboo canopy in the middle;
    10 long (y), sitting at the water line (origin)."""
    hull, wood, canopy = bmesh.new(), bmesh.new(), bmesh.new()
    n = 9
    sections = []
    for i in range(n):
        t = i / (n - 1)
        y = -5 + 10 * t
        w = 1.4 * math.sin(math.pi * (0.08 + 0.84 * t)) + 0.05
        rise = 0.9 * (abs(t - 0.5) * 2) ** 3
        sections.append((y, w, rise))
    rings = []
    for y, w, rise in sections:
        ring = [hull.verts.new(V((-w, y, 0.9 + rise))), hull.verts.new(V((-w * 0.8, y, -0.2 + rise * 0.6))),
                hull.verts.new(V((0, y, -0.5 + rise * 0.5))), hull.verts.new(V((w * 0.8, y, -0.2 + rise * 0.6))), hull.verts.new(V((w, y, 0.9 + rise)))]
        rings.append(ring)
    for r0, r1 in zip(rings, rings[1:]):
        for k in range(4):
            hull.faces.new((r0[k], r0[k + 1], r1[k + 1], r1[k]))
    for y in (-2.5, 0.0, 2.5):
        w = 1.4 * math.sin(math.pi * (0.08 + 0.84 * (y + 5) / 10)) - 0.1
        block(wood, V((-w, y - 0.3, 0.45)), V((w, y + 0.3, 0.6)))
    pts = []
    for k in range(9):
        a = math.pi * k / 8
        pts.append(V((-math.cos(a) * 1.25, 0, 0.6 + math.sin(a) * 1.5)))
    for y0 in (-1.6, 1.6):
        tube(canopy, [p + V((0, y0, 0)) for p in pts], [0.05] * len(pts), sides=4)
    shell = []
    for p in pts:
        shell.append((canopy.verts.new(p + V((0, -1.7, 0))), canopy.verts.new(p + V((0, 1.7, 0)))))
    for (a0, b0), (a1, b1) in zip(shell, shell[1:]):
        canopy.faces.new((a0, a1, b1, b0))
    return {"Hull": (hull, (84, 62, 44)), "Wood": (wood, (120, 92, 60)), "Canopy": (canopy, (146, 122, 78))}


def fence(rng):
    """A bamboo fence, 8 long (x): posts, two rails, a row of slanted split-bamboo slats."""
    bamboo = bmesh.new()
    for x in (-4, 0, 4):
        tube(bamboo, [V((x, 0, 0)), V((x, 0, 3.2))], [0.12, 0.1], sides=6)
    for z in (1.0, 2.4):
        tube(bamboo, [V((-4.1, 0, z)), V((4.1, 0, z))], [0.07, 0.07], sides=5)
    for k in range(17):
        x = -3.8 + k * 0.475
        lean = rng.uniform(-0.06, 0.06)
        tube(bamboo, [V((x, 0.08, 0.1)), V((x + lean, 0.08, 2.7 + rng.uniform(-0.15, 0.15)))], [0.05, 0.045], sides=4)
    return {"Bamboo": (bamboo, (150, 132, 84))}


def well(rng):
    """The village well (giếng): a ring of stone, a wooden frame with a crossbar and a rope with a bucket; ~2.6 wide."""
    stone, wood, rope = bmesh.new(), bmesh.new(), bmesh.new()
    n = 14
    for i in range(n):  # stones round the rim
        a = 2 * math.pi * i / n
        rot_block(stone, V((math.cos(a) * 1.15, math.sin(a) * 1.15, 0.5)), V((0.55, 0.45, 1.0)), rz=a)
        rot_block(stone, V((math.cos(a + 0.2) * 1.15, math.sin(a + 0.2) * 1.15, 1.15)), V((0.55, 0.5, 0.3)), rz=a + 0.2)
    tube(stone, [V((0, 0, 0.2)), V((0, 0, 0.25))], [1.0, 1.0], sides=12)  # dark water far down (coloured by the game)
    for sx in (-1, 1):
        tube(wood, [V((sx * 1.4, 0, 0)), V((sx * 1.3, 0, 3.3))], [0.12, 0.1], sides=6)
    tube(wood, [V((-1.55, 0, 3.1)), V((1.55, 0, 3.1))], [0.1, 0.1], sides=6)
    tube(rope, [V((0.2, 0, 3.05)), V((0.2, 0, 1.6))], [0.03, 0.03], sides=4)
    tube(wood, [V((0.2, 0, 1.15)), V((0.2, 0, 1.6))], [0.22, 0.26], sides=8)
    return {"Stone": (stone, (122, 118, 108)), "Wood": (wood, (104, 80, 54)), "Rope": (rope, (176, 156, 112))}


ITEMS = {"Sen": sen, "Child": child, "Face": face, "Hand": hand, "Shrine": shrine, "Altar": altar, "Lantern": lantern,
         "Reeds": reeds, "Causeway": causeway, "FishRack": fish_rack, "Boat": boat, "Fence": fence, "Well": well}


# ---------------------------------------------------------------- export

def to_object(bm, name, rgb):
    me = bpy.data.meshes.new(name)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = name.split("_")[0] in ("Sen", "Child", "Face", "Hand") and not name.endswith("Hair")
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    m = bpy.data.materials.new(name + "Mat")
    m.diffuse_color = (rgb[0] / 255, rgb[1] / 255, rgb[2] / 255, 1)
    me.materials.append(m)
    return ob


def box(ob):
    vs = [ob.matrix_world @ v.co for v in ob.data.vertices]
    lo = V((min(v.x for v in vs), min(v.y for v in vs), min(v.z for v in vs)))
    hi = V((max(v.x for v in vs), max(v.y for v in vs), max(v.z for v in vs)))
    return {"min": list(lo), "max": list(hi), "tris": sum(len(p.vertices) - 2 for p in ob.data.polygons)}


def render(path, obs):
    scene = bpy.context.scene
    lo = V((min(min(v[0] for v in [box(o)["min"]]) for o in obs), min(box(o)["min"][1] for o in obs), min(box(o)["min"][2] for o in obs)))
    hi = V((max(box(o)["max"][0] for o in obs), max(box(o)["max"][1] for o in obs), max(box(o)["max"][2] for o in obs)))
    centre, size = (lo + hi) / 2, (hi - lo).length
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    scene.collection.objects.link(cam)
    cam.location = centre + V((size * 0.45, -size * 0.75, size * 0.45))
    cam.rotation_euler = (centre - cam.location).to_track_quat("-Z", "Y").to_euler()
    cam.data.lens = 40
    scene.camera = cam
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sun.data.energy = 3.5
    sun.rotation_euler = (math.radians(50), 0, math.radians(30))
    scene.collection.objects.link(sun)
    world = bpy.data.worlds.new("W")
    world.color = (0.5, 0.52, 0.56)
    scene.world = world
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.color_type = "MATERIAL"
    scene.display.shading.light = "STUDIO"
    scene.render.resolution_x, scene.render.resolution_y = 1600, 1000
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out = Path(argv[0] if argv else "build/art")
    out.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    meta, objs, per_item = {}, [], {}
    for item, build in ITEMS.items():
        rng = random.Random(item)
        for part, (bm, rgb) in build(rng).items():
            ob = to_object(bm, f"{item}_{part}", rgb)
            meta[ob.name] = {**box(ob), "rgb": list(rgb)}
            per_item[item] = per_item.get(item, 0) + meta[ob.name]["tris"]
            objs.append(ob)
    (out / "set").mkdir(exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(out / "set" / "mada_art.glb"), export_format="GLB", export_apply=True, export_yup=True)
    (out / "set" / "meta.json").write_text(json.dumps({"source": "own", "id": "mada_art", "name": "Làng Vọng models", "author": "Raumania",
        "license": "own", "license_label": "Made for Raumania", "url": "tools/blender/mada_art.py", "credit": "Làng Vọng's own models"}))
    (out / "art.json").write_text(json.dumps(meta, indent=1))
    if "--preview" in argv:  # every item side by side, big ones scaled down so the little ones show
        spots = {}
        for i, item in enumerate(ITEMS):
            spots[item] = V(((i % 5) * 7.0, -(i // 5) * 8.0, 0))
        for ob in objs:
            item = ob.name.split("_")[0]
            k = 0.18 if item == "Shrine" else (0.4 if item in ("Causeway", "Boat") else 1.0)
            ob.data.transform(Matrix.Translation(spots[item]) @ Matrix.Scale(k, 4))
        render(out / "preview.png", objs)
    print(json.dumps(per_item))


if __name__ == "__main__":
    main()
