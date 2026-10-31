#!/usr/bin/env python3
"""Draws the stat, skill and weapon icons used by the HUD and the showcase into assets/ui/icons/ and the class emblems
into assets/ui/classes/ (our own, CC0).
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
    p.save("diamonds")


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


def trophy():
    p = Pen()
    g, hi, dk = (255, 200, 50, 255), (255, 235, 140, 255), (200, 140, 30, 255)
    for s in (-1, 1):  # handles
        cx = 64 + s * 40
        p.arc((cx - 18, 22, cx + 18, 62), 0, 360, 9, dk)
    p.poly([(26, 14), (102, 14), (98, 44), (84, 66), (64, 76), (44, 66), (30, 44)], fill=g)
    p.ellipse((30, 30, 98, 80), fill=g)
    p.poly([(38, 20), (52, 20), (50, 54), (42, 46)], fill=hi)
    p.rect((56, 74, 72, 94), fill=dk)
    p.rect((38, 92, 90, 102), r=3, fill=g)
    p.rect((30, 100, 98, 116), r=4, fill=dk)
    p.poly(star(64, 44, 14, 6, 5), fill=hi)
    p.save("score")


# ---- Class emblems: one bold glyph on the class tile, saved to assets/ui/classes/class_<Id>.png for the class cards.
CLASS_OUT = OUT.parent / "classes"


def emblem(cls, draw):
    """Draws `draw(p)` on its own layer, then lays it on the class tile over a soft drop shadow."""
    from PIL import ImageFilter

    glyph = Pen()
    draw(glyph)
    base = tile(cls)
    shadow = Image.new("RGBA", glyph.im.size, (0, 0, 0, 0))
    shadow.putalpha(glyph.im.getchannel("A").point(lambda a: a * 0.6))
    shadow = shadow.filter(ImageFilter.GaussianBlur(3 * K))
    base.im.alpha_composite(shadow, (0, 3 * K))
    base.im.alpha_composite(glyph.im)
    im = base.im.resize((S, S), Image.LANCZOS)
    im.save(CLASS_OUT / f"class_{cls}.png")
    im.resize((64, 64), Image.LANCZOS).save(CLASS_OUT / f"class_{cls}@64.png")


def em_trooper(p):
    p.poly(star(64, 30, 18, 8, 5), fill=GOLD)
    for y in (58, 84):
        p.poly([(20, y), (64, y + 22), (108, y), (108, y + 18), (64, y + 40), (20, y + 18)], fill=GOLD)


def em_tank(p):
    p.poly([(64, 12), (110, 26), (106, 72), (64, 118), (22, 72), (18, 26)], fill=STEEL)
    p.poly([(64, 24), (98, 35), (95, 70), (64, 104), (33, 70), (30, 35)], fill=(150, 110, 70, 255))
    p.poly([(64, 24), (98, 35), (95, 70), (64, 104)], fill=(120, 88, 56, 255))
    for x, y in ((30, 30), (98, 30), (64, 112), (26, 70), (102, 70)):
        p.ellipse((x - 3, y - 3, x + 3, y + 3), fill=(120, 124, 134, 255))


def em_scout(p):
    boot, sole, c, c2 = (150, 100, 60, 255), (70, 50, 40, 255), (245, 250, 255, 255), (180, 220, 255, 255)
    # a winged boot: shaft, foot pointing right, dark sole, and a three-feather wing on the heel
    p.rect((48, 22, 82, 92), r=8, fill=boot)
    p.poly([(48, 64), (96, 70), (114, 82), (114, 100), (48, 100)], fill=boot)
    p.rect((44, 16, 86, 30), r=5, fill=(190, 140, 90, 255))
    p.rect((42, 96, 118, 110), r=6, fill=sole)
    for (x0, y0), (x1, y1), col in (((54, 40), (18, 14), c), ((54, 50), (12, 38), c2), ((54, 60), (18, 62), c)):
        p.line([(x0, y0), (x1, y1)], 12, col)
    for y in (78, 92):
        p.line([(8, y), (30, y)], 5, (180, 220, 255, 190))


def em_medic(p):
    p.ellipse((14, 14, 114, 114), fill=WHITE)
    p.rect((50, 26, 78, 102), r=5, fill=(220, 50, 60, 255))
    p.rect((26, 50, 102, 78), r=5, fill=(220, 50, 60, 255))


def em_engineer(p):
    p.poly(star(64, 64, 52, 42, 9), fill=(150, 156, 166, 255))
    p.ellipse((26, 26, 102, 102), fill=(150, 156, 166, 255))
    p.ellipse((44, 44, 84, 84), fill=(0, 0, 0, 0))
    # wrench across the gear: handle bottom-left to the open jaw top-right
    p.line([(24, 104), (82, 46)], 16, GOLD)
    p.ellipse((70, 14, 114, 58), fill=GOLD)
    p.poly([(92, 36), (128, 0), (128, 30), (106, 50)], fill=(0, 0, 0, 0))
    p.ellipse((86, 28, 100, 42), fill=(0, 0, 0, 0))


def em_berserker(p):
    wood = (140, 95, 55, 255)
    p.line([(64, 14), (64, 116)], 10, wood)
    for s in (-1, 1):
        p.poly([(64, 28), (64 + s * 46, 12), (64 + s * 54, 44), (64 + s * 46, 76), (64, 60)], fill=STEEL)
        p.poly([(64 + s * 46, 12), (64 + s * 54, 44), (64 + s * 46, 76), (64 + s * 40, 44)], fill=WHITE)
    p.rect((56, 26, 72, 62), r=3, fill=(110, 114, 124, 255))
    p.poly(star(64, 10, 8, 4, 4), fill=STEEL)


def em_mage(p):
    hat, band = (130, 90, 220, 255), (255, 205, 60, 255)
    p.poly([(20, 98), (56, 50), (74, 14), (96, 4), (84, 26), (86, 60), (108, 98)], fill=hat)
    p.ellipse((10, 88, 118, 114), fill=hat)
    p.poly([(28, 92), (100, 92), (96, 80), (32, 80)], fill=band)
    p.poly(star(64, 58, 13, 5, 5), fill=(255, 240, 160, 255))
    p.poly(star(30, 40, 8, 3, 4), fill=(255, 240, 160, 255))
    p.poly(star(104, 52, 6, 2, 4), fill=(255, 240, 160, 255))


def em_pyro(p):
    flame(p, 64, 108, 78, 100, outer=(255, 110, 30, 255), inner=(255, 215, 80, 255))


def em_sniper(p):
    c = (240, 240, 240, 255)
    p.ellipse((18, 18, 110, 110), outline=c, width=8)
    p.ellipse((44, 44, 84, 84), outline=RED, width=4)
    for a, b in (((64, 8), (64, 46)), ((64, 82), (64, 120)), ((8, 64), (46, 64)), ((82, 64), (120, 64))):
        p.line([a, b], 6, c)
    p.ellipse((60, 60, 68, 68), fill=RED)


def em_demolisher(p):
    p.ellipse((14, 34, 100, 120), fill=(50, 52, 62, 255))
    p.ellipse((30, 50, 52, 72), fill=(130, 132, 145, 255))
    p.rect((56, 26, 84, 46), r=4, fill=STEEL)
    p.arc((70, 6, 110, 46), 180, 300, 6, (200, 170, 120, 255))
    p.poly(star(104, 18, 18, 7, 7), fill=(255, 130, 40, 255))
    p.poly(star(104, 18, 10, 4, 6), fill=GOLD)


# ---- Weapon icons (weapon_<Name> from Weapons.luau): side-view silhouettes pointing right, on a transparent
# background with a dark outline so they read on the HUD's dark weapon-slot buttons. Melee weapons are drawn upright
# or level and then rotated to a diagonal so they fill the square.
WP = 32  # the weapon layer reaches WP units past each side of the 128 grid, so a part may stick out before rotating


class WPen(Pen):
    """A Pen whose layer is 128 + 2*WP units wide; coordinates stay on the 0..128 grid of the final icon."""

    def __init__(self):
        n = (S + 2 * WP) * K
        self.im = Image.new("RGBA", (n, n), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)

    def _b(self, box):
        return [(v + WP) * K for v in box]

    def _p(self, pts):
        return [((x + WP) * K, (y + WP) * K) for x, y in pts]


def weapon(name, *layers, angle=0, outline=2.5, margin=4):
    """Each layer is a draw function (or (fn, False) for no outline, e.g. a glow). Layers are outlined in near-black
    and stacked in order, rotated `angle` degrees counter-clockwise, then scaled to fit the icon with `margin` units spare."""
    from PIL import ImageFilter

    n = (S + 2 * WP) * K
    out = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    size = int(outline * K) * 2 + 1
    for layer in layers:
        fn, edge = layer if isinstance(layer, tuple) else (layer, True)
        p = WPen()
        fn(p)
        if edge:
            ring = Image.new("RGBA", (n, n), (16, 18, 24, 0))
            ring.putalpha(p.im.getchannel("A").filter(ImageFilter.MaxFilter(size)))
            out.alpha_composite(ring)
        out.alpha_composite(p.im)
    if angle:
        out = out.rotate(angle, resample=Image.BICUBIC, expand=True)
    # fit the drawn weapon (outline included) into the icon with a small margin, centred
    out = out.crop(out.getbbox())
    box = (S - 2 * margin) * K
    f = min(box / out.width, box / out.height)
    out = out.resize((round(out.width * f), round(out.height * f)), Image.LANCZOS)
    icon = Image.new("RGBA", (S * K, S * K), (0, 0, 0, 0))
    icon.alpha_composite(out, ((S * K - out.width) // 2, (S * K - out.height) // 2))
    save(icon.resize((S, S), Image.LANCZOS), "weapon_" + name)


def shade(c, f):
    return (min(255, int(c[0] * f)), min(255, int(c[1] * f)), min(255, int(c[2] * f)), c[3] if len(c) > 3 else 255)


def part(p, box, c, r=0):
    """A rounded box with a lighter top band and a darker bottom band."""
    x0, y0, x1, y1 = box
    h = y1 - y0
    p.rect(box, r=r, fill=shade(c, 0.72))
    p.rect((x0, y0, x1, y1 - h * 0.22), r=r, fill=c)
    p.rect((x0 + min(r, 2), y0, x1 - min(r, 2), y0 + max(1.5, h * 0.25)), r=min(r, 1.5), fill=shade(c, 1.35))


GUN, TAN = (128, 134, 148, 255), (190, 160, 110, 255)
WOOD, LEATHER = (176, 110, 58, 255), (120, 78, 48, 255)
BLADE = (206, 214, 226, 255)
INK = (24, 26, 32, 255)


def trigger_guard(p, x0, x1, y, c=GUN):
    p.line([(x0, y), (x0 + 2, y + 8), (x1, y + 8), (x1, y)], 2.5, c)


def wp_assault_rifle(p):
    p.poly([(4, 52), (16, 50), (32, 53), (32, 65), (18, 70), (8, 80), (4, 80)], fill=TAN)
    p.poly([(4, 52), (16, 50), (32, 53), (32, 57), (4, 57)], fill=shade(TAN, 1.25))
    p.rect((2, 49, 7, 82), r=1.5, fill=shade(GUN, 0.55))
    p.poly([(36, 63), (48, 63), (44, 88), (32, 86)], fill=shade(TAN, 0.85))
    p.poly([(56, 63), (70, 63), (77, 92), (64, 96)], fill=shade(GUN, 0.7))
    p.line([(62, 68), (68, 90)], 2, shade(GUN, 0.95))
    trigger_guard(p, 47, 56, 64)
    part(p, (30, 46, 88, 64), GUN, r=2)
    p.rect((50, 51, 66, 55), r=1, fill=INK)
    p.rect((40, 38, 64, 43), r=1.5, fill=GUN)
    for x in (42, 58):
        p.rect((x, 41, x + 4, 47), fill=GUN)
    part(p, (86, 47, 110, 62), TAN, r=3)
    for x in (91, 98, 105):
        p.rect((x - 1.5, 53, x + 1.5, 58), r=1, fill=shade(TAN, 0.6))
    p.poly([(101, 47), (104, 37), (108, 37), (108, 47)], fill=GUN)
    p.rect((108, 51, 120, 57), fill=shade(GUN, 0.8))
    p.rect((117, 49, 126, 59), r=1.5, fill=GUN)


def wp_shotgun(p):
    p.poly([(2, 57), (38, 53), (38, 66), (30, 68), (22, 77), (4, 85), (2, 85)], fill=WOOD)
    p.poly([(2, 57), (38, 53), (38, 58), (2, 62)], fill=shade(WOOD, 1.25))
    p.rect((1, 55, 6, 86), r=1.5, fill=INK)
    trigger_guard(p, 40, 52, 65)
    part(p, (36, 50, 64, 66), GUN, r=2)
    p.rect((62, 61, 112, 66), r=2, fill=shade(GUN, 0.75))
    part(p, (62, 50, 126, 57), GUN, r=1.5)
    p.ellipse((119, 46, 124, 51), fill=GOLD)
    part(p, (72, 58, 102, 70), WOOD, r=3)
    for x in (78, 84, 90, 96):
        p.line([(x, 61), (x, 67)], 1.6, shade(WOOD, 0.6))


def pistol(p, x, y, c):
    """A pistol 78 units long with its slide's top-left corner at (x, y)."""
    p.poly([(x + 6, y + 18), (x + 24, y + 18), (x + 20, y + 52), (x + 2, y + 50)], fill=shade(c, 0.6))
    p.rect((x + 6, y + 22, x + 18, y + 46), r=2, fill=shade(c, 0.45))
    p.line([(x + 24, y + 18), (x + 26, y + 28), (x + 38, y + 28), (x + 40, y + 18)], 2.5, c)
    p.rect((x + 4, y + 14, x + 66, y + 22), r=2, fill=shade(c, 0.8))
    part(p, (x, y, x + 78, y + 16), c, r=2.5)
    for i in range(4):
        p.line([(x + 6 + i * 4, y + 4), (x + 6 + i * 4, y + 12)], 1.4, shade(c, 0.6))
    p.rect((x + 72, y - 3, x + 75, y), fill=c)


