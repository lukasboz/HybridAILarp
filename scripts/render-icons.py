"""Render the repository's geometric mark into PNG app icons (Pillow)."""
from pathlib import Path
from PIL import Image, ImageDraw
import json

root=Path(__file__).resolve().parents[1]
colors=json.loads((root/"shared/design-tokens.json").read_text())["colors"]

SCALE = 2048 / 192
image = Image.new("RGB", (2048, 2048), colors["orb"])
draw = ImageDraw.Draw(image)
colour = colors["ink"]
width = round(10 * SCALE)

def stroke(points):
    points = [(round(x*SCALE), round(y*SCALE)) for x,y in points]
    draw.line(points, fill=colour, width=width, joint="curve")
    radius = width/2
    for x,y in [points[0], points[-1]]:
        draw.ellipse((x-radius,y-radius,x+radius,y+radius),fill=colour)

def curve(p0,p1,p2,p3):
    result=[]
    for i in range(65):
        t=i/64; u=1-t
        result.append((u**3*p0[0]+3*u*u*t*p1[0]+3*u*t*t*p2[0]+t**3*p3[0],u**3*p0[1]+3*u*u*t*p1[1]+3*u*t*t*p2[1]+t**3*p3[1]))
    return result

stroke([(39,126),(39,76)]+curve((39,76),(39,54),(73,54),(73,76))+[(73,126)])
stroke(curve((73,76),(73,54),(107,54),(107,76))+[(107,126)])
stroke([(124,44),(124,126)])
stroke(curve((124,84),(124,62),(155,62),(155,84))+[(155,126)])
for size in (192,512):
    image.resize((size,size),Image.Resampling.LANCZOS).save(root/f"web/assets/icon-{size}.png")
image.resize((1024,1024),Image.Resampling.LANCZOS).save(root/"native/ios/Resources/AppIcon.png")
flutter=root/"app"
if flutter.exists():
    icons=flutter/"ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for entry in json.loads((icons/"Contents.json").read_text())["images"]:
        size=round(float(entry["size"].split("x")[0])*float(entry["scale"].rstrip("x")))
        image.resize((size,size),Image.Resampling.LANCZOS).save(icons/entry["filename"])
    for density,size in [("mdpi",48),("hdpi",72),("xhdpi",96),("xxhdpi",144),("xxxhdpi",192)]:
        image.resize((size,size),Image.Resampling.LANCZOS).save(flutter/f"android/app/src/main/res/mipmap-{density}/ic_launcher.png")
    for name,size in [("Icon-192.png",192),("Icon-maskable-192.png",192),("Icon-512.png",512),("Icon-maskable-512.png",512)]:
        image.resize((size,size),Image.Resampling.LANCZOS).save(flutter/"web/icons"/name)
    image.resize((192,192),Image.Resampling.LANCZOS).save(flutter/"web/favicon.png")
print("Rendered the shared geometric app mark for web, Flutter Android/iOS and the legacy iOS package.")
