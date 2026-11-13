# Frontier Circle event publishing

Sanitized Git event manifests are the public source of truth. They generate the
landing-page previews and monthly agenda on GitHub Pages, the aggregate subscription feed,
individual `.ics` downloads, and public activity reports. Outlook can retain a
shared operational calendar, but it is a mirror rather than the public
publishing source.

Private outcomes such as registrations, attendance, accounts, feedback, and
follow-ups stay outside this public repository.

## Calendar title convention

Use this format:

```text
<emoji> <short lane> | <event-specific title>
```

| Landing-page lane | Prefix | Example |
| --- | --- | --- |
| Build & Skill Labs | `🧪 Lab |` | `🧪 Lab | Build a Fabric Real-Time Intelligence Solution in a Day` |
| Transformation Briefings | `💡 Briefing |` | `💡 Briefing | Securing AI-Enabled Manufacturing` |
| Frontier Exchange | `🤝 Exchange |` | `🤝 Exchange | Connected Factory Patterns` |

The text label is required even when an emoji is present so titles remain
understandable in clients that render emoji differently and for people using
assistive technology.

## Public event content

Each calendar entry should include:

- Stable `created` and `lastModified` timestamps.
- A non-negative `sequence` number that increments whenever a published event
  changes.
- The event-specific public title.
- Start and end times with an explicit UTC offset.
- An IANA time-zone name, such as `America/New_York`, for webpage formatting.
- A short public time-zone label, such as `ET`.
- Public location, usually `Online`.
- A concise description focused on attendee value.
- Audience and major topics when available.
- Optional, human-reviewed `audienceSummary` (short intended roles) and
  `takeaway` (what participants can learn or build), grounded in the public
  audience and agenda. Omit unsupported summaries. When present, each must
  be a non-empty string; null, whitespace, and non-text values fail validation.
  Keep full audience, familiarity/preparation facts, description, and learning
  objectives in their existing fields. Do not invent costs, recordings,
  preparation details, or upcoming dates.
- A required `topicCategories` array with one or more reviewed IDs from the
  fixed taxonomy below. This is separate from the `topics` learning objectives.
- The direct public registration URL.
- The public registration deadline when available.

Use the public registration page as the primary source for title, schedule,
description, audience, and registration URL. Approval emails can contain
administrative date ranges that differ from the published session. Resolve any
conflict before generating the calendar file.

### Reviewed discovery topics

| ID | Public label |
| --- | --- |
| `ai-agents` | AI & agents |
| `data-analytics` | Data & analytics |
| `security` | Security |
| `modernization` | Modernization |
| `connected-products` | Connected products |

For every new event or event-generation request, an assistant may propose
`topicCategories` based on the public agenda and intended audience. A human
must review those proposals before publishing. Use only these fixed IDs; flag
uncertainty for review rather than fabricating a category or inferring tags
from the title at runtime. Select all relevant approved topics, without duplicates.
The template's `["data-analytics"]` is an example, not a default for every event.

The public builder validates this required array and emits both event IDs and
the canonical ID/label mapping in the generated data. The browser uses that
mapping for badges, search, and the topic selector; do not maintain a second
taxonomy in frontend code. Individual calendar content remains unchanged by
topic tags.

### Never publish

Do not include:

- Event request IDs or internal tracking identifiers.
- Event-management or organizer-only URLs.
- Outlook Safe Links; use the direct destination URL.
- Internal support contacts, operational instructions, or compliance text.
- Attendee or registration data.
- Private Teams meeting or lab-access links.

## Publish or update an event

1. Copy [`templates/frontier-circle-event.json`](templates/frontier-circle-event.json)
   to `events/<year>/` and replace the placeholders with approved public event
   information.
2. Have a human review the proposed `topicCategories` against the public agenda
   and audience, along with any short audience and takeaway summaries.
   Confirm the manifest contains no internal-only information.
3. For an update to an already published event:
   - Increment `sequence`.
   - Set `lastModified` to the current offset-aware timestamp.
   - Keep `id` unchanged so subscribed clients update the existing event.
