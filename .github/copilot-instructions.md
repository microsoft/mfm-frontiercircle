# Frontier Circle repository instructions

This is a public repository. Never commit confidential, customer, attendee, or
internal event-management information.

## Event publishing

When creating a Frontier Circle calendar event:

1. Follow [`EVENT-PUBLISHING.md`](../EVENT-PUBLISHING.md).
2. Use the lane mapping exactly:
   - `lab`: `🧪 Lab |` for Build & Skill Labs.
   - `briefing`: `💡 Briefing |` for Transformation Briefings.
   - `exchange`: `🤝 Exchange |` for Frontier Exchange.
3. Use the public registration page as the primary source. If its schedule
   conflicts with an approval email, stop and ask which public schedule is
   correct.
4. Use direct HTTPS registration URLs. Remove Outlook Safe Links wrappers.
5. Exclude request IDs, management URLs, internal contacts and instructions,
   registration data, and private Teams or lab links.
6. Store finalized, sanitized public event manifests under `events/<year>/`.
   Never add registrations, attendance, account names, feedback, or follow-up
   details to the public repository.
7. Keep the manifest `id` stable. Increment `sequence` and update
   `lastModified` whenever a published event changes.
8. Run `scripts/Build-FrontierCirclePublicEvents.ps1` after changing an event
   manifest. Review the generated landing-page data, aggregate `calendar.ics`,
   and individual event file.
9. For every event-generation request, propose one or more `topicCategories`
   from the public agenda and intended audience, and have a human review them
   before publishing. Flag uncertainty rather than fabricating tags. Only use
   unique IDs from the fixed taxonomy: `ai-agents` (AI & agents),
   `data-analytics` (Data & analytics), `security` (Security), `modernization`
   (Modernization), `connected-products` (Connected products).
   `topicCategories` is required and separate from `topics` learning objectives.
   The template category is an example, not a default. The public builder
   validates IDs and emits the shared labels; never guess topics from titles
   at runtime or duplicate the taxonomy in frontend code.
10. Propose short `audienceSummary` (roles) and `takeaway` (what participants
    can learn or build) from the public audience and agenda for human review.
    They are optional, but must be non-empty strings when present. Omit them
    if unsupported; never invent costs, recordings, preparation, or availability.
    Keep the complete `audience`, `description`, and `topics` source facts.
    Both pages show the summaries before registration without clipping;
    absent summaries reuse the existing audience and description, not AI inference.

Git event manifests are the public source of truth. The GitHub Pages landing
page and public calendar feed are generated from them. Outlook is an optional
operational mirror; private outcomes belong in the separate
OneDrive/SharePoint leadership workbook.

The landing page previews five sessions; `schedule.html` provides the full
monthly agenda with combined format, topic, and keyword filters. Keep calendar subscription separate from
event registration in all copy. Generated series entries are Free, not
attendance commitments. Never publish synthetic/test sessions to the feed.
Keep search terms local: no analytics payloads, URLs, or storage containing
raw queries. Preserve explicit Clarity masking on the search field and the
production-only cookieless setup.
