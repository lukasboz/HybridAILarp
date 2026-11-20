# Visual direction and sources

The shared Flutter UI follows [Yumi’s web dashboard](https://www.aarushagarwal.dev/projects/Yumi): pale-blue canvas, translucent sidebar, ice-blue glass orb, photo orbit, participant bubbles and floating composer. The user selected the web dashboard as the reference for all platforms. Original Yumi code, branding and demo assets are not bundled.

The palette follows [the selected Coolors colours](https://coolors.co/001b2e-6279b8-c1dff0): navy `#001B2E` for primary text and buttons, periwinkle `#6279B8` for accents, and ice blue `#C1DFF0` for the orb, borders and supporting surfaces. Backgrounds use lighter blue tints. Small text uses darker navy-derived shades for contrast.

`app/lib/design.dart`, `orbit.dart`, `screens.dart` and `dialogs.dart` implement one interface. All targets use Inter, bundled Material icons, identical imagery and a fixed shared control theme. Glass is painted by Flutter; the app does not substitute iOS Liquid Glass, Android native forms or CSS controls. At equal logical viewport, text scale, data and animation state, these widgets share a visual baseline.

A sidebar appears at 760 logical pixels; narrower screens use floating bottom navigation. Desktop expands the group-room layout into orbit and shortlist columns. Fonts respond to text scaling, controls remain accessible and orb motion respects reduced-motion settings. System UI such as keyboards and share targets belongs to each platform.

`shared/design-tokens.json` and `shared/experience.json` remain canonical inputs. `scripts/sync-flutter-assets.py` bundles data, fonts and photographs. Golden tests cover 390×844 and 1440×1000 layouts; a 320×640 test exercises enlarged text. Native screenshot parity still needs actual device builds.

Activity photos are downloaded and bundled locally. They illustrate categories, not verified venue interiors. Photo attribution and source references:

| Asset | Source |
| --- | --- |
| `games.jpg` | [Konrad Koller — board game](https://unsplash.com/photos/a-close-up-of-a-board-game-with-dices-zY5m91eiCGQ) |
| `art.jpg` | [Alexander Skrypnikov — gallery interior](https://unsplash.com/photos/art-gallery-interior-with-paintings-and-seating-EzfHCR-0bGo) |
| `water.jpg` | [Janis Laubergs — Toronto waterfront](https://unsplash.com/photos/cn-tower-canada-jFJASxF3osU) |
| `park.jpg` | [Toronto waterfront park](https://unsplash.com/photos/a-view-of-a-city-from-a-park-PN0V6eGftWs) |
| `coffee.jpg` | [Unsplash coffee photograph](https://images.unsplash.com/photo-1495474472287-4d71bcdd2085) |
| `food.jpg` | [Unsplash dining photograph](https://images.unsplash.com/photo-1414235077428-338989a2e8c0) |
| `market.jpg` | [Toronto waterfront panorama](https://unsplash.com/es/fotos/foto-de-paisaje-de-la-ciudad-MI0lyrjy1IA) |

The photographs are provided under the [Unsplash License](https://unsplash.com/license), independently of the MIT license covering MeetHalfway’s original code. All app icons are generated from the repository’s own geometric mark.
