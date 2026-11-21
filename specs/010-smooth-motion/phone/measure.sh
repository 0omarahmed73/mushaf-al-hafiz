#!/usr/bin/env bash
# Feature 010: the phone measurement of page swipes (specs/010-smooth-motion/quickstart.md, "On the phone").
#
# NEVER RUN THIS WITHOUT THE OWNER'S APPROVAL IN THAT SESSION. It sends touch input to the owner's phone with
# `adb shell input swipe`; the phone must be unlocked by the owner and the app already open on the reader, in the mode
# being measured. It installs nothing, changes no setting and writes nothing but files under the output folder.
#
#   measure.sh --approved-by-owner [--serial <phone>] [--swipes 50] [--out DIR] --label before|after \
#              --pace slow|normal|fast [--and-back]
#
# Pace: slow = one swipe, then 1.2 s of rest (the usual reading); normal = 0.6 s; fast = 0.25 s (flipping).
# Browse mode keeps the wird position still (jump to a page from the index first); for the wird-mode run the script
# swipes N pages forward and then N pages back (--and-back), so the position ends where it started.
set -euo pipefail

SERIAL="<phone>"; SWIPES=50; OUT=""; LABEL="run"; PACE="normal"; APPROVED=0; BACK=0
while [ $# -gt 0 ]; do
  case "$1" in
    --approved-by-owner) APPROVED=1 ;;
    --serial) SERIAL="$2"; shift ;;
    --swipes) SWIPES="$2"; shift ;;
    --out) OUT="$2"; shift ;;
    --label) LABEL="$2"; shift ;;
    --pace) PACE="$2"; shift ;;
    --and-back) BACK=1 ;;
    *) echo "unknown option $1" >&2; exit 2 ;;
  esac
  shift
done
if [ "$APPROVED" != 1 ]; then
  echo "Refusing to run: this sends touch input to the owner's phone. Ask the owner first, then pass --approved-by-owner." >&2
  exit 3
fi
case "$PACE" in slow) REST=1.2 ;; normal) REST=0.6 ;; fast) REST=0.25 ;; *) echo "pace: slow|normal|fast" >&2; exit 2 ;; esac
OUT="${OUT:-$(dirname "$0")/results/$(date +%Y%m%d-%H%M%S)-$LABEL-$PACE}"
mkdir -p "$OUT"
ADB=(adb -s "$SERIAL")

# 1. What the phone is: model, Android, screen size, refresh rate in use (the frame budget comes from it).
{
  echo "model: $("${ADB[@]}" shell getprop ro.product.model | tr -d '\r')"
  echo "android: $("${ADB[@]}" shell getprop ro.build.version.release | tr -d '\r')"
  echo "size: $("${ADB[@]}" shell wm size | tr -d '\r')"
  "${ADB[@]}" shell dumpsys display | grep -iE "refreshRate|fps|mActiveMode|DisplayModeRecord" | head -12 | tr -d '\r'
  "${ADB[@]}" shell dumpsys package app.hafiz.mushaf | grep -E "versionName|versionCode|lastUpdateTime" | tr -d '\r'
} > "$OUT/device.txt"

# 2. Start clean: the app's own frame trace in the log and the system's counters.
"${ADB[@]}" logcat -c
"${ADB[@]}" shell dumpsys gfxinfo app.hafiz.mushaf reset > /dev/null || true

# 3. The swipes: a finger moving left to right brings the next page (Constitution VI). Screen is read from `wm size`.
SIZE=$("${ADB[@]}" shell wm size | tr -d '\r' | sed -n 's/.*: \([0-9]*\)x\([0-9]*\).*/\1 \2/p' | tail -1)
W=${SIZE% *}; H=${SIZE#* }
Y=$((H / 2)); X1=$((W * 15 / 100)); X2=$((W * 85 / 100))
swipe() { "${ADB[@]}" shell input swipe "$1" "$Y" "$2" "$Y" 110; }
for i in $(seq 1 "$SWIPES"); do swipe "$X1" "$X2"; sleep "$REST"; done
if [ "$BACK" = 1 ]; then
  for i in $(seq 1 "$SWIPES"); do swipe "$X2" "$X1"; sleep "$REST"; done
fi
sleep 1

# 4. Collect.
"${ADB[@]}" logcat -d -s flutter > "$OUT/logcat-flutter.txt"
"${ADB[@]}" shell dumpsys gfxinfo app.hafiz.mushaf framestats > "$OUT/gfxinfo-framestats.txt" || true
"${ADB[@]}" shell dumpsys gfxinfo app.hafiz.mushaf > "$OUT/gfxinfo-summary.txt" || true
"${ADB[@]}" shell dumpsys SurfaceFlinger --latency-clear > /dev/null 2>&1 || true

# 5. Summarise (the frame trace first; gfxinfo as a cross-check, it may hold few frames for a Flutter app).
{
  echo "== FRAMETRACE (the build's own FrameTiming) =="
  python3 -I "$(dirname "$0")/summarise.py" frametrace "$OUT/logcat-flutter.txt" || true
  echo "== PAGETURN (time from the page being created to its text painted) =="
  grep -o 'PAGETURN page=[0-9]* ms=[0-9]*' "$OUT/logcat-flutter.txt" | sed 's/.*ms=//' | sort -n | awk '{a[NR]=$1} END {if (NR) printf "n=%d min=%d median=%d max=%d\n", NR, a[1], a[int((NR+1)/2)], a[NR]; else print "no PAGETURN lines (build without PAGE_TURN_TRACE?)"}'
  echo "== gfxinfo framestats (cross-check) =="
  python3 -I "$(dirname "$0")/summarise.py" framestats "$OUT/gfxinfo-framestats.txt" || true
} | tee "$OUT/summary.txt"
echo "saved in $OUT"
