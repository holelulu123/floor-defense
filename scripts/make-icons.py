#!/usr/bin/env python3
"""Draws the stat icons used by the HUD and the showcase into assets/ui/icons/ (our own, CC0).
Run after changing a shape: scripts/make-icons.py"""
import math
import pathlib

from PIL import Image, ImageDraw

OUT = pathlib.Path(__file__).resolve().parent.parent / "assets" / "ui" / "icons"
OUT.mkdir(parents=True, exist_ok=True)
S = 128  # drawn at 128, saved at 128 and 64


def canvas():
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def save(im, name):
    im.save(OUT / f"{name}.png")
    im.resize((64, 64), Image.LANCZOS).save(OUT / f"{name}@64.png")


def heart():
    im, d = canvas()
    c = (235, 70, 90, 255)
    d.ellipse((16, 22, 66, 72), fill=c)
    d.ellipse((62, 22, 112, 72), fill=c)
    d.polygon([(18, 56), (110, 56), (64, 112)], fill=c)
    d.ellipse((34, 32, 48, 46), fill=(255, 160, 170, 255))
    save(im, "health")


def speed():
    im, d = canvas()
    c = (120, 200, 255, 255)
    for i, x in enumerate((20, 48, 76)):
        pts = [(x, 24), (x + 28, 64), (x, 104), (x + 12, 104), (x + 40, 64), (x + 12, 24)]
        a = 255 - i * 40
        d.polygon(pts, fill=(c[0], c[1], c[2], a))
    save(im, "speed")


def damage():
    im, d = canvas()
    c = (255, 150, 60, 255)
    pts = []
    for i in range(16):
        r = 56 if i % 2 == 0 else 28
        a = math.pi * 2 * i / 16 - math.pi / 2
        pts.append((64 + r * math.cos(a), 64 + r * math.sin(a)))
    d.polygon(pts, fill=c)
    d.ellipse((50, 50, 78, 78), fill=(255, 230, 150, 255))
    save(im, "damage")


def coin():
    im, d = canvas()
    d.ellipse((14, 14, 114, 114), fill=(230, 180, 50, 255))
    d.ellipse((26, 26, 102, 102), fill=(255, 215, 90, 255))
    d.rounded_rectangle((56, 40, 72, 88), radius=6, fill=(230, 180, 50, 255))
    d.rounded_rectangle((44, 40, 84, 54), radius=6, fill=(230, 180, 50, 255))
    save(im, "coins")


def wave():
    im, d = canvas()
    c = (190, 120, 255, 255)
    d.rectangle((24, 16, 34, 112), fill=c)
    d.polygon([(34, 18), (106, 18), (90, 44), (106, 70), (34, 70)], fill=(210, 160, 255, 255))
    save(im, "wave")


def skull():
    im, d = canvas()
    c = (235, 235, 225, 255)
    d.ellipse((24, 14, 104, 90), fill=c)
    d.rectangle((40, 70, 88, 104), fill=c)
    for x in (42, 70):
        d.ellipse((x, 38, x + 18, 58), fill=(40, 40, 50, 255))
    d.polygon([(64, 60), (58, 74), (70, 74)], fill=(40, 40, 50, 255))
    for x in (46, 58, 70):
        d.rectangle((x, 90, x + 8, 104), fill=(40, 40, 50, 255))
    save(im, "kills")


# ---- Currency, ammo and skill icons: drawn at 4x on a 128-unit grid and downsampled, so edges stay smooth.
K = 4


class Pen:
    """ImageDraw on a 512 px canvas that takes coordinates on the same 0..128 grid as the icons above."""

    def __init__(self):
        self.im = Image.new("RGBA", (S * K, S * K), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)

    def _b(self, box):
        return [v * K for v in box]

    def _p(self, pts):
        return [(x * K, y * K) for x, y in pts]

    def ellipse(self, box, **kw):
        self.d.ellipse(self._b(box), **self._w(kw))

    def rect(self, box, r=0, **kw):
        self.d.rounded_rectangle(self._b(box), radius=r * K, **self._w(kw))

    def poly(self, pts, **kw):
        self.d.polygon(self._p(pts), **self._w(kw))

    def line(self, pts, width, fill, joint="curve"):
        self.d.line(self._p(pts), fill=fill, width=int(width * K), joint=joint)
        for x, y in (pts[0], pts[-1]):  # round caps
            r = width / 2
            self.d.ellipse(self._b((x - r, y - r, x + r, y + r)), fill=fill)

    def arc(self, box, start, end, width, fill):
        self.d.arc(self._b(box), start, end, fill=fill, width=int(width * K))

    def _w(self, kw):
        if "width" in kw:
            kw["width"] = int(kw["width"] * K)
        return kw

    def save(self, name):
        im = self.im.resize((S, S), Image.LANCZOS)
        save(im, name)


