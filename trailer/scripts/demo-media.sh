#!/usr/bin/env bash
# Makes stand-in footage and a click-track so the demo edits render with no
# real captures. Real takes come from scripts/capture-mac.sh + split-takes.mjs.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p public/demo
mk() { # name color label
  ffmpeg -loglevel error -y -f lavfi -i "testsrc2=size=1920x1080:rate=30:duration=6" \
    -f lavfi -i "color=c=$2:size=1920x1080:rate=30:duration=6" \
    -filter_complex "[0][1]blend=all_mode=overlay:all_opacity=0.7,drawtext=text='$3':fontcolor=white:fontsize=110:x=(w-text_w)/2:y=(h-text_h)/2:borderw=6:bordercolor=black" \
    -c:v libx264 -pix_fmt yuv420p -preset veryfast "public/demo/$1.mp4"
}
mk combo   0xff6a00 "TAKE combo"
mk ult     0x7a2cff "TAKE ultimate"
mk dash    0x00b4ff "TAKE dash"
mk boss    0xff2244 "TAKE boss"
mk arena   0x22cc88 "TAKE arena"
# 120 bpm click track with an accent on every bar, 20 s
ffmpeg -loglevel error -y -f lavfi \
  -i "aevalsrc='0.6*sin(2*PI*(if(lt(mod(t,2),0.06),880,440))*t)*exp(-40*mod(t,0.5))':s=44100:d=20" \
  -c:a pcm_s16le public/demo/click120.wav
echo "demo media in public/demo"
