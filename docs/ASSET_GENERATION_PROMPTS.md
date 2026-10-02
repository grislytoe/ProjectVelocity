# Reusable asset-generation prompts — M23

Generated raster is allowed only where painted texture/depth adds value. Exact icons, UI,
collision-aligned platforms/hazards and the modular robot remain SVG/Godot/code-native until a
controlled sprite-sheet pipeline replaces them. Built-in OpenAI ImageGen was used; no web
images, third-party assets, API keys or secrets were used.

## Integrated prompt and provenance

- Asset: `industrial_foundry_far_v1`
- Tool: OpenAI built-in image generation (`image_gen`), 2026-10-01
- Raw output: 1792×896 PNG outside the repository
- Integrated export: 1024×512 WebP, Lanczos resize, contrast 0.82, saturation 0.78, quality 84.
The raw generation was visually reviewed before export and is not committed.

Exact prompt:

```text
Use case: stylized-concept
Asset type: production game environment background plate for a 2D side-scrolling platform racer
Primary request: a cohesive distant Industrial + Brutalism foundry interior, made of massive concrete bays, steel ribs, shadowed ventilation stacks, restrained pipes and gantries, with a clear left-to-right directional rhythm
Scene/backdrop: cavernous factory interior viewed straight-on from the side, distant architectural layer only
Style/medium: clean high-resolution 2D painted environment plate, matte graphic realism, non-pixel-art, crisp large shapes with subtle material texture
Composition/framing: wide 2:1 panorama; no foreground floor, no platforms, no routes, no hazards, no characters; center and lower gameplay band remain quiet and low-detail; silhouettes repeat gently so the image can be cropped or tiled without a unique landmark
Lighting/mood: cool dark ambient light, sparse muted cyan practical lights, soft atmospheric depth; no bloom bursts
Color palette: charcoal #0B1117, slate #18232B, cold concrete #26343D, muted teal #2E6B70, tiny restrained warm amber accents #B58A46
Materials/textures: brushed steel, poured concrete, subtle grime, broad panels; texture stays understated at gameplay scale
Constraints: background presentation only; low contrast and low saturation; no collision-like bright ledges; no readable signs; no text; no logos; no symbols; no warning stripes; no red hazard colors; no characters; no vehicles; no sparks; no fire; no smoke clouds crossing the playfield; no watermark
Avoid: photorealistic clutter, cyberpunk neon, sci-fi city, strong focal point, sharp foreground edges, bright white lights, false platforms, UI elements, perspective floor, pixel art, 3D mockup
```

## Consistency workflow

1. Lock the palette/value hierarchy from `ART_DIRECTION.md`; never ask generation to invent a
   new palette or visual language.
2. Generate one role at a time. Keep environment plates free of gameplay objects and text.
3. Review at full size, then at the actual 1280×720 world target with a 64 px avatar overlay.
4. Reject first; edit only one problem per iteration. Do not composite rejected variants.
5. Crop/resize to the exact spec. Remove text, bright ledges, edge seams and alpha halos.
6. Compare normal, high-contrast and representative colorblind output. Verify hazard/route
   silhouettes with the asset enabled and disabled.
7. Export at ≤1024 edge, import in Godot, inspect normal renderer and measure decoded memory.
8. Record final prompt/tool/date/transform in the manifest; keep raw generations outside git.

## Future Foundry material prompt

```text
Use case: stylized-concept
Asset type: seamless 2D game material texture
Primary request: restrained poured brutalist concrete with broad formwork variation and sparse age marks
Style/medium: matte painted material, clean high-resolution non-pixel-art
Composition/framing: orthographic square swatch, perfectly seamless on all four edges, no unique focal mark
Lighting/mood: flat neutral material reference, no directional cast shadow
Color palette: #18232B, #26343D, #56626A; very low saturation
Materials/textures: broad concrete aggregate and subtle formwork; detail must survive reduction to 512×512
Constraints: no cracks resembling routes; no text; no numbers; no warning paint; no logos; no red; no cyan rail; no watermark
Avoid: photogrammetry glare, dramatic lighting, deep holes, strong edge lines, perspective, clutter
```

Acceptance: 512×512, seamless-difference inspection on every edge, no feature brighter than
the safe route edge, no high-frequency shimmer at 0.5× scale. Import linear + mipmaps + repeat.

## Future far silhouette variant prompt

```text
Use case: stylized-concept
Asset type: distant transparent environment cutout for a 2D side-scrolling game
Primary request: monumental brutalist concrete support bays and steel ventilation stacks in a sparse repeating rhythm
Style/medium: clean matte 2D environment silhouette, non-pixel-art
Composition/framing: wide 2:1 side elevation, structures contained inside frame, quiet lower third, generous transparent gaps
Lighting/mood: dark ambient silhouette with only tiny muted teal utility lights
Color palette: #0B1117, #18232B, #26343D, tiny #2E6B70
Constraints: genuinely transparent background; no floor; no walkable-looking ledges; no characters; no text; no logos; no hazards; no red; no white; no watermark
Avoid: neon cyberpunk, city skyline, dramatic focal point, perspective floor, dense pipes, smoke, sparks
```

Acceptance: true alpha, no matte fringe, 1024×512 maximum, lower-third readability check,
crop continuity. Use as presentation-only registry asset.

## Future character concept prompt (concept only)

Do not integrate generation output directly as animation frames. Use this to establish a
paint-over reference, then rebuild modules against the exact pivots in `ASSET_SPECIFICATION.md`.

```text
Use case: stylized-concept
Asset type: modular 2D game character production concept sheet
Primary request: compact clean techno android for a high-speed platform racer, rigid modular head, torso, paired arms and paired legs
Subject: athletic friendly machine, readable visor and emissive readiness markers, two replaceable color channels
Style/medium: crisp high-resolution 2D animation design, non-pixel-art, flat controlled shading
Composition/framing: front, side and three-quarter orthographic views plus separated modules; neutral pose; white/neutral background
Color palette: neutral slate body mask and white emissive mask so project body/accent colors can replace them
Constraints: consistent proportions; no squash-and-stretch; no weapons; no cape; no text; no logos; no background scene; no watermark
Avoid: human face, bulky mech, photorealism, chibi head, pixel art, excessive glow, tiny surface noise, perspective distortion
```

Acceptance: silhouette readable at 64 px; separable module boundaries; no baked custom color;
manual redraw into 192×192 production frames; all 14 state/pivot tests pass.

## Cleanup, slicing and rejection checklist

- Confirm canvas, alpha, pivot and attachment coordinates before slicing.
- Keep a 2 px transparent bleed around opaque module edges; remove RGB matte contamination.
- Align every frame to the same root pivot; never compensate by changing collision.
- Rotate one Dash base for eight directions only after verifying filtered bounds.
- Test body/accent masks with light, dark, low-saturation and similar-luminance pairs.
- Reject unreadable readiness at grayscale, 30% remote alpha or representative colorblind mode.
- Reject extra text/symbols, watermark, malformed machinery, non-seamless edges, strong focal
  landmarks, false collision edges, oversized canvases or excessive texture memory.
- Reject any asset that needs route/camera/timing changes, adds first-use stutter or requires a
  third-party runtime library.
