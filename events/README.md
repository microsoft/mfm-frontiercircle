# Public event manifests

This directory contains sanitized public metadata for Frontier Circle events.
The records provide durable history, render the landing page's upcoming event
experience, generate public calendar subscriptions, and support monthly and
quarterly reporting.

The landing page previews the next three upcoming sessions. `schedule.html`
shows the full upcoming agenda grouped by month, with combined format, topic,
and keyword filters; neither
view imposes a three-month or session-count limit. Completed and cancelled
events stay in history but are excluded from upcoming views.

Store manifests under a year directory:

```text
events/
└── 2026/
    └── 2026-12-14-fabric-real-time-intelligence.json
```

Only information already intended for public event promotion belongs here.
Never add registrations, attendee information, customer or account names,
feedback, follow-up notes, private meeting links, event-management URLs, or
internal request identifiers.

Each source manifest must include stable `created`, `lastModified`, and
`sequence` fields. Keep the event `id` unchanged and increment `sequence` when
updating a published event.

Every event-generation request must include `topicCategories`: a non-empty
array of unique, human-reviewed IDs, separate from the `topics` learning
objectives. Use only `ai-agents` (AI & agents), `data-analytics` (Data & analytics),
`security` (Security), `modernization` (Modernization), and `connected-products`
(Connected products). An assistant proposes topics from the public agenda and
audience; a human reviews before publishing. Flag uncertainty instead of
inventing tags. The template's category is an example that must be reviewed.
The public builder rejects missing, unknown, or duplicate IDs and emits the
canonical labels for both pages; there is no runtime title classification.
See [the publishing guide](../EVENT-PUBLISHING.md#reviewed-discovery-topics).

Run:

```powershell
pwsh .\scripts\Build-FrontierCirclePublicEvents.ps1
```

The build produces `index.json`, `events.js`, `ics/*.ics`, and the root
`calendar.ics`. These generated files are public and must be committed, but
must not be edited manually.

The subscription is for discovery, not registration. Generated calendar
entries are marked Free; each session still requires separate registration.
