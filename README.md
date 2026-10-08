# Manufacturing & Mobility Frontier Circle

This repository holds the public landing page for **Microsoft Manufacturing & Mobility Frontier Circle**: Microsoft-hosted technical labs, webinars, and industry briefings for manufacturing and mobility teams building and exploring AI, agents, data platforms, security, modernization, and connected products.

**Visit the site: [aka.ms/mfm-frontiercircle](https://aka.ms/mfm-frontiercircle)**

## Never miss a session

Subscribe to the Frontier Circle calendar once, and new or updated sessions appear in your calendar automatically.

| Option | How |
| --- | --- |
| **Subscribe in Outlook** (recommended) | [Subscribe with one click](https://outlook.office.com/calendar/addfromweb/?url=https%3A%2F%2Faka.ms%2Fmfm-frontiercircle-calendar-ics&name=MfM%20Frontier%20Circle). Outlook on the web opens its *Subscribe from web* dialog pre-filled (Microsoft 365 work or school account); select **Import**. |
| **Preview the calendar** | [aka.ms/mfm-frontiercircle-calendar](https://aka.ms/mfm-frontiercircle-calendar) shows upcoming sessions in Outlook on the web. No sign-in required. |
| **Other calendar apps** | Subscribe to this address: `https://aka.ms/mfm-frontiercircle-calendar-ics` |

To add the calendar address in other apps:

- **Google Calendar (web):** next to *Other calendars*, select **+** → **From URL**, paste the address, then select **Add calendar**.
- **Apple Calendar (Mac):** choose **File** → **New Calendar Subscription**, paste the address, then select **Subscribe**.

> [!TIP]
> Subscribing keeps your calendar current. Downloading or importing the `.ics` file creates a one-time snapshot that won't update.

Registration is separate: each event has its own registration page. Use the calendar to discover topics, then register for the sessions you want to attend.

## What to expect

Sessions are designed for both technical teams and business leaders. Pick the lane that fits the topic and audience.

| Lane | Audience | Format |
| --- | --- | --- |
| **Build & Skill Labs** | Technical | Hands-on labs, guided workshops, and implementation clinics for architects, engineers, makers, and technical teams. |
| **Transformation Briefings** | Business | Webinars, industry insights, customer stories, and art-of-the-possible discussions for business and technology leaders. |
| **Frontier Exchange** | Shared | Cross-functional sessions where business and technical stakeholders compare patterns, questions, and next steps. |

## Contact

Questions about Frontier Circle? Email [mfm-frontiercircle@microsoft.com](mailto:mfm-frontiercircle@microsoft.com).

## About this site

The page is a single, self-contained [`index.html`](index.html): HTML, CSS, an inline SVG illustration, and a small script. There's no build step, framework, web font, analytics, or third-party request. It's published with [GitHub Pages](https://docs.github.com/pages) from the root of the `main` branch.

### Preview locally

Open `index.html` directly in a browser, or serve the folder to mirror GitHub Pages:

```bash
python -m http.server 8000
```

Then browse to <http://localhost:8000>.

### Make changes

- All content, styles, and the illustration live in `index.html`. Colors are defined once as CSS custom properties at the top of the stylesheet.
- Calendar links use `aka.ms` short links, so the calendar can be republished without changing the page.
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

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general). Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos are subject to those third-party's policies.