def wp_dual_pistols(p):
    pistol(p, 4, 24, (110, 116, 130, 255))


def wp_dual_pistols_front(p):
    pistol(p, 44, 52, (196, 202, 212, 255))


def wp_smg(p):
    p.line([(8, 50), (30, 50)], 3, GUN, joint=None)
    p.line([(8, 50), (8, 68), (30, 64)], 3, GUN)
    p.poly([(56, 62), (68, 62), (71, 114), (59, 114)], fill=shade(GUN, 0.65))
    p.line([(62, 68), (64, 108)], 2, shade(GUN, 0.9))
    p.poly([(32, 62), (45, 62), (42, 88), (29, 86)], fill=shade(GUN, 0.6))
    trigger_guard(p, 44, 54, 62)
    p.rect((80, 60, 89, 82), r=3, fill=shade(GUN, 0.6))
    part(p, (28, 44, 94, 63), GUN, r=3)
    p.rect((36, 38, 44, 45), r=1, fill=GUN)
    p.rect((84, 39, 88, 45), fill=GUN)
    part(p, (92, 47, 116, 59), shade(GUN, 0.8), r=2)
    for x in (97, 103, 109):
        p.ellipse((x - 1.6, 51.4, x + 1.6, 54.6), fill=INK)
    p.rect((114, 50, 122, 56), r=1, fill=GUN)


