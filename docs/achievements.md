# Baby achievements

Each baby shares three badges across caregivers: 7, 14 and 30 consecutive diary
days containing at least one entry. A streak earns each badge once; a 60-day
streak still earns one of each. A missed day ends that streak without removing
its awards. A later qualifying streak increments the badge's count.

The baby overview displays the selected Happy little poops artwork, subdued
unearned placeholders and earned counts. Counts derive from the diary, including
existing history and backdated additions. Multiple entries on a day count once.
Deleting the last entry for a day can split a streak and change badge counts;
backfilling can join streaks and also change counts.

Only membership changes in the entries list trigger the overview calculation.
Each entry stores its original calendar day in `achievementDay`; editing its
date, time, consistency or notes never changes its achievement contribution.
Legacy records use their displayed diary date, which is frozen on their first
edit. New entries retain the creation device's selected calendar date across
timezones; older records without a saved date retain the existing diary's local
timezone interpretation. Calendar comparisons use date-only UTC arithmetic to
avoid daylight-saving gaps, not UTC conversion of the selected diary day.

After an entry saves successfully, increased milestone counts are eligible for
a celebration. Multiple eligible badges share one dialog. A shared transaction
claims each milestone/date once, preventing simultaneous caregivers or a
delete/re-add correction from repeating that celebration. Reading existing
history, editing, and deleting do not trigger a dialog. Claim failures cannot
turn a successful diary save into an error or duplicate retry. These claims
are removed when the baby diary is deleted.

## Local visual preview

`flutter run -d web-server -t tool/achievement_preview.dart --web-port 8091`

This preview uses synthetic entries and never initializes Firebase. It shows
earned counts, placeholders and the celebration using the production widgets.

## Artwork

The three PNGs in `assets/achievements/` were generated using the built-in
imagegen tool from the user-selected C concept. No CLI/API fallback was used.
They are transparent, local app assets; the app does not load remote images.

Prompt template (one generation for each milestone):

> Extract/recreate ONLY the {7,14,30}-day sticker badge from the TOP row as ONE
> standalone production app asset. Preserve its cute smiling brown poop
> character, dark brown outline, pink cheeks, pale green backing, thick white
> sticker contour, and {one golden sparkle / two golden stars / golden crown
> and celebratory golden stars}. Preserve the exact large dark green numeral
> and smaller word "days" with white outline below the mascot. No other badge,
> UI, heading, count chip or separate caption. Genuinely transparent background
> with alpha; centered complete sticker with uniform padding on a square canvas.
