# Screen schema (version 1)

The JSON a backend (BFF) sends to describe one screen. Small, versioned, and
safe: anything an older app does not understand is skipped, never a crash.

## Screen

```json
{
  "schemaVersion": 1,
  "id": "songkran",
  "title": "Songkran Festival",
  "minAppVersion": "1.2.0",
  "analyticsName": "bff_songkran",
  "state": { "tab": "all", "notify": true },
  "body": [ /* components */ ],
  "toolbar": [ /* toolbarButton components */ ]
}
```

| Field | Required | Meaning |
|---|---|---|
| `schemaVersion` | yes | Format version. The app sends the highest it supports (`?schema=1`); never send more. |
| `id` | yes | Screen id (also in the URL: `bff/screens/<id>`). |
| `title` | | Navigation bar title. |
| `minAppVersion` | | Older apps show "update the app" instead of a broken page. |
| `analyticsName` | | `screen_view` name. Default `dynamic_<id>`. |
| `state` | | Initial values for `bind`, `visibleIf`, `{{key}}` text. |
| `body` | | Components, top to bottom, in a scroll view. |
| `toolbar` | | `toolbarButton`s in a floating glass toolbar. |

## Component

```json
{ "type": "button", "id": "buy", "props": { "title": "Buy" }, "children": [], "action": { }, "visibleIf": { } }
```

`type` is required; everything else is optional. Unknown `type` = skipped.
Text props may contain `{{stateKey}}`.

### Layout

| type | props | children |
|---|---|---|
| `vstack` | `spacing`, `alignment` (`leading`/`center`/`trailing`) | yes |
| `hstack` | `spacing` | yes |
| `grid` | `columns` (default 2), `spacing` | yes |
| `carousel` | `itemWidth` (default 260), `spacing` | yes (horizontal, snapping) |
| `section` | `title`, `subtitle` | yes |
| `spacer` | `size` | |
| `divider` | | |

### Content

| type | props |
|---|---|
| `text` | `text`, `style` (`largeTitle`, `title`, `title2`, `title3`, `headline`, `body`, `callout`, `subheadline`, `footnote`, `caption`), `weight` (`bold`, `semibold`, `medium`), `color`, `alignment`, `lines` |
| `image` | `url`, `height`, `aspectRatio`, `cornerRadius`, `contentMode` (`fill`/`fit`), `label` (VoiceOver) |
| `icon` | `systemName` (SF Symbol), `size`, `color`, `label` |
| `badge` | `text`, `color` |

### Glass

| type | props |
|---|---|
| `card` | `padding`, `cornerRadius`, `spacing`, `tint` (+ children, + optional `action`) |
| `glassGroup` | `spacing` (children morph together on iOS 26) |
| `button` | `title`, `icon`, `style` (`glass`, `prominent`, `plain`), `fullWidth` |
| `banner` | `imageUrl`, `title`, `subtitle`, `badge`, `height`, `cornerRadius` |
| `listItem` | `icon`, `iconColor`, `title`, `subtitle`, `value`, `chevron` |
| `toolbarButton` | `icon`, `title` (toolbar only) |

### Controls (bound to `state`)

| type | props |
|---|---|
| `searchField` | `bind`, `prompt` (action = on submit) |
| `toggle` | `bind`, `title` (action = on change) |
| `slider` | `bind`, `title`, `min`, `max`, `step` |
| `segmented` | `bind`, `options`: `[{ "title", "value", "icon" }]` (action = on change) |

### App components

Apps add their own types. This app: `event_card` (`eventId`), the app's event
card loaded by id.

## Colors

`"#7952FC"`, `"#7952FCCC"` (with alpha) or a name: `accent`, `primary`,
`secondary`, `red`, `orange`, `yellow`, `green`, `teal`, `blue`, `purple`,
`pink`, `gray`, `white`, `black`.

## Actions

| type | fields | done by |
|---|---|---|
| `deepLink` | `url` (`eventpush://events/42`) | app router |
| `openURL` | `url` (http/https/mailto/tel) | system |
| `screen` | `id`, `presentation` (`push`, `sheet`, `fullScreen`) | app: another server screen |
| `track` | `event`, `params` (ids and categories only: no personal data) | analytics |
| `setState` | `key`, `value` | renderer, instant |
| `toggleState` | `key` | renderer, instant |
| `sequence` | `actions` (broken steps skipped) | both |
| `dismiss` | | closes the screen |
| `reload` | | fetches the screen again |
| anything else | free fields | `custom` (app may support it) |

A broken action (e.g. `deepLink` without `url`) is dropped; the component stays.

## Conditions (`visibleIf`)

```json
{ "key": "tab", "equals": "music" }
{ "key": "tab", "notEquals": "all" }
{ "key": "promoCode", "exists": true }
```

## Versioning rules for the backend

- Additive changes (new component types, new props, new actions) keep
  `schemaVersion: 1`. Older apps skip what they do not know.
- Breaking changes bump `schemaVersion`. Serve the version the app asks for (`?schema=`).
- A screen that needs a component only newer apps have: set `minAppVersion`.
