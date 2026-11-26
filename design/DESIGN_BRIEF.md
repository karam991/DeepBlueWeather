# DeepBlueWeather: "Living ocean" design brief

Status: **approved and built** on `design/living-ocean`. Based on explorations A (living ocean) and C (above / below). Before and after images are in [`before-after/`](before-after/).

Still open: measuring the frame rate on a real iPhone. The surface sea is limited to 580 points high, because the shader does not draw on very tall areas.

## 1. Signature element
A sea drawn from the forecast. Nothing in it is decorative:

| Data | Visual |
|---|---|
| Wave height | Swell height and foam |
| Wind speed | Surface chop |
| Time against sunrise and sunset | Sky and water colour, sun, moon, stars |
| Rain probability | Cloud cover |

Two views of the same sea:
- **Surface** (from A): looking across the water.
- **Cross-section** (from C): above and below the waterline.

The scene follows the time of day, not the light/dark setting. The page around it follows the setting.

## 2. Where the sea appears
| Screen | Treatment |
|---|---|
| Conditions | Surface hero for the selected hour |
| Dive detail | Cross-section hero for the dive hour, with water temperature and suit underwater |
| Login | Surface, no data shown; light follows the device clock |
| Dives, Checklist, Settings | **No sea.** Flat colour and type |

- At most one sea per screen.
- Never draw a sea from missing data. Inland or out-of-range locations get the plain `heroGradient` and say why.
- Bubbles and the old wave layers are retired from cards and banners.

## 3. Card hierarchy
1. **Hero:** one per screen, full width, answers "can I dive?".
2. **Card:** only for something tappable, or a chart with its controls.
3. **Plain content:** facts as a strip or rows with dividers, no card.

A value shown in the hero is never repeated below it.

## 4. Type scale
| Role | Size | Style |
|---|---|---|
| Hero number | 108 | Rounded, thin |
| Featured number | 56 | Rounded, semibold |
| Stat | 20 | Rounded, semibold, monospaced digits |
| Everything else | System text styles | |

Big numbers use `@ScaledMetric`. Heroes have minimum heights, and rows stack vertically at accessibility sizes.

## 5. Motion rules
- The sea is the only endless animation, at 30 frames per second at most.
- It holds one frame with Reduce Motion or Low Power Mode, and stops when off screen.
- Changing hour blends the sea over 0.6 s.
- Everything else moves only in response to an action.
- Delight moments play once, last 1.4 s at most, and become a haptic plus a static state with Reduce Motion.

## 6. Delight moments
1. **Excellent conditions:** a single glint crosses the water, with a success haptic, once per location per day.
2. **Checklist complete:** the progress ring fills like water, bubbles burst, "Ready to dive".
3. **Smart gear packed:** the list header turns into a "Kit packed" seal.
4. **Dive logged:** bubbles rise and the card is stamped "Logged".

## 7. Accessibility
- The sea is hidden from VoiceOver. Each hero reads as one summary: place, time, rating, water, waves, wind.
- The chart gets spoken values and an adjustable action for changing hour.
- Scrims keep white text readable, and the status bar is light over a hero.
- Air visibility is labelled "Air visibility" so it is not read as underwater visibility.

## 8. Rollout (one build and commit per step)
| Step | Screen | Changes |
|---|---|---|
| 0 | Foundation | Rerun UI tests. Move sea code to `Components` and `Models`, remove variant B and the sample-only code from the app, measure frame rate on a real iPhone |
| 1 | Conditions | A's hero and 24 h chart, suit line from C, facts strip, tide card; remove hour tiles and Details grid. Keeps the native search field |
| 2 | Dive detail | Cross-section hero, facts strip for non-hero values, "Kit packed" and "Logged" moments |
| 3 | Dives | Featured next dive with large countdown on flat deep blue; totals as a strip; quieter past dives |
| 4 | Checklist | Water-fill progress ring; plain smart-gear row instead of the ocean banner |
| 5 | Login | Surface sea behind the existing form |
| 6 | Settings | Appearance: System / Light / Dark, default System. Anyone who had Dark Mode on stays on Dark |

Each step also covers Dynamic Type and VoiceOver for that screen.

## 9. Approved changes
- `testDemoConditions` drags the chart instead of tapping the removed hour tiles.
- Dive totals and upcoming/past filtering moved into `DivePlannerViewModel`. No other ViewModel, service or Firebase change.
