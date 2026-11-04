"""Làng Vọng's land, designed here and ported into Roblox terrain (owner 2026-11-04: "revamp the entire map ... look like
a basin ... build a map in blender then port them in").

  blender -b --python tools/blender/mada_land.py -- [--preview]     # Blender: preview renders of the basin
  python tools/blender/mada_land.py                                 # plain Python: only writes the Lua data

One height + material map on an 8-stud grid (x -800..800, z -800..600; Roblox axes: y up, the lake toward -z) is the
single source: src/shared/Content/Land.luau carries it, Build.luau writes the terrain from it. The story's places keep
their spots (the lane z -20, the houses z 30, the shore z -50, the shrine -330,-64, the dock -140, the cove 350,-45, the
marsh -410,150, the causeway): flat where the game needs it; around the village the land rises into a basin rim, and
across the lake limestone karst towers stand against the sky.
"""
import math
import pathlib
import random
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
STEP = 8
X0, X1, Z0, Z1 = -800, 800, -800, 600
NX, NZ = (X1 - X0) // STEP + 1, (Z1 - Z0) // STEP + 1
WATER = -1.0
HOUSES = [-250, -195, -140, -85, -30, 25, 80, 135, 190, 245]
LANE_Z, HOUSE_Z, SHORE_Z = -20, 30, -50


# ---------------------------------------------------------------- noise (value noise, deterministic)

def _hash(ix, iz, seed):
    n = (ix * 374761393 + iz * 668265263 + seed * 2147483647) & 0xFFFFFFFF
    n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
    return ((n ^ (n >> 16)) & 0xFFFF) / 65535.0


def _vnoise(x, z, seed):
    ix, iz = math.floor(x), math.floor(z)
    fx, fz = x - ix, z - iz
    fx, fz = fx * fx * (3 - 2 * fx), fz * fz * (3 - 2 * fz)
    a, b = _hash(ix, iz, seed), _hash(ix + 1, iz, seed)
    c, d = _hash(ix, iz + 1, seed), _hash(ix + 1, iz + 1, seed)
    return (a + (b - a) * fx) * (1 - fz) + (c + (d - c) * fx) * fz


def fbm(x, z, scale, seed, oct=4):
    s, amp, tot = 0.0, 1.0, 0.0
    for o in range(oct):
        s += amp * (_vnoise(x / scale * 2 ** o, z / scale * 2 ** o, seed + o) * 2 - 1)
        tot += amp
        amp *= 0.5
    return s / tot


