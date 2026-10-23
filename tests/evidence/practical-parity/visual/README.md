# Local scientific report visual review

Screenshots show the synthetic public-R fixture preserved in
`../report-example/`. Actual CSS viewports are 1440×1000 (desktop) and 390×844
(mobile). `visual-review.json` binds every JPEG, final HTML and renderer by
SHA256 and records the manual checks and limits. Screenshots retain the original
JPEG bytes: desktop images are 1440×1000 pixels and mobile images are
390×843 pixels; the mobile CSS viewport measured 390×844. Dimensions were
verified with Pillow, independently of the browser viewport measurements.

Representative views:

- `complete-desktop-overview.jpg`: exact retained cells, discovery counts and stage status.
- `complete-desktop-calibration.jpg`: public R calibration plots and actual control summaries.
- `complete-desktop-discovery.jpg`: public significance/effect diagnostics.
- `complete-mobile-overview.jpg`, `complete-mobile-discovery.jpg` and
  `complete-mobile-public-figure.jpg`: responsive text/cards/navigation and a
  readable horizontally scrollable public plot.
- `partial-*-omitted.jpg`: no scientific values inferred for unselected families.
- `failure-*.jpg`: explicit presentation failure with saved evidence links.

Review used CUA-controlled local Chrome; viewport overrides were reset.
These are local manual screenshots, not hosted visual-test results.
