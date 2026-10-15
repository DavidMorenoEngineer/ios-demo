#!/usr/bin/env bash
# Records the scripted tour on ONE simulator and exports mp4 + gif — no human input.
#   tool/record_demo.sh <simulator-udid> <phone|pad> [out-dir]
# Boot only the simulator you pass; the script refuses to run if another one is booted.
set -euo pipefail
DEVICE="${1:?usage: record_demo.sh <udid> <phone|pad> [out-dir]}"
KIND="${2:?phone or pad}"
OUT="${3:-docs/videos}"
case "$KIND" in
  phone) TEST="testPhoneTour"; WIDTH=540 ;;
  pad)   TEST="testPadTour";   WIDTH=720 ;;
  *) echo "kind must be phone or pad" >&2; exit 1 ;;
esac
RAW="$(mktemp -d)/raw_$KIND.mov"
LOG="$(mktemp)"; rm -f "$LOG"   # the UI test creates it
mkdir -p "$OUT"

OTHERS=$(xcrun simctl list devices booted | grep Booted | grep -vc "$DEVICE" || true)
if [ "$OTHERS" != "0" ]; then echo "Another simulator is booted — run one at a time." >&2; exit 1; fi
xcrun simctl boot "$DEVICE" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE" -b >/dev/null
xcrun simctl status_bar "$DEVICE" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3

xcodegen generate >/dev/null
# Build first so the recording does not include compile time.
xcodebuild build-for-testing -project SideKixDemo.xcodeproj -scheme SideKixDemo \
  -destination "platform=iOS Simulator,id=$DEVICE" -derivedDataPath DerivedBuild \
  -skipMacroValidation -skipPackagePluginValidation >/dev/null

# Start the recorder only when the tour begins and stop it just after it ends. A long
# pre-roll would let the recorder's clock drift away from wall time and mis-cut the video.
TEST_RUNNER_DEMO_MARKERS="$LOG" xcodebuild test-without-building -project SideKixDemo.xcodeproj \
  -scheme SideKixDemo -destination "platform=iOS Simulator,id=$DEVICE" -derivedDataPath DerivedBuild \
  -only-testing:"SideKixDemoUITests/DemoTourUITests/$TEST" > "$LOG.xcodebuild" 2>&1 &
XCB=$!

until grep -qs '^START' "$LOG" 2>/dev/null; do
  kill -0 "$XCB" 2>/dev/null || { echo "Test ended before the tour started:" >&2; grep -E "error:" "$LOG.xcodebuild" >&2; exit 1; }
  sleep 0.1
done
xcrun simctl io "$DEVICE" recordVideo --codec=h264 --force "$RAW" 2>/dev/null &
REC=$!
until grep -qs '^END' "$LOG" 2>/dev/null; do
  kill -0 "$XCB" 2>/dev/null || break
  sleep 0.1
done
sleep 1.5
kill -INT "$REC"; wait "$REC" 2>/dev/null || true
wait "$XCB" || { echo "UI test failed:" >&2; grep -E "error:" "$LOG.xcodebuild" >&2; exit 1; }
grep -qs '^END' "$LOG" || { echo "Tour did not complete." >&2; exit 1; }

# The recorder needs a moment to warm up; the tour opens on a still frame, so skip it.
SS=0.4
# Trim with filters (not -ss): simulator video is variable-frame-rate.
ffmpeg -v error -y -i "$RAW" \
  -vf "fps=30,trim=start=$SS,setpts=PTS-STARTPTS,scale=$WIDTH:-2" \
  -c:v libx264 -crf 26 -pix_fmt yuv420p -an "$OUT/demo-$KIND.mp4"
ffmpeg -v error -y -i "$OUT/demo-$KIND.mp4" \
  -vf "fps=8,scale=$((WIDTH/2)):-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=64[p];[b][p]paletteuse=dither=bayer:bayer_scale=5" \
  "$OUT/demo-$KIND.gif"
echo "Wrote $OUT/demo-$KIND.mp4 and $OUT/demo-$KIND.gif"