def star(cx, cy, r1, r2, n, rot=-math.pi / 2):
    return [(cx + (r1 if i % 2 == 0 else r2) * math.cos(rot + math.pi * i / n), cy + (r1 if i % 2 == 0 else r2) * math.sin(rot + math.pi * i / n)) for i in range(2 * n)]


def flame(p, cx, base, w, h, outer=(255, 110, 30, 255), inner=(255, 215, 80, 255)):
    p.poly([(cx - w / 2, base), (cx - w * 0.55, base - h * 0.45), (cx - w * 0.15, base - h * 0.7), (cx - w * 0.05, base - h), (cx + w * 0.25, base - h * 0.62), (cx + w * 0.55, base - h * 0.5), (cx + w / 2, base)], fill=outer)
    p.poly([(cx - w * 0.28, base), (cx - w * 0.25, base - h * 0.35), (cx, base - h * 0.62), (cx + w * 0.28, base - h * 0.32), (cx + w * 0.28, base)], fill=inner)
    p.ellipse((cx - w / 2, base - w * 0.45, cx + w / 2, base + w * 0.25), fill=outer)
    p.ellipse((cx - w * 0.28, base - w * 0.3, cx + w * 0.28, base + w * 0.12), fill=inner)


def bullet(p, x, y, w, h, case=(214, 160, 60, 255), tip=(190, 120, 70, 255)):
    p.rect((x, y + h * 0.35, x + w, y + h), r=w * 0.15, fill=case)
    p.poly([(x, y + h * 0.36), (x + w / 2, y), (x + w, y + h * 0.36)], fill=tip)
    p.ellipse((x, y + h * 0.18, x + w, y + h * 0.5), fill=tip)
    p.rect((x - w * 0.08, y + h * 0.88, x + w * 1.08, y + h), r=w * 0.1, fill=(170, 120, 40, 255))


def gem():
    p = Pen()
    p.poly([(64, 112), (12, 46), (34, 18), (94, 18), (116, 46)], fill=(60, 200, 255, 255))
    p.poly([(34, 18), (50, 46), (78, 46), (94, 18)], fill=(150, 235, 255, 255))
    p.poly([(12, 46), (50, 46), (64, 112)], fill=(40, 150, 230, 255))
    p.poly([(78, 46), (116, 46), (64, 112)], fill=(90, 215, 255, 255))
    p.poly([(50, 46), (78, 46), (64, 112)], fill=(70, 185, 250, 255))
    p.poly([(40, 26), (48, 26), (40, 38)], fill=(235, 252, 255, 255))
    p.save("gems")


def ammo():
    p = Pen()
    for i, x in enumerate((22, 52, 82)):
        bullet(p, x, 18 + (i % 2) * 6, 24, 90)
    p.save("ammo")


def reload_icon():
    p = Pen()
    c = (120, 220, 140, 255)
    p.arc((18, 18, 110, 110), 200, 470, 14, c)
    p.poly([(14, 40), (40, 40), (24, 66)], fill=c)
    p.save("reload")


# Skill icons: a glyph on a dark rounded tile tinted by the class colour, so they read at 32 px on any HUD.
CLASS_TINT = {
    "Trooper": (70, 120, 70), "Tank": (110, 90, 70), "Scout": (60, 110, 150), "Medic": (60, 140, 110),
    "Engineer": (150, 120, 50), "Berserker": (150, 50, 50), "Mage": (100, 70, 160), "Pyro": (170, 80, 30),
    "Sniper": (80, 90, 110), "Demolisher": (120, 100, 40),
}


