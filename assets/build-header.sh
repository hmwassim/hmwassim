#!/bin/sh
# Rebuilds header.svg from header.src.svg: embeds the JetBrains Mono Nerd Font
# glyphs it uses, so it renders the same without the font installed.
# Needs Docker and JetBrains Mono Nerd Font Mono (FONTS: the folder of its .ttf files).
set -eu
cd "$(dirname "$0")"
fonts=${FONTS:-/usr/share/fonts/truetype/fonts-nerd-jetbrains-mono}
docker run --rm -v "$fonts":/fonts:ro -v "$PWD":/work -w /work debian:13 sh -ec '
	apt-get update -qq >/dev/null && apt-get install -qq -y --no-install-recommends python3-fonttools python3-brotli >/dev/null 2>&1
	python3 - <<PY
import base64, re, io
from fontTools import subset
from fontTools.ttLib import TTFont
src = open("header.src.svg", encoding="utf-8").read()
text = "".join(sorted(set("".join(re.findall(r">([^<]*)<", src))) | {" "}))
out = {}
for key, name in (("REGULAR", "Regular"), ("BOLD", "Bold")):
    f = TTFont("/fonts/JetBrainsMonoNerdFontMono-%s.ttf" % name)
    o = subset.Options(); o.flavor = "woff2"; o.layout_features = []; o.name_IDs = ["*"]; o.notdef_outline = True
    s = subset.Subsetter(o); s.populate(text=text); s.subset(f)
    b = io.BytesIO(); f.flavor = "woff2"; f.save(b)
    out[key] = base64.b64encode(b.getvalue()).decode()
open("header.svg", "w", encoding="utf-8").write(src.replace("@REGULAR@", out["REGULAR"]).replace("@BOLD@", out["BOLD"]))
PY
	chown '"$(id -u):$(id -g)"' header.svg'
echo "header.svg rebuilt"
