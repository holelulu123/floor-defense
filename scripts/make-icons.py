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


for fn in (heart, speed, damage, coin, wave, skull):
    fn()
(OUT / "LICENSE.txt").write_text("Stat icons drawn by scripts/make-icons.py for this project. CC0 1.0.\n")
print("icons written to", OUT)