def wp_flamethrower(p):
    red, hi = (214, 52, 40, 255), (255, 120, 100, 255)
    p.line([(46, 84), (14, 78), (12, 58), (24, 54)], 4, INK)
    p.poly([(24, 58), (36, 58), (33, 84), (21, 82)], fill=shade(GUN, 0.6))
    part(p, (40, 62, 90, 88), red, r=12)
    p.rect((48, 65, 82, 69), r=2, fill=hi)
    for x in (50, 78):
        p.rect((x, 63, x + 3, 87), fill=shade(red, 0.6))
    p.ellipse((80, 54, 92, 66), fill=STEEL)
    p.ellipse((83, 57, 89, 63), fill=INK)
    part(p, (20, 46, 98, 60), GUN, r=3)
    for x in (56, 72):
        p.rect((x, 46, x + 5, 60), fill=red)
    p.poly([(96, 44), (114, 40), (114, 64), (96, 62)], fill=shade(GUN, 0.75))
    p.rect((112, 38, 118, 66), r=2, fill=GUN)


def wp_flamethrower_fire(p):
    p.ellipse((114, 44, 126, 60), fill=(255, 120, 30, 255))
    p.ellipse((116, 48, 123, 56), fill=(255, 220, 90, 255))


def wp_bolt_rifle(p):
    p.poly([(2, 58), (30, 56), (46, 60), (46, 70), (36, 70), (22, 78), (4, 84), (2, 84)], fill=WOOD)
    p.poly([(2, 58), (30, 56), (46, 60), (46, 63), (2, 63)], fill=shade(WOOD, 1.25))
    p.rect((1, 56, 5, 85), r=1.5, fill=INK)
    trigger_guard(p, 48, 58, 68)
    part(p, (64, 57, 126, 62), GUN, r=1.5)
    part(p, (44, 60, 104, 69), WOOD, r=3)
    part(p, (38, 55, 70, 61), GUN, r=1.5)
    p.line([(48, 60), (54, 68)], 2.5, GUN)
    p.ellipse((51, 65, 58, 72), fill=STEEL)
    for x in (50, 76):
        p.rect((x, 45, x + 4, 56), fill=GUN)
    dark = (70, 74, 86, 255)
    p.poly([(40, 40), (32, 37), (32, 50), (40, 48)], fill=dark)
    part(p, (38, 40, 88, 48), dark, r=2)
    p.poly([(86, 40), (98, 35), (98, 53), (86, 48)], fill=dark)
    p.rect((60, 35, 67, 40), r=1, fill=dark)
    p.rect((95, 37, 99, 51), r=1, fill=(120, 200, 255, 255))