def smooth(a, b, x):
    t = min(1.0, max(0.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


# ---------------------------------------------------------------- the land

rng = random.Random(1975)
# karst towers across the lake and round the rim: (x, z, radius, height)
TOWERS = []
for _ in range(34):
    a = rng.uniform(-0.15, math.pi + 0.15)  # the southern half, behind the lake
    r = rng.uniform(470, 760)
    TOWERS.append((math.cos(a) * r * 1.05, -300 - math.sin(a) * (r - 300) * 0.9, rng.uniform(26, 62), rng.uniform(70, 190)))
for _ in range(5):  # a few far behind the village too, over the hills
    TOWERS.append((rng.uniform(-700, 700), rng.uniform(470, 590), rng.uniform(30, 50), rng.uniform(70, 120)))


def shore_z(x):
    """the north shore of the lake (the village side) wobbles a little round z -50"""
    return SHORE_Z + fbm(x, 0, 90, 3, 2) * 3


def lake_depth(x, z):
    """> 0 inside the lake: how far in from its edge (studs)"""
    # an organic oval, cut off straight-ish on the village side by the shore line
    # (wide enough that the village side is the shore line itself from the shrine to the cove: a narrower oval pulled the
    # shore south at the shrine's end and buried Bin's camera in the reeds, 2026-11-04)
    dx, dz = (x - 0) / 620, (z + 340) / 380
    rim = 1 - math.sqrt(dx * dx + dz * dz) + fbm(x, z, 140, 5, 3) * 0.12
    inside_oval = rim * 300
    inside_shore = shore_z(x) - z
    return min(inside_oval, inside_shore)


def in_cove(x, z):
    return ((x - 350) / 40) ** 2 + ((z + 48) / 40) ** 2 < 1 or (abs(x - 350) < 30 and -100 < z < -40)


def in_marsh(x, z):
    return ((x + 410) / 125) ** 2 + ((z - 150) / 120) ** 2 < 1


def playable(x, z):
    """the land players walk on (inside the boundary walls): the village band and the shrine's end"""
    return -380 <= x <= 420 and -60 <= z <= 125


def height(x, z):
    """the land's surface height (y) at x, z"""
    # the rim: rising outside the playable land, in all directions but the lake and the marsh's valley
    ox = max(-380 - x, x - 420, 0)
    oz = max(z - 125, 0)
    out = math.sqrt(ox * ox + oz * oz)
    hills = smooth(0, 170, out) ** 1.15 * (85 + fbm(x, z, 160, 11, 4) * 55) + smooth(120, 420, out) * 90
    hills += smooth(40, 200, out) * fbm(x, z, 45, 12, 3) * 14  # ridges and gullies
    h = 0.0
    # inside: the lane, the house pads and the shrine flat; the back yards rise gently behind the houses
    if playable(x, z):
        back = smooth(55, 125, z) * (3 + fbm(x, z, 60, 7, 3) * 2)
        h = back + fbm(x, z, 40, 8, 2) * 0.6 * smooth(55, 80, z)
    h = max(h, hills)
    # the marsh's valley: low ground winding west and south to where the causeway arrives
    # (the valley runs out along the causeway, south-west: its walls are gentle hills, not a crater)
    u, v = (x + 395) * 0.7071 - (z - 140) * 0.7071, (x + 395) * 0.7071 + (z - 140) * 0.7071
    md = math.sqrt((u / 120) ** 2 + (v / 230) ** 2)
    h *= smooth(0.9, 2.4, md)
    if md < 1.35:
        low = -2.2 + fbm(x, z, 25, 13, 2) * 1.6  # tussocks above the water, pools below it
        h = h * smooth(0.85, 1.35, md) + low * (1 - smooth(0.85, 1.35, md))
    # the lake: a soft shore down into deep water, far shore rising beyond
    d = lake_depth(x, z)
    if d > -40:
        bed = -13 - fbm(x, z, 80, 9, 2) * 2
        shore = 0.0 if d < 0 else -min(1.0, d / 30) ** 0.7 * (13 + fbm(x, z, 80, 9, 2) * 2)
        w = smooth(-40, 0, d)
        h = h * (1 - w) + (shore if d < 30 else bed) * w
    if in_cove(x, z):
        h = min(h, -9.0)
    # the karst towers (steep limestone)
    for tx, tz, tr, th in TOWERS:
        dd = math.hypot(x - tx, z - tz) * (1 + fbm(x, z, 30, int(tx) % 97, 2) * 0.35)  # ragged outline
        if dd < tr * 1.25:
            k = 1 - smooth(tr * 0.75, tr * 1.25, dd)  # sheer walls
            top = th * (0.82 + fbm(x, z, 22, int(tz) % 89, 3) * 0.25)  # a broken, rounded top
            h = max(h, (-2 if lake_depth(x, z) > 0 else h) + top * k ** 0.35)
    # keep the story's flat places flat
    for hx in HOUSES:
        if abs(x - hx) < 18 and abs(z - HOUSE_Z) < 16:
            h = 0.0
    if -340 <= x <= 330 and abs(z - LANE_Z) < 9:
        h = 0.0
    if abs(x + 330) < 24 and abs(z + 64) < 20:  # the shrine's ground
        h = max(min(h, 0.0), -2.0)
    return h


def material(x, z, h, slope):
    """one letter per cell: G grass, L leafy grass, D dirt path, M mud, R rock, S limestone, W wet sand"""
    if any(math.hypot(x - tx, z - tz) < tr * 1.3 for tx, tz, tr, _ in TOWERS) and h > 12:
        return "L" if slope < 0.55 else "S"  # jungle on the tops and ledges, bare limestone on the walls
    if h < WATER + 0.5:
        return "M"
    if h < WATER + 2.2 and (lake_depth(x, z) > -14 or in_marsh(x, z) or in_cove(x, z)):
        return "W"
    if -340 <= x <= 330 and abs(z - LANE_Z) < 6 + fbm(x, z, 30, 2, 2) * 1.5:
        return "D"
    for hx in HOUSES:  # a worn path from the lane to each door
        if abs(x - hx) < 3 + fbm(x, z, 12, 4, 1) and LANE_Z < z < HOUSE_Z - 8:
            return "D"
    if slope > 1.4:
        return "R"
    if h > 18 or (fbm(x, z, 70, 14, 2) > 0.15 and z > 50):
        return "L"
    return "G"


def grid():
    hs = [[height(X0 + i * STEP, Z0 + k * STEP) for i in range(NX)] for k in range(NZ)]
    mats = []
    for k in range(NZ):
        row = []
        for i in range(NX):
            h = hs[k][i]
            sx = abs(hs[k][min(i + 1, NX - 1)] - hs[k][max(i - 1, 0)]) / (2 * STEP)
            sz = abs(hs[min(k + 1, NZ - 1)][i] - hs[max(k - 1, 0)][i]) / (2 * STEP)
            row.append(material(X0 + i * STEP, Z0 + k * STEP, h, max(sx, sz)))
        mats.append("".join(row))
    return hs, mats


def write_lua(hs, mats):
    # heights in quarter studs, as a comma list per row (rows = z); materials one letter per cell
    lines = ["-- Generated by tools/blender/mada_land.py (do not edit by hand): Làng Vọng's land on an 8-stud grid.",
             "-- heights: quarter studs, one row per z (Z0 + k * STEP), one value per x (X0 + i * STEP).",
             "-- mats: G grass, L leafy grass, D dirt, M mud, R rock, S limestone, W wet sand.",
             f"return {{ STEP = {STEP}, X0 = {X0}, Z0 = {Z0}, NX = {NX}, NZ = {NZ}, WATER = {WATER},", "\theights = {"]
    for row in hs:
        lines.append('\t\t"' + ",".join(str(int(round(h * 4))) for h in row) + '",')
    lines.append("\t},")
    lines.append("\tmats = {")
    for row in mats:
        lines.append(f'\t\t"{row}",')
    lines.append("\t},")
    lines.append("}")
    out = ROOT / "src" / "shared" / "Content" / "Land.luau"
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(out, f"{NX} x {NZ} cells, {out.stat().st_size // 1024} KB")


COLORS = {"G": (0.18, 0.32, 0.14), "L": (0.12, 0.26, 0.1), "D": (0.36, 0.28, 0.2), "M": (0.22, 0.2, 0.17), "R": (0.38, 0.37, 0.35),
          "S": (0.62, 0.62, 0.6), "W": (0.42, 0.38, 0.3)}


def blender_preview(hs, mats):
    import bmesh
    import bpy
    from mathutils import Vector
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bm = bmesh.new()
    verts = [[bm.verts.new(Vector((X0 + i * STEP, -(Z0 + k * STEP), hs[k][i]))) for i in range(NX)] for k in range(NZ)]
    me = bpy.data.meshes.new("Land")
    mat_index = {}
    for k in range(NZ - 1):
        for i in range(NX - 1):
            f = bm.faces.new((verts[k][i], verts[k][i + 1], verts[k + 1][i + 1], verts[k + 1][i]))
            f.material_index = mat_index.setdefault(mats[k][i], len(mat_index))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    for name, idx in sorted(mat_index.items(), key=lambda t: t[1]):
        m = bpy.data.materials.new(name)
        m.diffuse_color = (*COLORS[name], 1)
        me.materials.append(m)
    land = bpy.data.objects.new("Land", me)
    bpy.context.scene.collection.objects.link(land)
    # the water, and the story's places as markers
    bpy.ops.mesh.primitive_plane_add(size=1, location=(0, 300, WATER))
    w = bpy.context.object
    w.scale = (1600, 1400, 1)
    wm = bpy.data.materials.new("Water"); wm.diffuse_color = (0.1, 0.22, 0.32, 1); w.data.materials.append(wm)
    hm = bpy.data.materials.new("House"); hm.diffuse_color = (0.9, 0.82, 0.6, 1)
    for hx in HOUSES:
        bpy.ops.mesh.primitive_cube_add(size=1, location=(hx, -HOUSE_Z, 6))
        o = bpy.context.object; o.scale = (22, 18, 12); o.data.materials.append(hm)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(-330, 64, 7))
    o = bpy.context.object; o.scale = (26, 20, 14)
    rm = bpy.data.materials.new("Shrine"); rm.diffuse_color = (0.6, 0.15, 0.1, 1); o.data.materials.append(rm)
    scene = bpy.context.scene
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN")); sun.data.energy = 3
    sun.rotation_euler = (math.radians(45), 0, math.radians(200)); scene.collection.objects.link(sun)
    world = bpy.data.worlds.new("W"); world.color = (0.55, 0.6, 0.68); scene.world = world
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.color_type = "MATERIAL"
    scene.render.resolution_x, scene.render.resolution_y = 1600, 1000
    out = ROOT / "build" / "land"
    out.mkdir(parents=True, exist_ok=True)
    for name, loc, look, lens in (("overview", (0, 1150, 700), (0, 0, -40), 28), ("from-lake", (0, 330, 16), (0, -60, 30), 22),
                                  ("from-shore", (-60, 30, 8), (0, 420, 40), 20), ("marsh", (-300, -60, 40), (-420, -150, 0), 22)):
        cam = bpy.data.objects.new("Cam_" + name, bpy.data.cameras.new(name))
        scene.collection.objects.link(cam)
        cam.location = Vector(loc)
        cam.rotation_euler = (Vector(look) - cam.location).to_track_quat("-Z", "Y").to_euler()
        cam.data.lens = lens
        cam.data.clip_end = 5000
        scene.camera = cam
        scene.render.filepath = str(out / f"{name}.png")
        bpy.ops.render.render(write_still=True)


def main():
    hs, mats = grid()
    write_lua(hs, mats)
    if "bpy" in sys.modules or "--preview" in sys.argv:
        try:
            import bpy  # noqa: F401
            blender_preview(hs, mats)
        except ImportError:
            pass


if __name__ == "__main__":
    main()
