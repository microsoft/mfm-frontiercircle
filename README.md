# Manufacturing & Mobility Frontier Circle

[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-live-2ea44f?logo=github)](https://aka.ms/mfm-frontiercircle)

This repository holds the public landing page for **Microsoft Manufacturing & Mobility Frontier Circle**: build practical skills, explore industry-relevant ideas, and learn approaches your team can apply. Microsoft-hosted labs, briefings, and conversations for manufacturing and mobility teams.

**Visit the site: [aka.ms/mfm-frontiercircle](https://aka.ms/mfm-frontiercircle)**

## Upcoming events and calendar subscription

The landing page introduces the series, offers a calendar subscription, and
previews the next three upcoming sessions.
Both pages show **For** and **You’ll** summaries before registration, with full
learning objectives and audience/familiarity details available to expand.
The landing page keeps one subscription options area in the hero and a short
three-lane introduction; lanes describe the series breadth, not guaranteed
upcoming availability. Only published upcoming records appear.
The [full schedule](https://microsoft.github.io/mfm-frontiercircle/schedule.html)
groups all upcoming sessions by month. Search titles, descriptions, audience,
learning objectives, and approved topic labels, or combine a topic with Labs,
Briefings, or Exchange. Clear filters restores the full agenda. Quiet topic
badges appear on both pages. Both views use sanitized manifests under [`events/`](events/). The same records
generate a public calendar feed, so event presentation and calendar
subscriptions stay consistent.

| Option | How |
| --- | --- |
| **Browse and register** | [Full schedule](https://microsoft.github.io/mfm-frontiercircle/schedule.html) shows upcoming sessions, audiences, topics, deadlines, and official registration links. |
| **Subscribe in Outlook** (recommended) | [Subscribe with one click](https://outlook.office.com/calendar/addfromweb/?url=https%3A%2F%2Fmicrosoft.github.io%2Fmfm-frontiercircle%2Fcalendar.ics&name=MfM%20Frontier%20Circle). Outlook on the web opens its *Subscribe from web* dialog pre-filled; select **Import**. |
| **Other calendar apps** | Subscribe to `https://microsoft.github.io/mfm-frontiercircle/calendar.ics`. |

To add the calendar address in other apps:

- **Google Calendar (web):** next to *Other calendars*, select **+** → **From URL**, paste the address, then select **Add calendar**.
- **Apple Calendar (Mac):** choose **File** → **New Calendar Subscription**, paste the address, then select **Subscribe**.

> [!TIP]
> Subscribing keeps the calendar current, but each calendar provider chooses
> its own refresh schedule. Downloading an individual `.ics` file creates a
> one-time snapshot.

Registration remains separate: use the landing page or the event description
in a compatible calendar client to open the official registration page.
Series calendar entries are marked **Free**: subscribing keeps sessions on
your radar without deliberately reserving time or registering you to attend.
Calendar clients control how subscribed calendars are displayed.

## What to expect

Sessions are designed for both technical teams and business leaders. Pick the lane that fits the topic and audience.

| Lane | Calendar prefix | Audience | Format |
| --- | --- | --- | --- |
| **Build & Skill Labs** | `🧪 Lab \|` | Technical | Hands-on labs, guided workshops, and implementation clinics for architects, engineers, makers, and technical teams. |
| **Transformation Briefings** | `💡 Briefing \|` | Business | Webinars, industry insights, customer stories, and art-of-the-possible discussions for business and technology leaders. |
| **Frontier Exchange** | `🤝 Exchange \|` | Shared | Cross-functional sessions where business and technical stakeholders compare patterns, questions, and next steps. |

Maintainers can use the [event publishing guide](EVENT-PUBLISHING.md),
[`New-FrontierCircleEvent.ps1`](scripts/New-FrontierCircleEvent.ps1), and
[`Build-FrontierCirclePublicEvents.ps1`](scripts/Build-FrontierCirclePublicEvents.ps1)
to create consistent page data, subscription feeds, and import-ready calendar
files. Sanitized public event records live under [`events/`](events/) so
monthly and quarterly activity summaries can be generated without exposing
private outcome metrics.

## Contact

Questions about Frontier Circle? Email [mfm-frontiercircle@microsoft.com](mailto:mfm-frontiercircle@microsoft.com).

## About this site

The site uses a landing page ([`index.html`](index.html)) and a full monthly
agenda ([`schedule.html`](schedule.html)), generated static event data, an inline
SVG illustration, and small shared scripts and styles. There is no frontend framework
or web font. A PowerShell build step regenerates the public event data and
calendar files from the manifests. The production page uses Microsoft
Clarity's cookieless mode for page-visit and link-engagement reporting. Local
previews don't load Clarity. It's published with
[GitHub Pages](https://docs.github.com/pages) from the root of the `main`
branch.

### Make changes

- The landing page and illustration live in `index.html`; `schedule.html`
  provides the full agenda. Shared event rendering and presentation keep both
  views consistent.
- Public event content lives in `events/<year>/*.json`. Run
  `pwsh .\scripts\Build-FrontierCirclePublicEvents.ps1` after changing a
  manifest and commit the generated assets.
- Every event-generation request needs `topicCategories`, separate from
  `topics` learning objectives. Use unique IDs from the fixed taxonomy:
  `ai-agents` (AI & agents), `data-analytics` (Data & analytics),
  `security` (Security), `modernization` (Modernization), and
  `connected-products` (Connected products). An assistant proposes from the
  public agenda and audience; a human reviews before publishing. Flag
  uncertainty instead of inventing tags. The public builder validates the
  required array and emits the shared labels. See the
  [reviewed discovery topics](EVENT-PUBLISHING.md#reviewed-discovery-topics).
- Optional `audienceSummary` and `takeaway` fields provide short, reviewed,
  public-source-grounded roles and outcomes. Omit them if unsupported; when
  supplied they must be non-empty strings. Both pages reuse full audience and
  description if summaries are absent, without runtime inference. Preserve
  full source facts in `audience`, `description`, and `topics`; do not invent
  costs, recordings, preparation, or dates. Search also checks the summaries.
- The stable public subscription URL is
  `https://microsoft.github.io/mfm-frontiercircle/calendar.ics`.
- Microsoft Clarity uses project `z4t5ly03h4`. Keep **Settings → Setup → Advanced settings → Cookies** off in the Clarity project. The page always sends both analytics and advertising storage as denied, so Clarity remains cookieless.
- Before merging, check the page at desktop and mobile widths, using only the keyboard, and with your operating system's *reduce motion* setting turned on.

### Accessibility

- Semantic landmarks and headings, a logical keyboard order, and visible focus indicators.
- Text colors chosen to meet WCAG 2.1 AA contrast.
- The illustration is decorative and hidden from screen readers. Its animation stops entirely when *reduce motion* is on, pauses when scrolled out of view, and has a pause button that appears on hover or keyboard focus.

## Contributing

This project welcomes contributions and suggestions. Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit <https://cla.opensource.microsoft.com>.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Security

Please don't report security vulnerabilities through public GitHub issues. See [SECURITY.md](SECURITY.md) for how to report them.

## Data collection and privacy

The production page uses [Microsoft Clarity](https://clarity.microsoft.com/) for page-visit reporting, engagement analytics, custom click events, and session recordings. Clarity always runs with both analytics and advertising storage denied, and the Clarity project's cookie setting is disabled. The site does not request or set optional Clarity cookies, so it does not display a cookie-consent banner.

In cookieless mode, page views and events are reported, but each page view is treated as a separate session, visitors can't be recognized as returning users, and time-based or multi-page metrics are less accurate. In particular, transitions between the landing page and the full schedule cannot reliably be stitched into a single visitor journey. The pages send explicit Clarity events for event-schedule navigation,
registration clicks, individual event downloads, Outlook subscription clicks,
calendar-address copy clicks, and contact-email clicks.
Search terms stay in memory on the page, are explicitly masked from Clarity,
and are not sent as custom events, written to the URL, or persisted.

Clarity is disabled for local and non-HTTPS previews. See [reporting without cookie consent](https://learn.microsoft.com/clarity/setup-and-installation/clarity-without-cookie-consent) and the [Clarity cookie documentation](https://learn.microsoft.com/clarity/setup-and-installation/clarity-cookies) for details.

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft's privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.

## Legal notices

Microsoft and any contributors grant you a license to the Microsoft documentation and other content in this repository under the [Creative Commons Attribution 4.0 International Public License](https://creativecommons.org/licenses/by/4.0/legalcode), see the [LICENSE](LICENSE) file, and grant you a license to any code in the repository under the [MIT License](https://opensource.org/licenses/MIT), see the [LICENSE-CODE](LICENSE-CODE) file.

In [`index.html`](index.html), the customer-facing copy and original logistics illustration are content licensed under CC BY 4.0; the HTML, CSS, and JavaScript implementation is code licensed under MIT. Microsoft names, logos, and trademarks are excluded from that content license as described below.

Microsoft, Windows, Microsoft Azure, and other Microsoft products and services referenced in the documentation may be either trademarks or registered trademarks of Microsoft in the United States or other countries. The licenses for this project do not grant you rights to use any Microsoft names, logos, or trademarks. Microsoft's general trademark guidelines can be found at the [Microsoft Trademark and Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).

Privacy information can be found at [https://privacy.microsoft.com](https://privacy.microsoft.com).

Microsoft and any contributors reserve all other rights, whether under their respective copyrights, patents, or trademarks, whether by implication, estoppel, or otherwise.