def wp_grenade_launcher(p):
    olive = (112, 128, 76, 255)
    p.poly([(4, 50), (36, 48), (36, 64), (4, 76)], fill=shade(GUN, 0.8))
    p.rect((2, 48, 7, 78), r=1.5, fill=INK)
    p.poly([(44, 68), (57, 68), (53, 98), (40, 96)], fill=shade(GUN, 0.6))
    trigger_guard(p, 56, 68, 70)
    p.rect((80, 68, 90, 92), r=3, fill=shade(GUN, 0.6))
    p.poly([(62, 40), (65, 28), (74, 28), (74, 40)], fill=GUN)
    part(p, (32, 38, 112, 72), olive, r=7)
    p.rect((88, 38, 95, 72), fill=GOLD)
    part(p, (108, 35, 122, 75), GUN, r=3)
    p.rect((114, 42, 118, 68), r=1.5, fill=INK)


def wp_flail(p):
    p.line([(14, 118), (42, 90)], 11, WOOD)
    p.line([(18, 114), (30, 102)], 11, LEATHER)
    p.ellipse((8, 112, 22, 126), fill=GUN)
    p.ellipse((38, 82, 50, 94), fill=GUN)
    for i in range(5):
        t = i / 4
        x, y = 46 + 26 * t, 86 - 26 * t
        if i % 2 == 0:
            p.ellipse((x - 5, y - 3, x + 5, y + 3), outline=STEEL, width=2.5)
        else:
            p.ellipse((x - 3, y - 5, x + 3, y + 5), outline=STEEL, width=2.5)
    p.poly(star(90, 40, 34, 18, 8), fill=(110, 116, 128, 255))
    p.ellipse((70, 20, 110, 60), fill=(130, 136, 148, 255))
    p.ellipse((78, 26, 92, 40), fill=(190, 196, 206, 255))