def tile(cls):
    p = Pen()
    r, g, b = CLASS_TINT[cls]
    p.rect((4, 4, 124, 124), r=24, fill=(r // 3 + 10, g // 3 + 10, b // 3 + 10, 255))
    p.rect((4, 4, 124, 124), r=24, outline=(r, g, b, 255), width=6)
    return p


WHITE, GOLD, RED, BLUE, GREEN = (240, 240, 240, 255), (255, 205, 60, 255), (240, 70, 60, 255), (110, 190, 255, 255), (90, 230, 130, 255)
STEEL, DARK = (180, 186, 196, 255), (60, 64, 74, 255)


def sk_burst_fire():
    p = tile("Trooper")
    for i, y in enumerate((28, 52, 76)):
        p.poly([(30 + i * 6, y + 6), (88 + i * 6, y + 6), (100 + i * 6, y + 12), (88 + i * 6, y + 18), (30 + i * 6, y + 18)], fill=GOLD)
        p.line([(14 + i * 6, y + 12), (26 + i * 6, y + 12)], 4, (255, 240, 180, 200))
    p.save("skill_burst_fire")


def sk_ammo_crate():
    p = tile("Trooper")
    p.rect((20, 46, 108, 106), r=6, fill=(90, 110, 60, 255))
    p.rect((16, 38, 112, 54), r=5, fill=(120, 140, 80, 255))
    p.rect((56, 38, 72, 106), fill=GOLD)
    bullet(p, 40, 12, 14, 34)
    bullet(p, 74, 12, 14, 34)
    p.save("skill_ammo_crate")


def sk_flail_sweep():
    p = tile("Tank")
    p.arc((14, 14, 114, 114), 200, 520, 8, WHITE)
    p.poly([(98, 22), (116, 30), (104, 44)], fill=WHITE)
    p.line([(40, 92), (60, 64)], 5, STEEL)
    p.poly(star(66, 56, 24, 14, 8), fill=DARK)
    p.ellipse((52, 42, 80, 70), fill=(120, 124, 134, 255))
    p.save("skill_flail_sweep")


def sk_iron_wall():
    p = tile("Tank")
    p.poly([(64, 14), (108, 28), (104, 72), (64, 114), (24, 72), (20, 28)], fill=STEEL)
    p.poly([(64, 24), (98, 35), (95, 70), (64, 102), (33, 70), (30, 35)], fill=(120, 90, 60, 255))
    p.rect((58, 30, 70, 96), fill=STEEL)
    p.rect((36, 50, 92, 62), fill=STEEL)
    p.save("skill_iron_wall")


def sk_dash():
    p = tile("Scout")
    for i, x in enumerate((26, 54)):
        a = 255 - (1 - i) * 90
        p.poly([(x, 28), (x + 30, 64), (x, 100), (x + 18, 100), (x + 48, 64), (x + 18, 28)], fill=(110, 200, 255, a))
    for y in (40, 64, 88):
        p.line([(10, y), (22, y)], 4, (200, 235, 255, 180))
    p.save("skill_dash")


def sk_mark_target():
    p = tile("Scout")
    p.ellipse((24, 24, 104, 104), outline=RED, width=7)
    p.ellipse((52, 52, 76, 76), fill=RED)
    for a, b in (((64, 12), (64, 34)), ((64, 94), (64, 116)), ((12, 64), (34, 64)), ((94, 64), (116, 64))):
        p.line([a, b], 6, RED)
    p.save("skill_mark_target")


def sk_repair_pulse():
    p = tile("Medic")
    for r, a in ((54, 90), (42, 160)):
        p.ellipse((64 - r, 64 - r, 64 + r, 64 + r), outline=(90, 230, 130, a), width=5)
    p.rect((52, 30, 76, 98), r=5, fill=GREEN)
    p.rect((30, 52, 98, 76), r=5, fill=GREEN)
    p.save("skill_repair_pulse")


def sk_overcharge():
    p = tile("Medic")
    p.poly([(64, 12), (106, 26), (102, 70), (64, 114), (26, 70), (22, 26)], fill=(255, 205, 60, 90), outline=GOLD, width=5)
    p.poly([(70, 24), (42, 70), (62, 70), (54, 104), (88, 54), (68, 54), (78, 24)], fill=GOLD)
    p.save("skill_overcharge")


def sk_place_turret():
    p = tile("Engineer")
    p.poly([(28, 108), (40, 80), (88, 80), (100, 108)], fill=DARK)
    p.rect((40, 50, 90, 82), r=8, fill=STEEL)
    p.rect((86, 58, 118, 68), r=3, fill=STEEL)
    p.rect((48, 40, 74, 52), r=4, fill=(130, 136, 146, 255))
    p.poly([(14, 22), (30, 22), (30, 14), (44, 28), (30, 42), (30, 34), (14, 34)], fill=GOLD)
    p.save("skill_place_turret")


def sk_overclock():
    p = tile("Engineer")
    p.poly(star(64, 64, 50, 40, 10), fill=STEEL)
    p.ellipse((30, 30, 98, 98), fill=(60, 66, 78, 255))
    p.poly([(70, 30), (46, 68), (62, 68), (56, 98), (84, 58), (68, 58), (76, 30)], fill=(110, 215, 255, 255))
    p.save("skill_overclock")


def sk_cleave():
    p = tile("Berserker")
    p.arc((10, 18, 118, 126), 200, 340, 8, (255, 255, 255, 200))
    p.line([(40, 108), (82, 34)], 8, (130, 90, 50, 255))
    p.poly([(74, 26), (110, 34), (100, 64), (82, 52)], fill=STEEL)
    p.poly([(74, 26), (60, 14), (56, 40)], fill=STEEL)
    p.save("skill_cleave")


def sk_rage():
    p = tile("Berserker")
    flame(p, 64, 112, 70, 96, outer=(220, 40, 40, 255), inner=(255, 140, 60, 255))
    p.poly([(40, 60), (58, 70), (40, 72)], fill=(40, 10, 10, 255))
    p.poly([(88, 60), (70, 70), (88, 72)], fill=(40, 10, 10, 255))
    p.save("skill_rage")


def sk_arcane_bolt():
    p = tile("Mage")
    p.poly([(16, 104), (52, 70), (58, 78)], fill=(180, 120, 255, 170))
    p.poly(star(72, 54, 38, 15, 4, rot=-math.pi / 4), fill=(200, 150, 255, 255))
    p.ellipse((60, 42, 84, 66), fill=(245, 230, 255, 255))
    p.save("skill_arcane_bolt")


def sk_frost_nova():
    p = tile("Mage")
    c = (190, 240, 255, 255)
    for i in range(6):
        a = math.pi / 3 * i
        x, y = 64 + 46 * math.cos(a), 64 + 46 * math.sin(a)
        p.line([(64, 64), (x, y)], 7, c)
        for t in (0.55, 0.78):
            bx, by = 64 + 46 * t * math.cos(a), 64 + 46 * t * math.sin(a)
            for s in (-1, 1):
                b = a + s * 0.7
                p.line([(bx, by), (bx + 12 * math.cos(b), by + 12 * math.sin(b))], 5, c)
    p.ellipse((54, 54, 74, 74), fill=c)
    p.save("skill_frost_nova")


def sk_flame_sweep():
    p = tile("Pyro")
    p.poly([(14, 60), (110, 26), (118, 64), (110, 102)], fill=(255, 110, 30, 200))
    p.poly([(14, 60), (100, 44), (106, 64), (100, 86)], fill=(255, 200, 70, 255))
    p.rect((8, 54, 30, 70), r=4, fill=STEEL)
    p.save("skill_flame_sweep")


def sk_fire_wall():
    p = tile("Pyro")
    for x, h in ((30, 62), (52, 84), (76, 74), (98, 56)):
        flame(p, x, 104, 26, h)
    p.rect((14, 102, 114, 110), r=3, fill=(120, 50, 20, 255))
    p.save("skill_fire_wall")


def sk_piercing_shot():
    p = tile("Sniper")
    for x in (40, 64, 88):
        p.ellipse((x - 10, 46, x + 10, 82), outline=RED, width=5)
    p.poly([(10, 58), (100, 58), (118, 64), (100, 70), (10, 70)], fill=GOLD)
    p.save("skill_piercing_shot")


def sk_overwatch():
    p = tile("Sniper")
    p.poly([(10, 64), (40, 34), (88, 34), (118, 64), (88, 94), (40, 94)], fill=WHITE)
    p.ellipse((44, 44, 84, 84), fill=(60, 120, 200, 255))
    p.ellipse((56, 56, 72, 72), fill=(20, 20, 30, 255))
    p.line([(64, 14), (64, 30)], 5, RED)
    p.line([(64, 98), (64, 114)], 5, RED)
    p.save("skill_overwatch")


def sk_frag_toss():
    p = tile("Demolisher")
    p.ellipse((26, 40, 96, 114), fill=(90, 120, 60, 255))
    for y in (58, 76, 94):
        p.line([(30, y), (92, y)], 3, (60, 80, 40, 255))
    p.rect((48, 26, 74, 44), r=4, fill=STEEL)
    p.arc((66, 12, 98, 44), 180, 360, 5, STEEL)
    p.poly(star(104, 22, 14, 6, 6), fill=GOLD)
    p.save("skill_frag_toss")


def sk_cluster_bomb():
    p = tile("Demolisher")
    for x, y, r in ((44, 50, 22), (86, 50, 18), (64, 88, 20), (30, 92, 12), (98, 92, 12)):
        p.ellipse((x - r, y - r, x + r, y + r), fill=(50, 50, 60, 255))
        p.ellipse((x - r * 0.5, y - r * 0.6, x - r * 0.1, y - r * 0.2), fill=(120, 120, 130, 255))
        p.poly(star(x + r * 0.7, y - r * 0.8, r * 0.45, r * 0.2, 5), fill=GOLD)
    p.save("skill_cluster_bomb")


for fn in (heart, speed, damage, coin, wave, skull, gem, ammo, reload_icon):
    fn()
for name, fn in list(globals().items()):
    if name.startswith("sk_") and callable(fn):
        fn()
(OUT / "LICENSE.txt").write_text("Stat, currency and skill icons drawn by scripts/make-icons.py for this project. CC0 1.0.\n")
print("icons written to", OUT)
