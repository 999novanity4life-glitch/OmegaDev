"""Low-poly stylised kit (ref: Sharman's map-style video, 2026-11-20).
Writes Studio preview meshes in the fruit preview format: line 1 vertices
`x,y,z,rrggbb,gg` (milli-studs, Y-up), line 2 zero-based triangles. Flat shaded:
every face has its own 3 vertices so Roblox computes per-face normals."""
import math, sys, os
import numpy as np

def ico(sub=1):
    t = (1 + 5 ** 0.5) / 2
    v = [(-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0), (0, -1, t), (0, 1, t), (0, -1, -t), (0, 1, -t), (t, 0, -1), (t, 0, 1), (-t, 0, -1), (-t, 0, 1)]
    f = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6), (7, 1, 8), (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9), (4, 9, 5), (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1)]
    v = [np.array(p, float) / np.linalg.norm(p) for p in v]
    for _ in range(sub):
        cache, nf = {}, []
        def mid(a, b):
            k = (min(a, b), max(a, b))
            if k not in cache:
                m = v[a] + v[b]; v.append(m / np.linalg.norm(m)); cache[k] = len(v) - 1
            return cache[k]
        for a, b, c in f:
            ab, bc, ca = mid(a, b), mid(b, c), mid(c, a)
            nf += [(a, ab, ca), (b, bc, ab), (c, ca, bc), (ab, bc, ca)]
        f = nf
    return np.array(v), f

class Mesh:
    def __init__(s): s.v, s.c, s.t = [], [], []
    def tri(s, a, b, c, col, shade=True):
        a, b, c = map(np.asarray, (a, b, c))
        n = np.cross(b - a, c - a); n = n / (np.linalg.norm(n) + 1e-9)
        k = (0.78 + 0.22 * max(0, n[1])) if shade else 1.0  # top faces a touch lighter (painted light)
        col = np.clip(np.array(col) * k, 0, 1)
        i = len(s.v)
        for p in (a, b, c): s.v.append(p); s.c.append(col)
        s.t.append((i, i + 1, i + 2))
    def write(s, path):
        V = ";".join("%d,%d,%d,%02x%02x%02x,00" % (round(p[0] * 1000), round(p[1] * 1000), round(p[2] * 1000), *(np.clip(np.array(c) * 255, 0, 255).astype(int))) for p, c in zip(s.v, s.c))
        T = ";".join("%d,%d,%d" % t for t in s.t)
        open(path, "w").write(V + "\n" + T)
        return len(s.t)

def hexc(h): return np.array([int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)])

def blob(m, centre, radius, squash, rng, col, jitter=0.22, sub=1, colvar=0.06):
    v, f = ico(sub)
    r = 1 + rng.uniform(-jitter, jitter, len(v))
    p = v * r[:, None] * radius
    p[:, 1] *= squash
    p += centre
    for a, b, c in f:
        cc = np.array(col) * (1 + rng.uniform(-colvar, colvar))
        m.tri(p[a], p[b], p[c], cc)

def boulder(seed):
    rng = np.random.default_rng(seed); m = Mesh()
    blob(m, np.zeros(3), 1.0, rng.uniform(0.6, 0.85), rng, hexc("7d8fe6"), jitter=0.28, sub=1)
    return m

def tree(seed):
    rng = np.random.default_rng(seed); m = Mesh()
    trunk = hexc("8a4b2a"); h = rng.uniform(2.2, 3.0); n = 6
    for i in range(n):  # tapered, slightly bent hex trunk
        a0, a1 = i / n * math.tau, (i + 1) / n * math.tau
        for y0, y1 in ((0, h * 0.5), (h * 0.5, h)):
            r0, r1 = 0.32 - 0.1 * y0 / h, 0.32 - 0.1 * y1 / h
            b0, b1 = 0.15 * (y0 / h) ** 2, 0.15 * (y1 / h) ** 2
            p00 = (b0 + r0 * math.cos(a0), y0, r0 * math.sin(a0)); p01 = (b0 + r0 * math.cos(a1), y0, r0 * math.sin(a1))
            p10 = (b1 + r1 * math.cos(a0), y1, r1 * math.sin(a0)); p11 = (b1 + r1 * math.cos(a1), y1, r1 * math.sin(a1))
            m.tri(p00, p10, p11, trunk); m.tri(p00, p11, p01, trunk)
    leaf = [hexc("3fd35a"), hexc("5be86a"), hexc("2fb84e")]
    for k in range(rng.integers(4, 6)):
        ang = rng.uniform(0, math.tau); d = rng.uniform(0.3, 0.8) if k else 0
        c = np.array([0.15 + d * math.cos(ang), h + rng.uniform(-0.2, 0.7), d * math.sin(ang)])
        blob(m, c, rng.uniform(0.8, 1.15), 0.8, rng, leaf[k % 3], jitter=0.2)
    return m

