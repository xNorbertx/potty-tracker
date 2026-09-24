# Google Play listing package

Open `preview.html` for the asset contact sheet. Copy is in `en-US/listing.md`.
No listing or policy questionnaire has been submitted to Play Console.

| File | Format / dimensions | Use |
| --- | --- | --- |
| `assets/icon-512.png` | 512 × 512 PNG | Existing app icon; no new branding |
| `assets/feature-graphic.png` | 1024 × 500 PNG | Play feature graphic |
| `assets/feature-graphic.svg` | Editable vector layout with existing embedded artwork | Source for the graphic |
| `assets/phone/01-diary.png` | 1080 × 2160 PNG | Calendar and a recorded poop |
| `assets/phone/02-log.png` | 1080 × 2160 PNG | Five illustrated consistencies |
| `assets/phone/03-achievements.png` | 1080 × 2160 PNG | Achievements and shared caregivers |
| `assets/phone/04-month-navigation.png` | 1080 × 2160 PNG | Jump to an older month |

The four captures use the **real Flutter widgets with fictional in-memory data**,
rendered by Flutter web at a 360 × 720 logical phone size, scaled 3×. They are not
Android-device captures. They have no added marketing text, fake UI or real
caregiver/child data. Compare them against the final signed Android build and
recapture on Android if platform rendering or controls differ before uploading.
Their 1:2 aspect ratio meets Play's basic screenshot limits; optional promotional
placements prefer 9:16 screenshots, which can be prepared after native-device QA.

To reproduce, run `tool/store_preview.dart` with `?capture=true`, open a 1080 × 2160
viewport and save **full-page** captures (viewport-only captures can be clipped by
the browser host). Use normal navigation for the log, baby overview and month
picker. `tool/build_store_graphic.py` recreates the icon copy and editable graphic;
open that SVG at 1024 × 500 and capture as PNG. No image-generation model was used;
all illustration assets already belong to this repository's approved design.

The app name, support address, free pricing, English-only release and intended
worldwide availability reflect the operator's decisions. Complete the outstanding
items in `docs/google-play-disclosures.md` before submitting to Google Play.

Asset requirements checked against [Google Play preview asset guidance](https://support.google.com/googleplay/android-developer/answer/9866151).
