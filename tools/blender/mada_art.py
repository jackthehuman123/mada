"""Làng Vọng's own models, built in Blender (release council 2026-11-03 B7, owner's yes 11-04): Sen, a lost child, Sen's
face and hand, the shrine and its altar, a paper lantern, reeds, a causeway stretch, and village props. One model, one
upload; every item split by material so the game colours it.

  blender -b --python tools/blender/mada_art.py -- <out_dir> [--preview]

Objects are named <Item>_<Part> (Sen_Shirt, Shrine_Roof...). Studs, Z up, front toward -Y (toward -Z in Roblox).
Origins: figures and props stand on the ground at the origin; Face is centred on the face; Hand starts at the wrist and
reaches up; the causeway stretch is 8 wide, 16 long, 1.25 deep. art_lua.py turns the uploaded result into
src/shared/Content/ArtMeshes.luau. Low-poly on purpose: props ~300-2,000 triangles, buildings up to 5,000.
Roblox draws only the front of a face, so every surface is a closed solid (or a sheet that closes with another part of
the same item, like the shrine's Tile over its Boards); the build checks this (check_item) and prints PROBLEMS if not.
--preview renders with back faces culled like Roblox: preview.png (all items) and close-ups (CLOSEUPS).
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


def bevel_block(bm, lo, hi, off=0.08):
    """block() with chamfered edges: a 0.05-0.15 chamfer catches light, a hard box edge reads as placeholder."""
    res = bmesh.ops.create_cube(bm, size=1.0)
    c, s = (lo + hi) / 2, hi - lo
    for v in res["verts"]:
        v.co = V((c.x + v.co.x * s.x, c.y + v.co.y * s.y, c.z + v.co.z * s.z))
    edges = list({e for v in res["verts"] for e in v.link_edges})
    bmesh.ops.bevel(bm, geom=edges, offset=off, segments=1, affect="EDGES", profile=0.5)


def beam(bm, pts, w, h, tri=False, hang=True):
    """A timber along pts, w wide and h deep, kept upright; hang: its top runs along pts (else centred on them); tri: a
    three-sided rafter (flat top, an edge underneath). A closed solid."""
    rings = []
    for i, p in enumerate(pts):
        d = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        side = d.cross(UP)
        side = side.normalized() if side.length > 1e-4 else V((1, 0, 0))
        up = side.cross(d).normalized()
        top = 0.0 if hang else h / 2
        if tri:
            prof = [side * w / 2 + up * top, up * (top - h), -side * w / 2 + up * top]
        else:
            prof = [side * w / 2 + up * top, side * w / 2 + up * (top - h), -side * w / 2 + up * (top - h), -side * w / 2 + up * top]
        rings.append([bm.verts.new(p + o) for o in prof])
    k = len(rings[0])
    for r0, r1 in zip(rings, rings[1:]):
        for j in range(k):
            bm.faces.new((r0[j], r0[(j + 1) % k], r1[(j + 1) % k], r1[j]))
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])


def hexa(bm, c):
    """A closed six-sided solid from 8 corners: bottom 4 (c[0..3]) then the top 4 above them, both in the same order."""
    vs = [bm.verts.new(p) for p in c]
    for f in ((0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)):
        bm.faces.new([vs[i] for i in f])


def cone(bm, base, r, h, segs=4):
    res = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=r, radius2=0.0, depth=h)
    for v in res["verts"]:
        v.co = base + V((v.co.x, v.co.y, v.co.z + h / 2))


class Tier:
    """One tier of a hipped Vietnamese roof, a closed shell: tiles on top (and the eave edge), boards underneath.
    inner (w, d) = the half size where it starts (at z_in; a ridge when d is small), outer (W, D) = the eave (at z_out
    mid-side). The slope is concave (steep at the top, flattening to the eave) and the eave sweeps up `lift` at the
    corners. top(x, y)/under(x, y) give the surfaces, so rafters and walls can follow them exactly."""

    def __init__(self, inner, outer, z_in, z_out, lift, thick, n=8, rings=3):
        (self.w, self.d), (self.W, self.D) = inner, outer
        self.z_in, self.z_out, self.lift, self.thick, self.n, self.rings = z_in, z_out, lift, thick, n, rings

    def zr(self, r, t):
        return self.z_in - (self.z_in - self.z_out) * math.sin(r * math.pi / 2) + self.lift * abs(t) ** 4 * r * r

    def rt(self, x, y):
        rx = (abs(x) - self.w) / (self.W - self.w)
        ry = (abs(y) - self.d) / (self.D - self.d)
        r = min(max(rx, ry, 0.0), 1.0)
        t = y / (self.d + (self.D - self.d) * r) if rx >= ry else x / (self.w + (self.W - self.w) * r)
        return r, max(-1.0, min(1.0, t))

    def top(self, x, y):
        return self.zr(*self.rt(x, y))

    def under(self, x, y):
        return self.top(x, y) - self.thick

    def at(self, qx, qy, r, t, dz=0.0):
        return V((qx * (self.w + (self.W - self.w) * r), qy * (self.d + (self.D - self.d) * r), self.zr(r, t) + dz))

    def ring(self):
        """(qx, qy, t) round the square, counter-clockwise seen from above, denser toward the corners."""
        out = []
        for side in range(4):
            for k in range(self.n):
                t = math.sin(math.pi / 2 * (-1 + 2 * k / self.n))
                out.append(((t, -1.0), (1.0, t), (-t, 1.0), (-1.0, -t))[side] + (t,))
        return out

    def build(self, tile, boards, cap=False):
        q = self.ring()
        m, R = len(q), self.rings
        T = [[tile.verts.new(self.at(qx, qy, j / R, t)) for (qx, qy, t) in q] for j in range(R + 1)]
        Bt = {j: [tile.verts.new(self.at(qx, qy, j / R, t, -self.thick)) for (qx, qy, t) in q] for j in ((R,) if cap else (0, R))}
        B = [[boards.verts.new(self.at(qx, qy, j / R, t, -self.thick)) for (qx, qy, t) in q] for j in range(R + 1)]
        for i in range(m):
            k = (i + 1) % m
            for j in range(R):
                tile.faces.new((T[j][i], T[j + 1][i], T[j + 1][k], T[j][k]))  # tiles, facing up
                boards.faces.new((B[j][k], B[j + 1][k], B[j + 1][i], B[j][i]))  # boards, facing down
            tile.faces.new((T[R][i], Bt[R][i], Bt[R][k], T[R][k]))  # the eave edge, facing out
            if not cap:
                tile.faces.new((T[0][i], T[0][k], Bt[0][k], Bt[0][i]))  # the inner edge, facing in
        if cap:  # the flat strip under the ridge
            f = tile.faces.new(T[0])
            g = boards.faces.new(list(reversed(B[0])))
            bmesh.ops.triangulate(tile, faces=[f], quad_method="BEAUTY", ngon_method="BEAUTY")
            bmesh.ops.triangulate(boards, faces=[g], quad_method="BEAUTY", ngon_method="BEAUTY")


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
    """The lakeside shrine: a thủy đình-style pavilion. A stepped stone base (footing, body, an overhanging coping) with
    steps and stair cheeks toward the lane (+y) and a stone balustrade round the edge (open at the steps and mid-sides);
    four lacquered columns on lotus plinths; beams, a red frieze with knee braces and a name board; carved cantilever
    brackets (bẩy) under the eave; a two-tier roof (chồng diêm) with real thickness, boards and rafters underneath, a
    lattice band between the tiers, hip ridges ending in upturned corners (đao), a ridge with curled ends and two
    dragons facing a pearl. Matches the graybox: 34 x 26 platform (top at z 1), posts at (±9, ±7), roof over 24 x 20
    between z 12 and 17 (ornaments to ~19.5). Every surface is a closed shell (Roblox culls back faces)."""
    stone, wood, tile, boards, trim = bmesh.new(), bmesh.new(), bmesh.new(), bmesh.new(), bmesh.new()
    lower = Tier((9.2, 7.2), (13.0, 11.0), 13.5, 12.1, 1.3, 0.42, n=7)
    upper = Tier((5.0, 0.35), (10.4, 8.4), 17.4, 14.4, 1.3, 0.45, n=7)

    # -- the base: footing, body, coping (top at z 1), two steps and their cheeks toward the lane
    block(stone, V((-17.6, -13.6, -1.4)), V((17.6, 13.6, -0.25)))
    bevel_block(stone, V((-17.0, -13.0, -0.4)), V((17.0, 13.0, 0.84)), 0.1)
    bevel_block(stone, V((-17.3, -13.3, 0.8)), V((17.3, 13.3, 1.0)), 0.06)
    bevel_block(stone, V((-4.4, 12.9, -1.2)), V((4.4, 14.5, 0.67)), 0.06)
    bevel_block(stone, V((-4.4, 14.4, -1.2)), V((4.4, 15.9, 0.33)), 0.06)
    for sx in (-1, 1):  # stair cheeks sloping down from the balustrade, a block with a bud at the foot
        a, b = sx * 4.4, sx * 5.2
        hexa(stone, [V((a, 13.0, -1.2)), V((b, 13.0, -1.2)), V((b, 16.1, -1.2)), V((a, 16.1, -1.2)),
                     V((a, 13.0, 2.0)), V((b, 13.0, 2.0)), V((b, 16.1, 1.0)), V((a, 16.1, 1.0))])
        block(stone, V((sx * 4.8 - 0.55, 15.6, -1.2)), V((sx * 4.8 + 0.55, 16.7, 1.6)))
        cone(stone, V((sx * 4.8, 16.15, 1.6)), 0.5, 0.6)

    # -- the balustrade on the coping: posts with lotus-bud caps, a curb, a top rail, slim balusters
    e, ex = 12.65, 16.65
    runs = [((-ex, -e), (ex, -e), 7), ((-ex, e), (-4.4, e), 3), ((4.4, e), (ex, e), 3)]
    for sx in (-1, 1):
        runs += [((sx * ex, -e), (sx * ex, -3.0), 2), ((sx * ex, 3.0), (sx * ex, e), 2)]
    posts = {}
    for (ax, ay), (bx, by), n in runs:
        a, b = V((ax, ay, 0)), V((bx, by, 0))
        along = (b - a).normalized()
        p0, p1 = a + along * 0.2, b - along * 0.2
        for (z0, z1, w) in ((1.0, 1.3, 0.2), (2.3, 2.52, 0.16)):  # curb and rail, post to post
            block(stone, V((min(p0.x, p1.x) - w, min(p0.y, p1.y) - w, z0)), V((max(p0.x, p1.x) + w, max(p0.y, p1.y) + w, z1)))
        for k in range(n + 1):
            p = a.lerp(b, k / n)
            posts[(round(p.x, 2), round(p.y, 2))] = p
            if k < n:
                for f in (1 / 3, 2 / 3):
                    q = a.lerp(b, (k + f) / n)
                    block(stone, q + V((-0.09, -0.09, 1.3)), q + V((0.09, 0.09, 2.3)))
    for p in posts.values():
        block(stone, p + V((-0.24, -0.24, 1.0)), p + V((0.24, 0.24, 2.85)))
        cone(stone, p + V((0, 0, 2.85)), 0.3, 0.42)

    # -- columns on lotus plinths, beams, the red frieze, knee braces, the name board
    for sx in (-1, 1):
        for sy in (-1, 1):
            x, y = sx * 9, sy * 7
            tube(stone, [V((x, y, 1.0)), V((x, y, 1.3)), V((x, y, 1.62))], [0.95, 0.9, 0.6], sides=8)
            tube(wood, [V((x, y, 1.6)), V((x, y, 7.0)), V((x, y, 14.6))], [0.52, 0.5, 0.45], sides=8)
            o = V((x, y, 0))
            for d in (V((-sx, 0, 0)), V((0, -sy, 0))):  # knee braces along both beams, inward
                beam(trim, [o + d * 0.4 + V((0, 0, 8.4)), o + d * 1.0 + V((0, 0, 9.35)), o + d * 2.0 + V((0, 0, 9.85))], 0.24, 0.3, hang=False)
    for sy in (-1, 1):
        block(wood, V((-9.7, sy * 7 - 0.36, 10.6)), V((9.7, sy * 7 + 0.36, 11.4)))
        block(trim, V((-8.5, sy * 7 - 0.22, 9.85)), V((8.5, sy * 7 + 0.22, 10.6)))
    for sx in (-1, 1):
        block(wood, V((sx * 9 - 0.36, -7.7, 10.6)), V((sx * 9 + 0.36, 7.7, 11.4)))
        block(trim, V((sx * 9 - 0.22, -6.5, 9.85)), V((sx * 9 + 0.22, 6.5, 10.6)))
    block(trim, V((-2.9, 7.3, 9.6)), V((2.9, 7.56, 11.35)))  # the name board (hoành phi) on the lane side
    block(wood, V((-2.5, 7.5, 9.85)), V((2.5, 7.66, 11.1)))

    # -- cantilever brackets (bẩy) from each column out to the eave, a block (đấu) at each tip, the eave purlin
    for sx in (-1, 1):
        for sy in (-1, 1):
            o = V((sx * 9, sy * 7, 0))
            for d, reach in ((V((sx, 0, 0)), 3.3), (V((0, sy, 0)), 3.3), (V((sx, sy, 0)).normalized(), 3.6)):
                tip = o + d * reach
                zt = lower.under(tip.x, tip.y) - 0.28
                beam(wood, [o + d * 0.4 + V((0, 0, 9.9)), o + d * 1.6 + V((0, 0, 10.9)), V((tip.x, tip.y, zt))], 0.26, 0.4, hang=False)
                if d.x and d.y:
                    block(wood, V((tip.x - 0.3, tip.y - 0.3, zt - 0.12)), V((tip.x + 0.3, tip.y + 0.3, lower.under(tip.x, tip.y) + 0.05)))
    r = 0.86
    hw, hd = lower.w + (lower.W - lower.w) * r, lower.d + (lower.D - lower.d) * r
    for (qx, qy) in ((0, -1), (1, 0), (0, 1), (-1, 0)):  # the eave purlin on the bracket tips, following the sweep
        pts = []
        for k in range(4):
            t = -1 + 2 * k / 3
            x, y = (t * hw, qy * hd) if qx == 0 else (qx * hw, t * hd)
            pts.append(V((x, y, lower.under(x, y) + 0.02)))
        beam(wood, pts, 0.32, 0.34)

    # -- the two roof tiers, the lattice band between them, rafters under both
    lower.build(tile, boards)
    upper.build(tile, boards, cap=True)
    q = []  # the band (chồng diêm): a closed wall on the column line, its top tucked into the upper roof
    for side in range(4):
        for k in range(6):
            t = -1 + 2 * k / 6
            q.append(((t, -1), (1, t), (-t, 1), (-1, -t))[side])
    ob, ot, ib, it = [], [], [], []
    for (qx, qy) in q:
        for (hx, hy), bot, topl in (((9.2, 7.2), ob, ot), ((8.8, 6.8), ib, it)):
            x, y = qx * hx, qy * hy
            bot.append(boards.verts.new(V((x, y, 11.4))))
            topl.append(boards.verts.new(V((x, y, upper.under(x, y) + 0.12))))
    m = len(q)
    for i in range(m):
        k = (i + 1) % m
        boards.faces.new((ob[i], ob[k], ot[k], ot[i]))
        boards.faces.new((ib[k], ib[i], it[i], it[k]))
        boards.faces.new((ot[i], ot[k], it[k], it[i]))
        boards.faces.new((ob[k], ob[i], ib[i], ib[k]))
    for sy in (-1, 1):  # lattice studs on the band's outside
        for k in range(5):
            x = -6.8 + k * 3.4
            y0, y1 = sorted((sy * 7.15, sy * 7.32))
            block(wood, V((x - 0.09, y0, 12.4)), V((x + 0.09, y1, upper.under(x, sy * 7.3))))
    for sx in (-1, 1):
        for k in range(3):
            y = -3.6 + k * 3.6
            x0, x1 = sorted((sx * 9.15, sx * 9.32))
            block(wood, V((x0, y - 0.09, 12.4)), V((x1, y + 0.09, upper.under(sx * 9.3, y))))
    for sy in (-1, 1):  # rafters under the lower tier, straight sides
        for k in range(8):
            x = -7.875 + k * 2.25
            pts = [V((x, sy * (lower.d + (lower.D - lower.d) * rr), 0)) for rr in (0.0, 0.5, 1.0)]
            beam(wood, [p + V((0, 0, lower.under(p.x, p.y) + 0.02)) for p in pts], 0.2, 0.22, tri=True)
    for sx in (-1, 1):
        for k in range(6):
            y = -6.0 + k * 2.4
            pts = [V((sx * (lower.w + (lower.W - lower.w) * rr), y, 0)) for rr in (0.0, 0.5, 1.0)]
            beam(wood, [p + V((0, 0, lower.under(p.x, p.y) + 0.02)) for p in pts], 0.2, 0.22, tri=True)
    for sx in (-1, 1):  # corner rafters along the diagonals, heavier
        for sy in (-1, 1):
            beam(wood, [lower.at(sx, sy, rr, 1.0, -lower.thick + 0.02) for rr in (0.0, 0.5, 1.0)], 0.32, 0.34)
    for sy in (-1, 1):  # inside, under the upper tier: rafters and purlins
        for k in range(5):
            x = -4.4 + k * 2.2
            pts = [V((x, sy * y, 0)) for y in (0.35, 3.5, 6.8)]
            beam(wood, [p + V((0, 0, upper.under(p.x, p.y) + 0.02)) for p in pts], 0.18, 0.2, tri=True)
        for y in (3.8,):
            pts = [V((x, sy * y, 0)) for x in (-6.2, 0.0, 6.2)]
            beam(wood, [p + V((0, 0, upper.under(p.x, p.y) + 0.02)) for p in pts], 0.26, 0.28)
    for sx in (-1, 1):  # tie beams and king posts up to the ridge
        block(wood, V((sx * 4.6 - 0.3, -6.9, 11.4)), V((sx * 4.6 + 0.3, 6.9, 12.2)))
        tube(wood, [V((sx * 4.6, 0, 12.2)), V((sx * 4.6, 0, upper.under(sx * 4.6, 0) + 0.05))], [0.24, 0.22], sides=8)

    # -- ridges: hips ending in đao, the ridge with curled ends, two dragons facing the pearl (lưỡng long chầu nguyệt)
    for tier, rs in ((lower, (0.0, 0.55, 1.0)), (upper, (0.0, 0.4, 0.75, 1.0))):
        for sx in (-1, 1):
            for sy in (-1, 1):
                pts = [tier.at(sx, sy, rr, 1.0, 0.18) for rr in rs]
                d = V((sx * (tier.W - tier.w), sy * (tier.D - tier.d), 0)).normalized()
                end = pts[-1]
                pts += [end + d * 0.65 + UP * 0.4, end + d * 0.95 + UP * 1.0]  # the đao: a short, thick upturn
                tube(stone, pts, [0.22] * (len(rs) - 1) + [0.26, 0.24, 0.12], sides=4)
    beam(stone, [V((-5.5, 0, 17.95)), V((-4.2, 0, 17.8)), V((4.2, 0, 17.8)), V((5.5, 0, 17.95))], 0.7, 0.7)
    for sx in (-1, 1):
        tube(stone, [V((sx * 5.3, 0, 17.6)), V((sx * 6.0, 0, 18.0)), V((sx * 6.3, 0, 18.75)), V((sx * 6.05, 0, 19.35)), V((sx * 5.6, 0, 19.3))],
             [0.34, 0.3, 0.24, 0.16, 0.08], sides=4)
        pts = []
        for k in range(7):
            u = k / 6
            pts.append(V((sx * (4.5 - 3.2 * u), 0, 17.95 + 0.5 * abs(math.sin(u * 2.4 * math.pi)) + 0.35 * u)))
        tube(trim, pts, [0.08, 0.15, 0.2, 0.21, 0.21, 0.22, 0.26], sides=4)
        h = pts[-1]
        rot_block(trim, h + V((-sx * 0.22, 0, 0.12)), V((0.6, 0.34, 0.36)))
        cone(trim, h + V((sx * 0.05, 0, 0.28)), 0.12, 0.4)  # the horn
    tube(stone, [V((0, 0, 17.9)), V((0, 0, 18.35))], [0.22, 0.14], sides=6)
    ball(trim, V((0, 0, 18.8)), 0.42, subdiv=1)
    return {"Stone": (stone, (150, 146, 136)), "Wood": (wood, (92, 34, 28)), "Tile": (tile, (58, 66, 60), "up"),
            "Boards": (boards, (124, 88, 62), "down"), "Trim": (trim, (156, 46, 34))}


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
    """16 studs of the causeway: a crowned, uneven earth top between rough chamfered edging stones of varied size and
    tilt, moss patches; 8 wide (x), 16 long (y), top at z ~1.25 (the graybox top is 1.2). All closed shells."""
    earth, stone, moss = bmesh.new(), bmesh.new(), bmesh.new()
    xs, ys = [-3.6 + 7.2 * i / 6 for i in range(7)], [-8 + 16 * j / 8 for j in range(9)]
    top = [[earth.verts.new(V((x, y, 1.16 + 0.1 * (1 - (x / 3.6) ** 2) + (rng.uniform(-0.04, 0.04) if 0 < j < 8 else 0))))
            for x in xs] for j, y in enumerate(ys)]
    bot = [[earth.verts.new(V((x, y, 0.0))) for x in xs] for y in ys]
    for j in range(8):
        for i in range(6):
            earth.faces.new((top[j][i], top[j][i + 1], top[j + 1][i + 1], top[j + 1][i]))
            earth.faces.new((bot[j + 1][i], bot[j + 1][i + 1], bot[j][i + 1], bot[j][i]))
    for j in range(8):  # the long sides
        earth.faces.new((top[j][0], top[j + 1][0], bot[j + 1][0], bot[j][0]))
        earth.faces.new((top[j + 1][6], top[j][6], bot[j][6], bot[j + 1][6]))
    for i in range(6):  # the ends
        earth.faces.new((top[0][i + 1], top[0][i], bot[0][i], bot[0][i + 1]))
        earth.faces.new((top[8][i], top[8][i + 1], bot[8][i + 1], bot[8][i]))
    for sx in (-1, 1):
        y = -8.0
        while y < 7.6:
            l = min(rng.uniform(1.0, 1.9), 8.0 - y)
            h, w = 1.25 + rng.uniform(0, 0.3), rng.uniform(0.8, 1.05)
            tmp = bmesh.new()
            bevel_block(tmp, V((-w / 2, -l / 2 + 0.04, 0)), V((w / 2, l / 2 - 0.04, h)), 0.09)
            m = (Matrix.Translation(V((sx * (3.75 + rng.uniform(-0.08, 0.08)), y + l / 2, -0.05))) @ Matrix.Rotation(rng.uniform(-0.07, 0.07), 4, "Z")
                 @ Matrix.Rotation(sx * rng.uniform(0.0, 0.06), 4, "Y"))
            bmesh.ops.transform(tmp, matrix=m, verts=tmp.verts)
            me = bpy.data.meshes.new("tmp")
            tmp.to_mesh(me)
            tmp.free()
            stone.from_mesh(me)
            bpy.data.meshes.remove(me)
            y += l
    for _ in range(6):
        c = V((rng.uniform(-2.8, 2.8), rng.uniform(-7, 7), 1.24))
        ball(moss, c, rng.uniform(0.5, 1.1), (1.4, 1.0, 0.07), subdiv=1)
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
    """A small sampan (thuyền): a planked hull with thickness (outside, inside, gunwale, closed ends) rising to the bow
    and stern, rub rails, three thwarts, a woven bamboo canopy (mui) on ribs, an oar; 10 long (y), sitting at the water
    line (origin). All closed shells."""
    hull, wood, canopy = bmesh.new(), bmesh.new(), bmesh.new()
    n, th = 11, 0.12
    outs, ins, gun = [], [], []
    for i in range(n):
        t = i / (n - 1)
        y = -5 + 10 * t
        w = 1.25 * math.sin(math.pi * (0.04 + 0.92 * t)) + 0.22
        rise = 1.0 * (abs(t - 0.5) * 2) ** 3
        prof = [(-1.0, 0.95), (-0.88, 0.2), (-0.5, -0.32), (0.0, -0.48), (0.5, -0.32), (0.88, 0.2), (1.0, 0.95)]
        o, inn = [], []
        for k, (fx, fz) in enumerate(prof):
            z = fz + rise * (1.0 if k in (0, 6) else 0.6)
            o.append(hull.verts.new(V((fx * w, y, z))))
            wi = max(w - th, 0.08)
            inn.append(hull.verts.new(V((fx * wi, y, z if k in (0, 6) else z + th))))
        outs.append(o)
        ins.append(inn)
        gun.append((V((-w, y, 0.95 + rise)), V((w, y, 0.95 + rise))))
    for i in range(n - 1):
        o0, o1, i0, i1 = outs[i], outs[i + 1], ins[i], ins[i + 1]
        for k in range(6):
            hull.faces.new((o0[k], o0[k + 1], o1[k + 1], o1[k]))
            hull.faces.new((i0[k + 1], i0[k], i1[k], i1[k + 1]))
        hull.faces.new((o0[0], o1[0], i1[0], i0[0]))  # the gunwale tops
        hull.faces.new((o0[6], i0[6], i1[6], o1[6]))
    for o, inn in ((outs[0], ins[0]), (outs[-1], ins[-1])):  # bow and stern closed
        for k in range(6):
            hull.faces.new((o[k], o[k + 1], inn[k + 1], inn[k]))
    for side in (0, 1):  # rub rails along the gunwales
        tube(wood, [g[side] + V((0.06 * (1 if side else -1), 0, -0.08)) for g in gun[1:-1]], [0.08] * (n - 2), sides=4)
    for y in (-2.6, 0.0, 2.6):  # thwarts
        t = (y + 5) / 10
        w = 0.86 * (1.25 * math.sin(math.pi * (0.04 + 0.92 * t)) + 0.22 - th)  # inside the planks at seat height
        bevel_block(wood, V((-w, y - 0.3, 0.42)), V((w, y + 0.3, 0.58)), 0.04)
    ro, ri = 1.22, 1.12  # the canopy: an arched mat with thickness, closed at both ends, standing inside the gunwales
    arc_o = [V((-math.cos(math.pi * k / 8) * ro, 0, 0.88 + math.sin(math.pi * k / 8) * ro * 1.2)) for k in range(9)]
    arc_i = [V((-math.cos(math.pi * k / 8) * ri, 0, 0.88 + math.sin(math.pi * k / 8) * ri * 1.2)) for k in range(9)]
    of = [canopy.verts.new(p + V((0, -1.7, 0))) for p in arc_o]
    ob = [canopy.verts.new(p + V((0, 1.7, 0))) for p in arc_o]
    inf = [canopy.verts.new(p + V((0, -1.7, 0))) for p in arc_i]
    ib = [canopy.verts.new(p + V((0, 1.7, 0))) for p in arc_i]
    for k in range(8):
        canopy.faces.new((of[k], ob[k], ob[k + 1], of[k + 1]))
        canopy.faces.new((inf[k + 1], ib[k + 1], ib[k], inf[k]))
        canopy.faces.new((of[k + 1], inf[k + 1], inf[k], of[k]))
        canopy.faces.new((ob[k], ib[k], ib[k + 1], ob[k + 1]))
    for k in (0, 8):
        canopy.faces.new((of[k], inf[k], ib[k], ob[k]))
    for y0 in (-1.75, 0.0, 1.75):  # bamboo ribs over it
        tube(wood, [V((p.x * (ro + 0.05) / ro, y0, 0.88 + (p.z - 0.88) * (ro + 0.05) / ro)) for p in arc_o], [0.05] * 9, sides=4)
    tube(wood, [V((0.9, 3.4, 1.0)), V((0.5, 6.2, 0.2))], [0.06, 0.06], sides=5)  # the oar, resting over the stern
    rot_block(wood, V((0.45, 6.6, 0.05)), V((0.08, 1.0, 0.36)), rz=0.14, rx=0.28)
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


def ba_thu(rng):
    """Bà Thu, the old woman who keeps the shrine: a little bent, áo bà ba, dark trousers, grey hair in a bun; feet at the
    origin, about 4.7 tall."""
    shirt, pants, skin, hair, eyes = bmesh.new(), bmesh.new(), bmesh.new(), bmesh.new(), bmesh.new()
    lean = V((0, -0.18, 0))  # her back bends forward a little
    for sx in (-1, 1):
        tube(pants, [V((sx * 0.22, 0, 0.25)), V((sx * 0.22, 0, 1.2)), V((sx * 0.2, 0, 2.0))], [0.2, 0.22, 0.25], sides=8)
        block(skin, V((sx * 0.22 - 0.1, -0.26, 0)), V((sx * 0.22 + 0.1, 0.1, 0.14)))
    tube(shirt, [V((0, 0, 1.75)), V((0, -0.04, 2.3)), V((0, -0.1, 3.0)) + lean * 0.5, V((0, -0.14, 3.45)) + lean, V((0, -0.16, 3.58)) + lean],
         [0.5, 0.46, 0.44, 0.38, 0.17], sides=10, squash=0.72)
    for sx in (-1, 1):
        tube(shirt, [V((sx * 0.42, -0.14, 3.4)) + lean, V((sx * 0.5, -0.24, 2.85)), V((sx * 0.34, -0.42, 2.45))], [0.15, 0.15, 0.14], sides=7)
        ball(skin, V((sx * 0.26, -0.5, 2.38)), 0.1, (0.9, 0.8, 0.9), subdiv=1)  # hands folded in front
    neck = V((0, -0.2, 3.62)) + lean
    tube(skin, [neck, neck + V((0, -0.02, 0.18))], [0.1, 0.1], sides=6)
    head = neck + V((0, -0.06, 0.48))
    ball(skin, head, 0.32, (0.9, 0.95, 1.05))
    ball(skin, head + V((0, -0.31, -0.02)), 0.06, (0.9, 0.9, 1.1), subdiv=1)  # nose
    for sx in (-1, 1):
        ball(eyes, head + V((sx * 0.12, -0.28, 0.06)), 0.035, (1.4, 0.6, 0.7), subdiv=1)
    ball(hair, head + V((0, 0.04, 0.08)), 0.34, (1.0, 1.0, 0.92))  # grey hair, combed back
    ball(hair, head + V((0, 0.3, 0.12)), 0.17, (1.0, 0.9, 1.0))  # the bun
    return {"Shirt": (shirt, (70, 58, 54)), "Pants": (pants, (32, 32, 38)), "Skin": (skin, (196, 160, 132)), "Hair": (hair, (176, 174, 170)),
            "Eyes": (eyes, (30, 24, 20))}


def bin_(rng):
    """Bin, the group's camera guy: orange jacket, jeans, a cap, a headlamp, the camcorder held up in his right hand;
    feet at the origin, about 5 tall."""
    jacket, jeans, skin, hair, cap, gear, lamp = (bmesh.new() for _ in range(7))
    for sx in (-1, 1):
        tube(jeans, [V((sx * 0.24, 0, 0.3)), V((sx * 0.24, 0, 1.3)), V((sx * 0.23, 0, 2.3))], [0.21, 0.22, 0.26], sides=8)
        block(gear, V((sx * 0.24 - 0.13, -0.32, 0)), V((sx * 0.24 + 0.13, 0.14, 0.22)))  # shoes
    tube(jacket, [V((0, 0, 2.15)), V((0, 0, 2.6)), V((0, 0, 3.4)), V((0, 0, 3.7)), V((0, 0, 3.82))], [0.52, 0.5, 0.5, 0.44, 0.2], sides=10, squash=0.68)
    tube(jacket, [V((-0.48, 0, 3.6)), V((-0.6, 0, 3.0)), V((-0.62, -0.05, 2.45))], [0.17, 0.16, 0.15], sides=7)  # left arm down
    ball(skin, V((-0.62, -0.06, 2.3)), 0.11, (0.9, 0.8, 1.0), subdiv=1)
    tube(jacket, [V((0.48, 0, 3.6)), V((0.66, -0.3, 3.3)), V((0.6, -0.72, 3.45))], [0.17, 0.16, 0.15], sides=7)  # right arm up, filming
    ball(skin, V((0.58, -0.86, 3.47)), 0.11, (0.9, 0.9, 0.9), subdiv=1)
    block(gear, V((0.44, -1.25, 3.42)), V((0.72, -0.82, 3.72)))  # the camcorder
    tube(gear, [V((0.58, -1.25, 3.57)), V((0.58, -1.38, 3.57))], [0.09, 0.1], sides=8)
    tube(skin, [V((0, 0, 3.8)), V((0, 0, 3.98))], [0.11, 0.11], sides=6)
    head = V((0, -0.02, 4.32))
    ball(skin, head, 0.33, (0.92, 0.95, 1.05))
    ball(skin, head + V((0, -0.32, -0.03)), 0.06, (0.9, 0.9, 1.1), subdiv=1)
    for sx in (-1, 1):
        ball(gear, head + V((sx * 0.12, -0.29, 0.06)), 0.035, (1.4, 0.6, 0.7), subdiv=1)
    ball(hair, head + V((0, 0.05, 0.05)), 0.35, (1.0, 1.0, 0.85))
    ball(cap, head + V((0, 0.02, 0.17)), 0.35, (1.0, 1.0, 0.55))
    block(cap, head + V((-0.26, -0.62, 0.12)), head + V((0.26, -0.2, 0.17)))  # the peak
    tube(lamp, [head + V((0, -0.36, 0.2)), head + V((0, -0.44, 0.2))], [0.08, 0.08], sides=8)
    return {"Jacket": (jacket, (232, 128, 36)), "Jeans": (jeans, (48, 60, 86)), "Skin": (skin, (206, 168, 136)), "Hair": (hair, (20, 18, 18)),
            "Cap": (cap, (180, 40, 40)), "Gear": (gear, (28, 28, 32)), "Lamp": (lamp, (255, 250, 220))}



# ---------------------------------------------------------------- the village houses
# One shell for every house on the lane, matching the game's walls exactly (Build.luau house(): floor top at z 1, walls
# 1..11, 22 wide on x, 18 deep on y, the front toward -y with a 6-stud door gap and the lantern window at Roblox x -6.5 =
# Blender x +6.5). The graybox walls stay in the game as invisible collision; these are what you see.
W2, D2, H = 11, 9, 11


def _box6(bm, corners):
    vs = [bm.verts.new(c) for c in corners]
    for f in ((0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)):
        bm.faces.new([vs[i] for i in f])


def _walls(wall, brick):
    block(wall, V((-W2, D2 - 1, 1)), V((W2, D2, H)))  # back
    block(wall, V((-W2, -D2, 1)), V((-W2 + 1, D2, H)))  # sides
    block(wall, V((W2 - 1, -D2, 1)), V((W2, D2, H)))
    block(wall, V((-W2, -D2, 1)), V((-3, -D2 + 1, H)))  # front: the door's other side
    block(wall, V((3, -D2, 1)), V((4.8, -D2 + 1, H)))  # the window side, round its hole (x 4.8..8.2, z 4.7..7.3)
    block(wall, V((8.2, -D2, 1)), V((W2, -D2 + 1, H)))
    block(wall, V((4.8, -D2, 1)), V((8.2, -D2 + 1, 4.7)))
    block(wall, V((4.8, -D2, 7.3)), V((8.2, -D2 + 1, H)))
    block(wall, V((-3, -D2, 9)), V((3, -D2 + 1, H)))  # lintel over the door
    for x0, x1 in ((-W2, -W2 + 1), (W2 - 1, W2)):  # gables up to the ridge
        vs = [wall.verts.new(V((x, y, z))) for x in (x0, x1) for (y, z) in ((-D2, H), (D2, H), (0, H + 5.6))]
        wall.faces.new((vs[0], vs[1], vs[2]))
        wall.faces.new((vs[5], vs[4], vs[3]))
        for a, b in ((0, 1), (1, 2), (2, 0)):
            wall.faces.new((vs[a], vs[b], vs[b + 3], vs[a + 3]))
    block(brick, V((-W2 - 0.3, D2, 0)), V((W2 + 0.3, D2 + 0.3, 1.5)))  # a brick plinth round the outside
    block(brick, V((-W2 - 0.3, -D2 - 0.3, 0)), V((-W2, D2 + 0.3, 1.5)))
    block(brick, V((W2, -D2 - 0.3, 0)), V((W2 + 0.3, D2 + 0.3, 1.5)))
    block(brick, V((-W2 - 0.3, -D2 - 0.3, 0)), V((-3, -D2, 1.5)))
    block(brick, V((3, -D2 - 0.3, 0)), V((W2 + 0.3, -D2, 1.5)))


def _roof(roof, rng, ridge_z=H + 5.8, eave=1.8, thick=0.4, rows=True, gaps=0.0):
    """two slopes from the ridge to past the walls in overlapping tile rows; gaps = share of rows missing (Sen's)"""
    for sy in (-1, 1):
        y0, z0, y1, z1 = 0.0, ridge_z, sy * (D2 + eave), H - 0.6
        n = 9 if rows else 1
        for k in range(n):
            if rows and gaps and rng.random() < gaps:
                continue
            t0, t1 = k / n, (k + 1) / n
            ya, za = y0 + (y1 - y0) * t0, z0 + (z1 - z0) * t0
            yb, zb = y0 + (y1 - y0) * t1, z0 + (z1 - z0) * t1
            off = 0.12 if rows else 0.0
            c = []
            for x in (-W2 - 1.6, W2 + 1.6):
                for (y, z) in ((ya, za + off), (yb, zb), (yb, zb - thick), (ya, za + off - thick)):
                    c.append(V((x, y, z)))
            _box6(roof, c)


def _porch(wood, stone, roof):
    block(stone, V((-W2 - 0.5, -D2 - 4.8, 0)), V((W2 + 0.5, -D2, 0.5)))  # the porch floor
    for x in (-W2, -3.5, 3.5, W2):
        block(stone, V((x - 0.55, -D2 - 4.15, 0.5)), V((x + 0.55, -D2 - 3.05, 1.0)))
        tube(wood, [V((x, -D2 - 3.6, 1.0)), V((x, -D2 - 3.6, 8.9))], [0.36, 0.32], sides=8)
    block(wood, V((-W2 - 0.4, -D2 - 3.95, 8.7)), V((W2 + 0.4, -D2 - 3.25, 9.4)))  # beam
    c = []  # the porch roof, from the wall down over the beam
    for x in (-W2 - 1.0, W2 + 1.0):
        for (y, z) in ((-D2, H - 0.3), (-D2 - 5.6, 8.9), (-D2 - 5.6, 8.55), (-D2, H - 0.65)):
            c.append(V((x, y, z)))
    _box6(roof, c)
    for sx in (-1, 1):  # the door frame
        block(wood, V((sx * 3 - 0.2, -D2 - 0.15, 1)), V((sx * 3 + 0.2, -D2 + 0.15, 9.2)))
    block(wood, V((-3.2, -D2 - 0.15, 8.9)), V((3.2, -D2 + 0.15, 9.4)))
    for x in (8.8, 4.2):  # shutters beside the window (Roblox x -8.8, -4.2)
        block(wood, V((x - 0.6, -D2 - 0.35, 4.6)), V((x + 0.6, -D2 - 0.15, 7.4)))


def _ridge(trim, curl=0.9, z=H + 6.0):
    tube(trim, [V((-W2 - 1.8, 0, z + curl)), V((-W2 - 1.2, 0, z + 0.15)), V((W2 + 1.2, 0, z + 0.15)), V((W2 + 1.8, 0, z + curl))],
         [0.35, 0.42, 0.42, 0.35], sides=6)


def house_tile(rng):
    wall, brick, roof, wood, stone, trim = (bmesh.new() for _ in range(6))
    _walls(wall, brick)
    _roof(roof, rng)
    _porch(wood, stone, roof)
    _ridge(trim)
    return {"Wall": (wall, (206, 178, 118)), "Brick": (brick, (118, 74, 58)), "Roof": (roof, (150, 70, 52)), "Wood": (wood, (92, 64, 44)),
            "Stone": (stone, (128, 124, 114)), "Trim": (trim, (110, 52, 40))}


def house_thatch(rng):
    wall, brick, thatch, wood, stone = (bmesh.new() for _ in range(5))
    _walls(wall, brick)
    _roof(thatch, rng, ridge_z=H + 6.6, eave=2.4, thick=1.0, rows=False)
    for sy in (-1, 1):  # a ragged fringe along the eaves
        for k in range(30):
            x = -W2 - 2 + k * (2 * W2 + 4) / 29
            rot_block(thatch, V((x, sy * (D2 + 2.45), H - 0.95 - rng.uniform(0, 0.5))), V((0.9, 0.5, 0.8 + rng.uniform(0, 0.6))), rx=sy * 0.5)
    tube(thatch, [V((-W2 - 1.8, 0, H + 6.7)), V((W2 + 1.8, 0, H + 6.7))], [0.7, 0.7], sides=6)  # the ridge bundle
    _porch(wood, stone, thatch)
    return {"Wall": (wall, (186, 162, 120)), "Brick": (brick, (110, 80, 62)), "Thatch": (thatch, (130, 108, 70)), "Wood": (wood, (88, 66, 46)),
            "Stone": (stone, (124, 120, 110))}


def house_dinh(rng):
    """the communal house (dinh lang): heavier roof, red-lacquered columns, the ridge ends curling up like dragon tails"""
    wall, brick, roof, wood, stone, trim = (bmesh.new() for _ in range(6))
    _walls(wall, brick)
    _roof(roof, rng, ridge_z=H + 6.2, eave=2.4, thick=0.55)
    _porch(trim, stone, roof)
    tube(trim, [V((-W2 - 2.4, 0, H + 8.6)), V((-W2 - 1.6, 0, H + 6.6)), V((W2 + 1.6, 0, H + 6.6)), V((W2 + 2.4, 0, H + 8.6))],
         [0.3, 0.5, 0.5, 0.3], sides=6)
    for sx in (-1, 1):
        tube(trim, [V((sx * (W2 + 2.4), 0, H + 8.6)), V((sx * (W2 + 2.0), 0, H + 9.4)), V((sx * (W2 + 1.4), 0, H + 9.1))], [0.3, 0.2, 0.1], sides=6)
    block(wood, V((-2.2, -D2 - 0.3, H - 0.1)), V((2.2, -D2 - 0.1, H + 1.4)))  # a name board over the door
    return {"Wall": (wall, (214, 192, 140)), "Brick": (brick, (118, 74, 58)), "Roof": (roof, (120, 60, 46)), "Wood": (wood, (70, 46, 34)),
            "Stone": (stone, (130, 126, 116)), "Trim": (trim, (140, 40, 32))}


def house_sen(rng):
    """the house at the end of the lane: like the others once, now neglected (tiles missing, moss, a shutter hanging)"""
    wall, brick, roof, wood, stone, moss = (bmesh.new() for _ in range(6))
    _walls(wall, brick)
    _roof(roof, rng, gaps=0.18)
    block(stone, V((-W2 - 0.5, -D2 - 4.8, 0)), V((W2 + 0.5, -D2, 0.5)))
    for x in (-W2, 3.5, W2):  # one porch post gone
        tube(wood, [V((x, -D2 - 3.6, 0.5)), V((x + 0.15, -D2 - 3.6, 8.9))], [0.34, 0.3], sides=7)
    rot_block(wood, V((0, -D2 - 3.6, 8.6)), V((2 * W2 + 0.8, 0.6, 0.6)), rz=0.03)
    for sx in (-1, 1):
        block(wood, V((sx * 3 - 0.2, -D2 - 0.15, 1)), V((sx * 3 + 0.2, -D2 + 0.15, 9.2)))
    rot_block(wood, V((8.6, -D2 - 0.5, 5.4)), V((1.2, 0.2, 2.8)), rx=0.25, rz=0.5)  # the hanging shutter
    for _ in range(9):
        ball(moss, V((rng.uniform(-W2, W2), rng.choice((-1, 1)) * rng.uniform(2, D2), H + rng.uniform(1, 4))), rng.uniform(0.8, 1.6),
             (1.4, 1.0, 0.15), subdiv=1)
    return {"Wall": (wall, (150, 140, 120)), "Brick": (brick, (96, 70, 58)), "Roof": (roof, (96, 62, 52)), "Wood": (wood, (70, 56, 44)),
            "Stone": (stone, (110, 108, 100)), "Moss": (moss, (62, 80, 50))}


ITEMS = {"Sen": sen, "Child": child, "Face": face, "Hand": hand, "Shrine": shrine, "Altar": altar, "Lantern": lantern,
         "Reeds": reeds, "Causeway": causeway, "FishRack": fish_rack, "Boat": boat, "Fence": fence, "Well": well,
         "BaThu": ba_thu, "Bin": bin_, "HouseTile": house_tile, "HouseThatch": house_thatch, "HouseDinh": house_dinh,
         "HouseSen": house_sen}


# ---------------------------------------------------------------- export

def _islands(bm):
    bm.faces.ensure_lookup_table()
    seen, out = set(), []
    for f in bm.faces:
        if f.index in seen:
            continue
        stack, isl = [f], []
        seen.add(f.index)
        while stack:
            g = stack.pop()
            isl.append(g)
            for e in g.edges:
                for h in e.link_faces:
                    if h.index not in seen:
                        seen.add(h.index)
                        stack.append(h)
        out.append(isl)
    return out


def _volume(faces):
    vol = 0.0
    for f in faces:
        vs = [v.co for v in f.verts]
        for k in range(1, len(vs) - 1):
            vol += vs[0].dot(vs[k].cross(vs[k + 1])) / 6
    return vol


def to_object(bm, name, rgb, facing=None):
    """facing None: closed solids, normals made to point out (any island still inside-out is flipped). facing 'up' /
    'down': a part built as an open sheet that closes with another part of the same item (roof tiles over boards);
    its winding is already right and is only checked."""
    me = bpy.data.meshes.new(name)
    if facing is None:
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        for isl in _islands(bm):
            closed = all(len(e.link_faces) == 2 for f in isl for e in f.edges)
            if closed and _volume(isl) < 0:
                bmesh.ops.reverse_faces(bm, faces=isl)
    else:
        nz = sum(f.normal.z * f.calc_area() for f in bm.faces)
        if (nz > 0) != (facing == "up"):
            print(f"WARNING {name}: faces point {'up' if nz > 0 else 'down'}, expected {facing}")
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = name.split("_")[0] in ("Sen", "Child", "Face", "Hand", "BaThu", "Bin") and not name.endswith("Hair")
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    m = bpy.data.materials.new(name + "Mat")
    m.diffuse_color = (rgb[0] / 255, rgb[1] / 255, rgb[2] / 255, 1)
    me.materials.append(m)
    return ob


def check_item(item, obs):
    """Roblox draws only the front of a face: an item is see-through wherever its parts together leave an open edge, or
    where a closed shell faces inward. Returns the problems (holes, inside-out shells, slivers)."""
    bm = bmesh.new()
    for ob in obs:
        bm.from_mesh(ob.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-3)
    holes = sum(1 for e in bm.edges if len(e.link_faces) == 1)
    slivers = sum(1 for f in bm.faces if f.calc_area() < 1e-6)
    inverted = 0
    for ob in obs:
        b = bmesh.new()
        b.from_mesh(ob.data)
        for isl in _islands(b):
            if all(len(e.link_faces) == 2 for f in isl for e in f.edges) and _volume(isl) < -1e-6:
                inverted += 1
        b.free()
    bm.free()
    return {"open_edges": holes, "inside_out": inverted, "slivers": slivers}


def box(ob):
    vs = [ob.matrix_world @ v.co for v in ob.data.vertices]
    lo = V((min(v.x for v in vs), min(v.y for v in vs), min(v.z for v in vs)))
    hi = V((max(v.x for v in vs), max(v.y for v in vs), max(v.z for v in vs)))
    return {"min": list(lo), "max": list(hi), "tris": sum(len(p.vertices) - 2 for p in ob.data.polygons)}


def setup_render():
    """Workbench with back-face culling on, so the preview hides exactly what Roblox hides (a single-sided skin shows
    as a hole here too)."""
    scene = bpy.context.scene
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sun.data.energy = 3.5
    sun.rotation_euler = (math.radians(50), 0, math.radians(30))
    scene.collection.objects.link(sun)
    world = bpy.data.worlds.new("W")
    world.color = (0.5, 0.52, 0.56)
    scene.world = world
    scene.render.engine = "BLENDER_WORKBENCH"
    sh = scene.display.shading
    sh.color_type = "MATERIAL"
    sh.light = "STUDIO"
    sh.show_backface_culling = True
    sh.show_cavity = True
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    return cam


def render_view(cam, path, loc, target, lens=35, res=(1600, 1000), show=None):
    scene = bpy.context.scene
    for ob in scene.objects:
        if ob.type == "MESH":
            ob.hide_render = show is not None and ob not in show
    cam.location = loc
    cam.rotation_euler = (target - loc).to_track_quat("-Z", "Y").to_euler()
    cam.data.lens = lens
    cam.data.clip_start = 0.05
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


def render(cam, path, obs):
    lo = V((min(box(o)["min"][0] for o in obs), min(box(o)["min"][1] for o in obs), min(box(o)["min"][2] for o in obs)))
    hi = V((max(box(o)["max"][0] for o in obs), max(box(o)["max"][1] for o in obs), max(box(o)["max"][2] for o in obs)))
    centre, size = (lo + hi) / 2, (hi - lo).length
    render_view(cam, path, centre + V((size * 0.45, -size * 0.75, size * 0.45)), centre, 40, show=obs)


# close-ups at the player's scale (camera, target, lens), the shrine from where players see it: the lane, the beach,
# standing under its roof looking up, and from above
CLOSEUPS = {
    "Shrine": {"lane": (V((16, 38, 6)), V((0, 0, 8)), 30), "beach": (V((-40, 10, 5)), V((0, 0, 9)), 30),
               "under": (V((5.5, 3.5, 4.2)), V((-3, -2, 14)), 14), "above": (V((28, -34, 34)), V((0, 0, 9)), 30)},
    "Boat": {"side": (V((9, -10, 5)), V((0, 0, 0.6)), 35), "low": (V((-6, 3, 0.4)), V((0, 0, 1.2)), 28)},
}


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out = Path(argv[0] if argv else "build/art")
    out.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    meta, objs, per_item, by_item = {}, [], {}, {}
    for item, build in ITEMS.items():
        rng = random.Random(item)
        for part, spec in build(rng).items():
            bm, rgb = spec[0], spec[1]
            ob = to_object(bm, f"{item}_{part}", rgb, spec[2] if len(spec) > 2 else None)
            meta[ob.name] = {**box(ob), "rgb": list(rgb)}
            per_item[item] = per_item.get(item, 0) + meta[ob.name]["tris"]
            by_item.setdefault(item, []).append(ob)
            objs.append(ob)
    problems = {}
    for item, obs in by_item.items():
        c = check_item(item, obs)
        if any(c.values()):
            problems[item] = c
        if per_item[item] > 5000:
            problems.setdefault(item, {})["over_budget_tris"] = per_item[item]
    (out / "set").mkdir(exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(out / "set" / "mada_art.glb"), export_format="GLB", export_apply=True, export_yup=True)
    (out / "set" / "meta.json").write_text(json.dumps({"source": "own", "id": "mada_art", "name": "Làng Vọng models", "author": "Raumania",
        "license": "own", "license_label": "Made for Raumania", "url": "tools/blender/mada_art.py", "credit": "Làng Vọng's own models"}))
    (out / "art.json").write_text(json.dumps(meta, indent=1))
    if "--preview" in argv:
        cam = setup_render()
        for item, views in CLOSEUPS.items():
            for view, (loc, target, lens) in views.items():
                render_view(cam, out / f"preview_{item.lower()}_{view}.png", loc, target, lens, (1200, 800), show=by_item[item])
        spots = {}  # every item side by side, big ones scaled down so the little ones show
        for i, item in enumerate(ITEMS):
            spots[item] = V(((i % 5) * 7.0, -(i // 5) * 8.0, 0))
        for ob in objs:
            item = ob.name.split("_")[0]
            k = 0.18 if item == "Shrine" else (0.4 if item in ("Causeway", "Boat") else (0.25 if item.startswith("House") else 1.0))
            ob.data.transform(Matrix.Translation(spots[item]) @ Matrix.Scale(k, 4))
        render(cam, out / "preview.png", objs)
    print(json.dumps(per_item))
    print("PROBLEMS " + json.dumps(problems) if problems else "CHECK OK: every item closed, no inside-out shells, all under 5,000 tris")


if __name__ == "__main__":
    main()