def crystal(seed):
    rng = np.random.default_rng(seed); m = Mesh()
    cols = [hexc("6fe3ff"), hexc("3fb0ff"), hexc("9af0ff")]
    for k in range(rng.integers(5, 8)):
        L = rng.uniform(0.8, 1.8); r = rng.uniform(0.15, 0.3)
        tilt = rng.uniform(0, 0.6); yaw = rng.uniform(0, math.tau)
        axis = np.array([math.sin(tilt) * math.cos(yaw), math.cos(tilt), math.sin(tilt) * math.sin(yaw)])
        u = np.cross(axis, [0, 0, 1.0]); u /= np.linalg.norm(u); w = np.cross(axis, u)
        base = np.array([rng.uniform(-0.3, 0.3), 0, rng.uniform(-0.3, 0.3)])
        ring0 = [base + r * (math.cos(i / 6 * math.tau) * u + math.sin(i / 6 * math.tau) * w) for i in range(6)]
        ring1 = [p + axis * L for p in ring0]; tip = base + axis * (L + r * 2.2)
        col = cols[k % 3]
        for i in range(6):
            j = (i + 1) % 6
            m.tri(ring0[i], ring1[i], ring1[j], col); m.tri(ring0[i], ring1[j], ring0[j], col)
            m.tri(ring1[i], tip, ring1[j], col * 1.1)
    blob(m, np.array([0, 0.1, 0]), 0.6, 0.5, rng, hexc("7d8fe6"), jitter=0.25)
    return m

def stepstone(seed):
    rng = np.random.default_rng(seed); m = Mesh(); col = hexc("6b5fc9"); h = 0.25
    pts = [(math.cos(i / 6 * math.tau + 0.2) * (1 + rng.uniform(-0.12, 0.12)), math.sin(i / 6 * math.tau + 0.2) * (1 + rng.uniform(-0.12, 0.12))) for i in range(6)]
    for i in range(6):
        j = (i + 1) % 6; a, b = pts[i], pts[j]
        m.tri((0, h, 0), (b[0], h, b[1]), (a[0], h, a[1]), col)
        m.tri((a[0], 0, a[1]), (a[0], h, a[1]), (b[0], h, b[1]), col * 0.8); m.tri((a[0], 0, a[1]), (b[0], h, b[1]), (b[0], 0, b[1]), col * 0.8)
    return m

def bush(seed):
    rng = np.random.default_rng(seed); m = Mesh()
    for k in range(3):
        blob(m, np.array([rng.uniform(-0.4, 0.4), 0.5 + rng.uniform(0, 0.3), rng.uniform(-0.4, 0.4)]), rng.uniform(0.55, 0.75), 0.85, rng, hexc("47d65e"), jitter=0.2)
    return m

if __name__ == "__main__":
    out = sys.argv[1]; os.makedirs(out, exist_ok=True)
    jobs = {f"boulder_{i}": (boulder, 10 + i) for i in range(1, 5)}
    jobs.update({f"tree_{i}": (tree, 20 + i) for i in range(1, 4)})
    jobs.update({f"crystal_{i}": (crystal, 30 + i) for i in range(1, 3)})
    jobs.update({"stepstone_1": (stepstone, 41), "bush_1": (bush, 51)})
    for name, (fn, seed) in jobs.items():
        print(name, fn(seed).write(os.path.join(out, name + ".txt")))
