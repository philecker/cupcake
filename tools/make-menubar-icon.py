# Regenerates the menu bar icons from the app icon, thickening the cupcake's outer outline by
# `extra_px` (measured at @2x). Needs Pillow, NumPy, SciPy.
#   Resources/cupcakeTemplate.png (+@2x)        the normal icon
#   Resources/cupcakeFilledTemplate.png (+@2x)  frosting filled in (with a thin gap), flashed after copying
import sys
from PIL import Image
import numpy as np
from scipy import ndimage as ndi

src = np.array(Image.open(sys.argv[1]).convert('RGB').crop((150, 120, 874, 904))).astype(int)  # cupcake only, not the icon rim
R, G, B = src[..., 0], src[..., 1], src[..., 2]
glyph = (G > 200) & (R < 170)                      # the light-green cupcake strokes
ys, xs = np.nonzero(glyph)
glyph = glyph[ys.min():ys.max()+1, xs.min():xs.max()+1]
silhouette = ndi.binary_fill_holes(glyph)
gh, gw = glyph.shape

# The enclosed regions inside the outline: the three frosting tiers sit in the top ~65% of the
# cupcake, the gaps between the wrapper's pleats below that.
_holes, _n = ndi.label(silhouette & ~glyph)
frosting = np.zeros_like(glyph)
for _i in range(1, _n + 1):
    _ys, _ = np.nonzero(_holes == _i)
    if _ys.mean() < gh * 0.65:
        frosting |= _holes == _i

def filled_glyph(gap_px=0):
    """Glyph with the frosting filled in. gap_px > 0 keeps a thin gap inside each tier's outline."""
    fill = frosting
    if gap_px > 0:
        fill = ndi.binary_erosion(frosting, iterations=gap_px)
    return glyph | fill

def make(extra_px_at_2x, out_prefix, glyph=glyph):
    # Final 2x canvas is 32px; glyph height ~ (32 - margins). Convert extra px to source px.
    pad = 1.0                                        # px margin at 2x
    # thickness grows outward, so leave room for it inside the canvas
    avail = 32 - 2*pad
    scale = avail / (max(gh, gw) + 2 * extra_px_at_2x * max(gh, gw) / avail)
    r = int(round(extra_px_at_2x / scale))
    if r > 0:
        yy, xx = np.ogrid[-r:r+1, -r:r+1]
        disk = xx*xx + yy*yy <= r*r
        grown = ndi.binary_dilation(np.pad(silhouette, r), structure=disk)
        shape = np.pad(glyph, r) | (grown & ~np.pad(silhouette, r))
    else:
        shape = glyph
    h, w = shape.shape
    side = max(h, w)
    canvas = np.zeros((side, side), bool)
    canvas[(side-h)//2:(side-h)//2+h, (side-w)//2:(side-w)//2+w] = shape
    img = Image.fromarray((canvas*255).astype(np.uint8))
    for size, name in [(16, ''), (32, '@2x')]:
        inner = round(size * avail / 32)
        a = img.resize((inner, inner), Image.LANCZOS)
        out = Image.new('L', (size, size), 0)
        out.paste(a, ((size-inner)//2, (size-inner)//2))
        rgba = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        rgba.putalpha(out)
        rgba.save(f'{out_prefix}{name}.png')

if __name__ == '__main__':
    # Usage: python3 tools/make-menubar-icon.py Resources/AppIcon.png [extra_px]
    extra = float(sys.argv[2]) if len(sys.argv) > 2 else 1.0
    make(extra, 'Resources/cupcakeTemplate')
    # Frosting filled with a thin gap kept inside each tier's outline (22 source px ≈ 1px at @2x)
    make(extra, 'Resources/cupcakeFilledTemplate', glyph=filled_glyph(gap_px=22))
