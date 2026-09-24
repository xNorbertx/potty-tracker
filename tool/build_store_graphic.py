"""Build an editable store graphic from the app's existing brand artwork.

Open the generated SVG in a browser at 1024x500 and capture it as PNG.
No generated app UI or new illustration is substituted for the real product.
"""
from pathlib import Path
import base64
import shutil

root = Path(__file__).resolve().parents[1]
output = root / "store" / "assets"
output.mkdir(parents=True, exist_ok=True)
shutil.copyfile(root / "web/icons/Icon-512.png", output / "icon-512.png")
poop = base64.b64encode((root / "assets/branding/poop-emoji.png").read_bytes()).decode()
svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="500" viewBox="0 0 1024 500">
  <rect width="1024" height="500" fill="#fff8f0"/>
  <circle cx="856" cy="253" r="215" fill="#e5efda"/>
  <circle cx="1020" cy="0" r="100" fill="#f0eadb"/>
  <circle cx="591" cy="428" r="18" fill="#d1e5be"/>
  <circle cx="949" cy="415" r="10" fill="#9bbb83"/>
  <text x="64" y="182" fill="#285e2b" font-family="Arial, sans-serif" font-size="57" font-weight="700" letter-spacing="-2">Potty Tracker</text>
  <text x="67" y="248" fill="#435942" font-family="Arial, sans-serif" font-size="29">Every little poop,</text>
  <text x="67" y="290" fill="#435942" font-family="Arial, sans-serif" font-size="29">in one shared diary.</text>
  <rect x="67" y="341" width="42" height="5" rx="2.5" fill="#72a654"/>
  <image x="644" y="64" width="360" height="360" href="data:image/png;base64,{poop}"/>
</svg>'''
(output / "feature-graphic.svg").write_text(svg, encoding="utf-8")
print("Wrote store/assets/feature-graphic.svg and icon-512.png")
