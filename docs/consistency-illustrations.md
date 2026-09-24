# Consistency illustrations

The approved direction is A (clean and simple): five warm brown, faceless
illustrations with distinct silhouettes. Logging and diary entries use the same
assets. Colour remains a separate optional observation. Existing category values,
labels and historical entries are unchanged.

Assets: `assets/consistency/{hard,formed,pasty,soft,watery}.png`.
Generated using the built-in image generation tool, with the approved A comparison
sheet as the reference. Each file has a transparent background.

Prompt template (one generation per category):

> Use case: precise-object-edit. Create a production app asset from the approved
> reference sheet A — Clean & simple. Isolate ONLY [subject]. Preserve the shape,
> warm ochre-brown palette, clean flat illustration style and simple shading of
> that icon closely. Remove ALL other icons, ALL text, and the cream background.
> Genuine alpha transparent background, no white rectangle, no outline, no sticker
> border, no faces or props, no cast shadow. Single centered icon composition on
> square canvas with a modest 8% transparent margin, large readable silhouette for
> display at 40-48 logical pixels. Output a transparent PNG.

Subjects: first icon, six separate small hard pellets; second icon, one curved
rounded solid log; third icon, a smooth thick paste mound with a smear; fourth
icon, loose irregular mushy clumps; fifth icon, a thin puddle with two small
droplets.

Local preview (synthetic entries, no Firebase connection):
`flutter run -d web-server -t tool/consistency_preview.dart --web-port 8091`.