def wp_great_axe(p):
    p.line([(64, 6), (64, 126)], 8, WOOD)
    p.line([(64, 100), (64, 124)], 8, LEATHER)
    for s in (-1, 1):
        edge = [(64 + s * 34, 6), (64 + s * 44, 18), (64 + s * 50, 38), (64 + s * 44, 58), (64 + s * 34, 70)]
        p.poly([(64, 26)] + edge + [(64, 50)], fill=STEEL)
        p.poly(edge + [(64 + s * 40, 58), (64 + s * 44, 38), (64 + s * 38, 18)], fill=(236, 240, 246, 255))
    p.rect((57, 22, 71, 54), r=3, fill=(100, 104, 116, 255))
    p.poly([(59, 22), (64, 4), (69, 22)], fill=STEEL)


def wp_staff(p):
    p.line([(64, 124), (64, 44)], 8, (130, 86, 48, 255))
    for y in (60, 100):
        p.rect((59, y, 69, y + 5), r=1.5, fill=GOLD)
    for s in (-1, 1):
        p.line([(64, 50), (64 + s * 15, 38), (64 + s * 12, 18)], 4.5, GOLD)


def wp_staff_glow(p):
    p.ellipse((30, -4, 98, 64), fill=(190, 110, 255, 60))
    p.ellipse((38, 4, 90, 56), fill=(190, 110, 255, 90))