4. Rebuild all public event assets:

   ```powershell
   pwsh .\scripts\Build-FrontierCirclePublicEvents.ps1
   ```

5. Review:
   - `events/index.json` and `events/events.js` for the landing page.
   - `calendar.ics` for the aggregate subscription.
   - `events/ics/<event>.ics` for an individual event download or Outlook
     import.
6. Preview the landing page and confirm the event title, schedule, audience,
   topics, deadline, and registration action. The landing page shows the next
   five upcoming sessions; `schedule.html` shows all upcoming sessions grouped
   by month, with format, topic, and keyword filters that combine (AND).
   Search checks titles, descriptions, audience, learning objectives, and
   approved category labels, ignoring case and surrounding whitespace.
   Verify topic badges on both pages, combined results, and Clear filters.
   Both pages show unclipped **For** and **You’ll** lines before registration,
   using `audienceSummary` and `takeaway`, or the existing audience and
   description when summaries are absent. The full description remains in
   expanded details when it differs from the takeaway; identical text is not
   repeated. Verify full learning objectives and audience/familiarity details
   expand, and registration is identified as opening an external site in a new tab.
   Completed and cancelled sessions remain in the
   public history but do not appear in the upcoming schedule.
7. If the shared Outlook calendar is still needed operationally, import the
   generated individual `.ics` file there and verify it separately.

Importing an individual `.ics` file creates a snapshot. The website and public
subscription feed update from Git; they do not depend on Outlook's anonymous
calendar publishing permissions.

The series calendar is a discovery channel, not a registration or attendance
commitment. Generated entries are marked Free (`TRANSP:TRANSPARENT` and
`X-MICROSOFT-CDO-BUSYSTATUS:FREE`) so they do not intentionally reserve time.
Calendar clients control how subscribed calendars are displayed. Attendees
must register separately through each session's official registration page.

### Generated public files

Do not edit these files manually:

- `calendar.ics`
- `events/index.json`
- `events/events.js`
- `events/ics/*.ics`

The validation workflow rebuilds them and fails when committed outputs are
stale.

## Monthly and quarterly reporting

Generate a public activity summary from the versioned event manifests:

```powershell
pwsh .\scripts\Get-FrontierCircleEventReport.ps1 `
  -StartDate 2026-10-01 `
  -EndDate 2026-12-31 `
  -OutputPath C:\path\to\Frontier-Circle-Q4-2026.md
```

The report includes event counts by lane, scheduled hours, status, dates,
titles, and registration links. It intentionally excludes private outcomes.
Combine it with the private leadership workbook when reporting registrations,
attendance, organizations engaged, feedback, and follow-ups.

## Generator behavior

The generator:

- Applies the lane emoji and short label.
- Converts offset-aware input times to UTC.
- Marks series entries Free rather than reserving time before registration.
- Preserves stable UIDs, created/modified timestamps, and sequence numbers for
  subscribed calendar updates.
- Escapes iCalendar text and folds UTF-8 lines to the 75-byte limit.
- Writes UTF-8 without a byte-order mark and uses CRLF line endings.
- Creates a stable UID from the public event ID.
- Adds a restrained, email-safe HTML event body for Outlook while retaining
  the complete plain-text description as a fallback for other calendar clients.
- Rejects invalid date ranges, non-HTTPS registration links, Safe Links, and
  common internal-only content.
- The public builder also rejects missing, empty, unknown, or duplicate
  `topicCategories` IDs before generating that event's assets.
- The public builder rejects malformed optional `audienceSummary` and
  `takeaway` values and emits reviewed summaries for both pages. These fields
  do not replace the full calendar description, audience, or learning objectives.
- Omits organizers, attendees, reminders, and meeting links.

Sanitized event manifests belong under `events/<year>/` and are committed for
durable history. Public generated feeds are also committed because GitHub
Pages serves them directly. Ad hoc local calendar drafts belong in
`calendar-drafts/`, which is ignored by Git.
