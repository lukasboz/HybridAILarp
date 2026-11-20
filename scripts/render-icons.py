"""Render the repository's geometric mark into PNG app icons (Pillow)."""
from pathlib import Path
from PIL import Image, ImageDraw

SCALE = 2048 / 192
image = Image.new("RGB", (2048, 2048), "#f4effb")
draw = ImageDraw.Draw(image)
colour = "#946acb"
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
root=Path(__file__).resolve().parents[1]
for size in (192,512):
    image.resize((size,size),Image.Resampling.LANCZOS).save(root/f"web/assets/icon-{size}.png")
image.resize((1024,1024),Image.Resampling.LANCZOS).save(root/"native/ios/Resources/AppIcon.png")
print("Rendered web and iOS PNG icons from the geometric app mark.")