def wp_staff_orb(p):
    p.ellipse((48, 14, 80, 46), fill=(160, 80, 250, 255))
    p.ellipse((52, 18, 76, 42), fill=(200, 140, 255, 255))
    p.ellipse((55, 20, 65, 30), fill=(250, 235, 255, 255))


def wp_combat_knife(p):
    p.poly([(4, 58), (46, 58), (46, 72), (40, 75), (35, 71), (29, 75), (23, 71), (17, 75), (10, 72), (4, 72)], fill=(66, 72, 62, 255))
    p.rect((6, 60, 44, 63), r=1.5, fill=(100, 108, 94, 255))
    p.rect((0, 57, 7, 73), r=2, fill=GUN)
    p.rect((44, 51, 51, 79), r=2, fill=shade(GUN, 0.8))
    p.poly([(50, 57), (100, 57), (112, 60), (128, 66), (116, 72), (100, 75), (50, 75)], fill=BLADE)
    p.poly([(50, 57), (100, 57), (112, 60), (128, 66), (50, 64)], fill=(160, 168, 182, 255))
    for i in range(6):
        x = 58 + i * 6
        p.poly([(x, 56.5), (x + 3, 61), (x + 6, 56.5)], fill=INK)
    p.line([(52, 72), (100, 72), (118, 68)], 2, (245, 248, 252, 255))


def wp_karambit(p):
    p.ellipse((4, 58, 34, 88), outline=GUN, width=6)
    p.poly([(30, 62), (78, 56), (82, 72), (32, 82)], fill=(66, 72, 62, 255))
    p.line([(34, 66), (76, 61)], 2, (100, 108, 94, 255))
    for x, y in ((46, 70), (66, 66)):
        p.ellipse((x - 2.5, y - 2.5, x + 2.5, y + 2.5), fill=STEEL)
    spine = [(76, 56), (90, 46), (106, 43), (119, 49), (126, 62), (126, 80), (121, 96)]
    inner = [(116, 80), (114, 68), (108, 60), (98, 60), (88, 66), (82, 74)]
    p.poly(spine + inner, fill=BLADE)
    p.poly(spine[:5] + [(118, 58), (108, 52), (96, 52), (84, 58)], fill=(160, 168, 182, 255))
    p.line([(121, 92), (116, 78), (112, 68), (104, 62), (94, 63), (86, 70)], 2, (245, 248, 252, 255))


def wp_scalpel(p):
    p.rect((-6, 59, 82, 69), r=3, fill=(176, 186, 200, 255))
    p.rect((-4, 60, 80, 63), r=1.5, fill=(220, 228, 238, 255))
    for x in range(8, 40, 5):
        p.line([(x, 61), (x, 67)], 1.2, (120, 130, 146, 255))
    p.rect((44, 61, 70, 67), r=2, fill=(80, 200, 180, 255))
    p.poly([(80, 61), (100, 59), (114, 61), (124, 65), (114, 71), (96, 72), (80, 67)], fill=(236, 242, 250, 255))
    p.poly([(80, 61), (100, 59), (114, 61), (124, 65), (80, 64)], fill=(190, 200, 214, 255))


def wp_hammer(p):
    p.line([(64, 44), (64, 124)], 10, WOOD)
    p.line([(64, 96), (64, 124)], 10, LEATHER)
    for y in (102, 110, 118):
        p.line([(59, y), (69, y - 3)], 1.5, shade(LEATHER, 0.6))
    part(p, (28, 16, 100, 46), STEEL, r=3)
    p.rect((56, 16, 72, 46), fill=(110, 114, 126, 255))
    for x0 in (24, 96):
        part(p, (x0, 12, x0 + 8, 50), (150, 156, 168, 255), r=2)


