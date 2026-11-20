# Visual direction and sources

MeetHalfway follows the visual language shown in [Yumi’s public demo](https://github.com/scrappydevs/Yumi/blob/main/Yumi_Demo.gif) and its discovery screen: an off-white canvas, translucent navigation, purple accents, a glass orb, people inside an activity orbit, and a floating composer. The UI and orb are independently implemented in SwiftUI, Compose, and CSS/JavaScript. No Yumi source code, logo, demo media or proprietary assets are included in the app.

`web/src/discovery.js` renders actual catalogue options and participants. Home tiles open sample-idea previews. Participant bubbles open sample perspectives. The composer names a new plan and opens its creation form; it does not pretend to be an AI chat. In a group room, selecting an eligible orbit tile updates the selected plan. Excluded ideas open the explanation of shared limits. Decorative orb animation does not invoke AI. Reduced-motion preferences disable it.

The same design is implemented with SwiftUI on iOS, Jetpack Compose on Android and HTML/CSS on web. `shared/design-tokens.json` generates Swift, Kotlin and CSS constants; all three bundle identical Inter Regular/Medium/SemiBold fonts and the same photographs. `shared/experience.json` and `shared/planner-cases.json` align content and recommendation behavior. Native renderers use their platform’s controls and accessibility while sharing the visual specification. Runtime screenshot parity has not yet been established on native hardware.

On phones, the orbit becomes smaller, detailed panels stack vertically, and translucent floating navigation replaces the sidebar. The iOS interface uses native SwiftUI `Button`, `TextField`, `TextEditor`, `Picker`, `Toggle`, `Stepper`, `DatePicker`, `Form`, `NavigationStack`, sheets and `ShareLink`. Its iOS 26 surfaces use `glassEffect`; older supported versions use SwiftUI material. Android uses Compose equivalents and a frosted surface treatment. The composer stays above the floating navigation. The web interface was inspected at desktop and 390 × 844 sizes; that evidence does not substitute for native device runs.

Inter is bundled under its SIL Open Font License, included in each platform’s resources. SwiftUI and Compose planner results are checked against seven shared web-generated scenarios, including zero budget, inaccessible options, missing cards and non-overlapping availability.

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