def wp_sword(p):
    p.ellipse((-18, 57, -4, 71), fill=GOLD)
    p.rect((-6, 59, 22, 69), r=2, fill=LEATHER)
    for x in (0, 7, 14):
        p.line([(x, 60), (x + 4, 68)], 1.5, shade(LEATHER, 0.6))
    part(p, (20, 46, 29, 82), GOLD, r=3)
    p.poly([(29, 57), (130, 57), (148, 64), (130, 71), (29, 71)], fill=BLADE)
    p.poly([(29, 57), (130, 57), (148, 64), (29, 64)], fill=(236, 240, 248, 255))
    p.line([(34, 64), (120, 64)], 2, (140, 150, 166, 255))


def wp_dagger(p):
    p.ellipse((2, 55, 18, 73), fill=GOLD)
    p.ellipse((6, 59, 14, 69), fill=(220, 40, 60, 255))
    p.rect((15, 59, 40, 69), r=2, fill=(90, 56, 40, 255))
    p.poly([(38, 46), (46, 50), (46, 78), (38, 82), (42, 64)], fill=GOLD)
    p.poly([(46, 56), (86, 51), (124, 64), (86, 77), (46, 72)], fill=BLADE)
    p.poly([(46, 56), (86, 51), (124, 64), (46, 64)], fill=(236, 240, 248, 255))
    p.line([(48, 64), (118, 64)], 1.8, (140, 150, 166, 255))


def wp_machete(p):
    p.rect((-8, 58, 32, 72), r=4, fill=(52, 52, 60, 255))
    for x in (2, 18):
        p.ellipse((x - 2.5, 62.5, x + 2.5, 67.5), fill=STEEL)
    p.poly([(30, 55), (116, 50), (138, 52), (148, 60), (134, 76), (110, 82), (30, 76)], fill=(186, 192, 202, 255))
    p.poly([(30, 55), (116, 50), (138, 52), (148, 60), (30, 62)], fill=(150, 156, 168, 255))
    p.line([(32, 74), (110, 80), (134, 74), (146, 61)], 2.5, (245, 248, 252, 255))


def wp_hatchet(p):
    p.poly([(59, 40), (69, 40), (71, 124), (59, 124)], fill=WOOD)
    p.poly([(59, 40), (63, 40), (62, 124), (59, 124)], fill=shade(WOOD, 1.25))
    p.poly([(52, 24), (72, 24), (78, 30), (100, 16), (108, 36), (106, 58), (98, 70), (80, 50), (72, 54), (52, 54)], fill=STEEL)
    p.poly([(100, 16), (108, 36), (106, 58), (98, 70), (98, 56), (102, 36)], fill=(240, 244, 250, 255))
    p.rect((46, 26, 56, 52), r=2, fill=(120, 124, 136, 255))


weapon("AssaultRifle", wp_assault_rifle)
weapon("Shotgun", wp_shotgun)
weapon("DualPistols", wp_dual_pistols, wp_dual_pistols_front)
weapon("SMG", wp_smg)
weapon("Flamethrower", wp_flamethrower, wp_flamethrower_fire)
weapon("BoltRifle", wp_bolt_rifle)
weapon("GrenadeLauncher", wp_grenade_launcher)
weapon("Flail", wp_flail)
weapon("GreatAxe", wp_great_axe, angle=-30)
weapon("Staff", (wp_staff_glow, False), wp_staff, wp_staff_orb, angle=-30)
weapon("CombatKnife", wp_combat_knife, angle=40)
weapon("Karambit", wp_karambit)
weapon("Scalpel", wp_scalpel, angle=40)
weapon("Hammer", wp_hammer, angle=-30)
weapon("Sword", wp_sword, angle=45)
weapon("Dagger", wp_dagger, angle=45)
weapon("Machete", wp_machete, angle=40)
weapon("Hatchet", wp_hatchet, angle=-30)

for fn in (heart, speed, damage, coin, wave, skull, trophy, gem, ammo, reload_icon):
    fn()
for name, fn in list(globals().items()):
    if name.startswith("sk_") and callable(fn):
        fn()
for cls in CLASS_TINT:
    emblem(cls, globals()["em_" + cls.lower()])
(CLASS_OUT / "LICENSE.txt").write_text("Class emblems drawn by scripts/make-icons.py for this project. CC0 1.0.\n")
(OUT / "LICENSE.txt").write_text("Stat, currency, skill and weapon icons drawn by scripts/make-icons.py for this project. CC0 1.0.\n")
print("icons written to", OUT)
