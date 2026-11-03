(() => {
  const board = document.getElementById('event-board');
  if (!board) return;

  const status = document.getElementById('events-status');
  const mode = board.dataset.eventMode || 'schedule';
  const isSchedule = mode === 'schedule';
  const filters = Array.from(document.querySelectorAll('.schedule-filter[data-lane]'));
  const data = window.frontierCircleEventData;
  const topicLabels = new Map((data && Array.isArray(data.topicCategories) ? data.topicCategories : [])
    .map((category) => [category.id, category.label]));
  const search = document.getElementById('session-search');
  const topicFilter = document.getElementById('session-topic');
  const clearFilters = document.getElementById('clear-filters');
  const laneNames = {
    all: 'All',
    lab: 'Labs',
    briefing: 'Briefings',
    exchange: 'Exchange'
  };
  const copyStatus = document.getElementById('copy-status');
  let upcoming = [];
  let selectedLane = 'all';
  let selectedTopic = 'all';
  let searchText = '';

  const matchesDiscovery = (event) => {
    if (selectedTopic !== 'all' && !(event.topicCategories || []).includes(selectedTopic)) return false;
    const query = searchText.trim().toLocaleLowerCase();
    if (!query) return true;
    return [
      event.title, event.summary, event.description, event.audience, event.audienceSummary, event.takeaway,
      ...(event.topics || []),
      ...(event.topicCategories || []).map((id) => topicLabels.get(id))
    ].filter(Boolean).join(' ').toLocaleLowerCase().includes(query);
  };

  const setStatus = (message) => {
    if (status) status.textContent = message;
  };

  const showError = (error) => {
    board.replaceChildren();
    const message = document.createElement('p');
    message.className = 'events__error';
    message.textContent = 'The schedule could not be displayed. Refresh the page to try again.';
    board.appendChild(message);
    setStatus('The event schedule could not be loaded.');
    if (window.console && typeof window.console.error === 'function') {
      window.console.error('Frontier Circle schedule rendering failed:', error);
    }
  };

  const announce = (message) => {
    if (!copyStatus) return;
    copyStatus.textContent = '';
    window.setTimeout(() => { copyStatus.textContent = message; }, 60);
  };

  const initScheduleControls = () => {
    if (!isSchedule) return;

    document.addEventListener('click', (clickEvent) => {
      if (!(clickEvent.target instanceof Element)) return;
      const tracked = clickEvent.target.closest('[data-clarity-event]');
      if (tracked && typeof window.clarity === 'function') {
        window.clarity('event', tracked.dataset.clarityEvent);
      }
    });

    document.querySelectorAll('[data-copy-target]').forEach((button) => {
      button.addEventListener('click', async () => {
        const source = document.getElementById(button.getAttribute('data-copy-target'));
        if (!source) {
          announce('The calendar address is not available to copy.');
          return;
        }

        const text = source.textContent.trim();
        let copied = false;
        try {
          if (navigator.clipboard && window.isSecureContext) {
            await navigator.clipboard.writeText(text);
            copied = true;
          }
        } catch (error) {
          if (window.console && typeof window.console.warn === 'function') {
            window.console.warn('Clipboard access was unavailable; using the browser copy fallback.', error);
          }
        }

        if (!copied) {
          const field = document.createElement('textarea');
          field.value = text;
          field.setAttribute('readonly', '');
          field.className = 'sr-only';
          document.body.appendChild(field);
          field.select();
          try { copied = document.execCommand('copy'); } catch (error) {
            if (window.console && typeof window.console.warn === 'function') {
              window.console.warn('The browser could not copy the calendar address.', error);
            }
          }
          field.remove();
        }

        if (copied) {
          announce('Calendar address copied to your clipboard.');
        } else {
          const selection = window.getSelection();
          const range = document.createRange();
          range.selectNodeContents(source);
          selection.removeAllRanges();
          selection.addRange(range);
          announce('Address selected. Press Ctrl+C, or Command+C on a Mac, to copy it.');
        }
      });
    });

    document.querySelectorAll('[data-year]').forEach((node) => {
      node.textContent = String(new Date().getFullYear());
    });
  };

  const formatDate = (value, timeZone, options) => {
    return new Intl.DateTimeFormat('en-US', { ...options, timeZone }).format(new Date(value));
  };

  const makeText = (parent, tag, className, value) => {
    const node = document.createElement(tag);
    if (className) node.className = className;
    node.textContent = value;
    parent.appendChild(node);
    return node;
  };

  const safeUrl = (value, allowRelative) => {
    if (typeof value !== 'string' || value.trim() === '') return null;
    try {
      const url = new URL(value, window.location.href);
      if (url.protocol !== 'https:' && !(allowRelative && url.origin === window.location.origin)) return null;
      return url.href;
    } catch (error) {
      return null;
    }
  };

  const appendFact = (parent, label, value) => {
    const fact = document.createElement('div');
    fact.className = 'event-fact';
    makeText(fact, 'span', 'event-fact__label', label);
    makeText(fact, 'span', 'event-fact__value', value);
    parent.appendChild(fact);
  };

  const renderEvent = (event, index) => {
    const article = document.createElement('article');
    const stableId = String(event.id || `event-${index}`).replace(/[^a-zA-Z0-9_-]/g, '-');
    article.className = `event-card event-card--${event.lane}`;
    article.id = `event-${stableId}`;

    const dateRail = document.createElement('div');
    dateRail.className = 'event-date';
    dateRail.setAttribute('aria-label', formatDate(event.start, event.timeZone, {
      weekday: 'long', month: 'long', day: 'numeric', year: 'numeric'
    }));
    const dateMain = document.createElement('div');
    makeText(dateMain, 'span', 'event-date__lane', `${event.laneEmoji || ''} ${event.laneLabel || laneNames[event.lane] || 'Session'}`.trim());
    makeText(dateMain, 'span', 'event-date__month', formatDate(event.start, event.timeZone, { month: 'long' }));
    makeText(dateMain, 'span', 'event-date__day', formatDate(event.start, event.timeZone, { day: 'numeric' }));
    makeText(dateMain, 'span', 'event-date__weekday', formatDate(event.start, event.timeZone, { weekday: 'long' }));
    dateRail.appendChild(dateMain);
    makeText(dateRail, 'span', 'event-date__year', formatDate(event.start, event.timeZone, { year: 'numeric' }));

    const body = document.createElement('div');
    body.className = 'event-body';
    const kicker = document.createElement('p');
    kicker.className = 'event-kicker';
    kicker.appendChild(document.createTextNode(event.laneName || laneNames[event.lane] || 'Frontier Circle'));
    body.appendChild(kicker);

    const title = makeText(body, 'h3', 'event-title', event.title || event.summary || 'Frontier Circle session');
    title.id = `${article.id}-title`;
    article.setAttribute('aria-labelledby', title.id);
    const categories = (event.topicCategories || []).filter((id) => topicLabels.has(id));
    if (categories.length) {
      const badges = document.createElement('ul');
      badges.className = 'event-topics';
      badges.setAttribute('aria-label', 'Session topics');
      categories.forEach((id) => makeText(badges, 'li', 'event-topic', topicLabels.get(id)));
      body.appendChild(badges);
    }
    const audienceSummary = event.audienceSummary || event.audience;
    const takeaway = event.takeaway || event.description;
    if (audienceSummary || takeaway) {
      const value = document.createElement('div');
      value.className = 'event-value';
      const appendSummary = (label, text) => {
        if (!text) return;
        const line = makeText(value, 'p', 'event-value__line', '');
        makeText(line, 'strong', 'event-value__label', label);
        line.appendChild(document.createTextNode(` ${text}`));
      };
      appendSummary('For', audienceSummary);
      appendSummary("You’ll", takeaway);
      body.appendChild(value);
    }

    const facts = document.createElement('div');
    facts.className = 'event-facts';
    appendFact(facts, 'Date', formatDate(event.start, event.timeZone, {
      weekday: 'short', month: 'short', day: 'numeric', year: 'numeric'
    }));
    const startTime = formatDate(event.start, event.timeZone, { hour: 'numeric', minute: '2-digit' });
    const endTime = formatDate(event.end, event.timeZone, { hour: 'numeric', minute: '2-digit' });
    appendFact(facts, 'Time', `${startTime}–${endTime} ${event.timeZoneLabel || ''}`.trim());
    appendFact(facts, 'Location', event.location || 'See event details');
    body.appendChild(facts);

    const deadlineTime = event.registrationDeadline ? new Date(event.registrationDeadline).getTime() : NaN;
    const registrationClosed = Number.isFinite(deadlineTime) && deadlineTime <= Date.now();
    const registrationNote = document.createElement('p');
    registrationNote.className = 'event-registration-note';
    if (registrationClosed) {
      registrationNote.textContent = `Registration closed${event.registrationDeadline ? ` ${formatDate(event.registrationDeadline, event.timeZone, {
        month: 'long', day: 'numeric', year: 'numeric', hour: 'numeric', minute: '2-digit'
      })} ${event.timeZoneLabel || ''}` : ''}. Registration was required and subject to approval.`;
    } else if (event.registrationDeadline) {
      registrationNote.textContent = `Registration is required and subject to approval. Closes ${formatDate(event.registrationDeadline, event.timeZone, {
        month: 'long', day: 'numeric', year: 'numeric', hour: 'numeric', minute: '2-digit'
      })} ${event.timeZoneLabel || ''}.`;
    } else {
      registrationNote.textContent = 'Registration is required and subject to approval.';
    }
    body.appendChild(registrationNote);

    const actions = document.createElement('div');
    actions.className = 'event-actions';
    const registrationUrl = safeUrl(event.registrationUrl, false);
    if (registrationClosed) {
      makeText(actions, 'span', 'event-registration-closed', 'Registration closed');
    } else if (registrationUrl) {
      const register = makeText(actions, 'a', 'event-action', 'Register for this event');
      register.href = registrationUrl;
      register.target = '_blank';
      register.rel = 'noopener';
      register.dataset.clarityEvent = 'event_registration_click';
      const context = makeText(body, 'p', 'event-registration-context', 'Opens registration site in a new tab.');
      context.id = `${article.id}-registration-context`;
      register.setAttribute('aria-describedby', context.id);
    } else {
      makeText(actions, 'span', 'event-registration-closed', 'Registration link unavailable');
    }

    const icsUrl = safeUrl(event.eventIcsUrl, true);
    if (icsUrl) {
      const calendar = makeText(actions, 'a', 'event-action event-action--quiet', 'One-time .ics download');
      calendar.href = icsUrl;
      calendar.download = '';
      calendar.dataset.clarityEvent = 'event_ics_download';
    }
    body.appendChild(actions);

    const expandedDescription = event.description && event.description !== takeaway;
    if ((Array.isArray(event.topics) && event.topics.length > 0) || event.audience || expandedDescription) {
      const details = document.createElement('details');
      details.className = 'event-details';
      makeText(details, 'summary', '', 'Topics and intended audience');
      const content = document.createElement('div');
      content.className = 'event-details__content';
      if (expandedDescription) {
        const overview = document.createElement('section');
        makeText(overview, 'h4', '', 'Session overview');
        makeText(overview, 'p', '', event.description);
        content.appendChild(overview);
      }
      if (Array.isArray(event.topics) && event.topics.length > 0) {
        const topics = document.createElement('section');
        makeText(topics, 'h4', '', 'What participants will do');
        const list = document.createElement('ul');
        event.topics.forEach((topic) => makeText(list, 'li', '', topic));
        topics.appendChild(list);
        content.appendChild(topics);
      }
      if (event.audience) {
        const audience = document.createElement('section');
        makeText(audience, 'h4', '', 'Audience');
        makeText(audience, 'p', '', event.audience);
        content.appendChild(audience);
      }
      details.appendChild(content);
      body.appendChild(details);
    }

    article.append(dateRail, body);
    return article;
  };

  const monthGroupFor = (event) => {
    const parts = new Intl.DateTimeFormat('en', {
      timeZone: event.timeZone,
      year: 'numeric',
      month: '2-digit'
    }).formatToParts(new Date(event.start));
    const year = parts.find((part) => part.type === 'year').value;
    const month = parts.find((part) => part.type === 'month').value;
    return {
      key: `${year}-${month}|${event.timeZone}`,
      title: formatDate(event.start, event.timeZone, { month: 'long', year: 'numeric' }),
      zone: event.timeZoneLabel || event.timeZone
    };
  };

  const updateFilterCounts = () => {
    const matching = upcoming.filter(matchesDiscovery);
    filters.forEach((button) => {
      const lane = button.dataset.lane;
      const count = lane === 'all'
        ? matching.length
        : matching.filter((event) => event.lane === lane).length;
      let counter = button.querySelector('.schedule-filter__count');
      if (!counter) {
        counter = document.createElement('span');
        counter.className = 'schedule-filter__count';
        button.appendChild(counter);
      }
      counter.textContent = String(count);
      const sessionWord = count === 1 ? 'session' : 'sessions';
      button.setAttribute('aria-label', `${laneNames[lane]}, ${count} ${sessionWord}`);
    });
  };

  const renderBoard = () => {
    board.replaceChildren();
    const filtersActive = selectedLane !== 'all' || selectedTopic !== 'all' || searchText.length > 0;
    if (isSchedule) {
      updateFilterCounts();
      if (clearFilters) {
        clearFilters.hidden = !filtersActive;
        clearFilters.disabled = !filtersActive;
      }
    }
    const visible = upcoming.filter((event) => matchesDiscovery(event) &&
      (selectedLane === 'all' || event.lane === selectedLane));

    if (!visible.length) {
      const empty = document.createElement('p');
      empty.className = 'events__empty';
      empty.textContent = upcoming.length
        ? 'No sessions match your filters. Try another keyword, topic, or format, or clear filters to see all upcoming sessions.'
        : 'No upcoming sessions are currently scheduled. New dates will appear here when published.';
      board.appendChild(empty);
      if (isSchedule && filtersActive) {
        const reset = makeText(board, 'button', 'schedule-clear', 'Clear filters');
        reset.type = 'button';
        reset.addEventListener('click', resetFilters);
      }
      setStatus(upcoming.length
        ? `Showing 0 of ${upcoming.length} upcoming sessions.`
        : 'No upcoming sessions are currently scheduled.');
      return;
    }

    if (!isSchedule) {
      const limit = Number.parseInt(board.dataset.limit || '3', 10);
      const preview = visible.slice(0, Number.isFinite(limit) ? limit : 3);
      preview.forEach((event, index) => board.appendChild(renderEvent(event, index)));
      const totalWord = upcoming.length === 1 ? 'session' : 'sessions';
      setStatus(`Showing the next ${preview.length} of ${upcoming.length} upcoming ${totalWord}.`);
      return;
    }

    const monthGroups = new Map();
    visible.forEach((event) => {
      const month = monthGroupFor(event);
      if (!monthGroups.has(month.key)) monthGroups.set(month.key, { ...month, events: [] });
      monthGroups.get(month.key).events.push(event);
    });

    let eventIndex = 0;
    monthGroups.forEach((group) => {
      const section = document.createElement('section');
      section.className = 'agenda-month-group';
      const heading = document.createElement('h2');
      heading.className = 'agenda-month';
      heading.id = `agenda-${group.key.replace(/[^a-zA-Z0-9_-]/g, '-')}`;
      heading.appendChild(document.createTextNode(group.title));
      const zone = makeText(heading, 'span', 'agenda-month__zone', ` · ${group.zone}`);
      zone.setAttribute('aria-label', `Public time zone ${group.zone}`);
      section.setAttribute('aria-labelledby', heading.id);
      section.appendChild(heading);
      group.events.forEach((event) => {
        section.appendChild(renderEvent(event, eventIndex));
        eventIndex += 1;
      });
      board.appendChild(section);
    });
    const visibleWord = visible.length === 1 ? 'session' : 'sessions';
    const totalWord = upcoming.length === 1 ? 'session' : 'sessions';
    setStatus(`Showing ${visible.length} ${visibleWord} of ${upcoming.length} upcoming ${totalWord}.`);
  };

  const refreshBoard = () => {
    try { renderBoard(); } catch (error) { showError(error); }
  };

  const resetFilters = () => {
    selectedLane = 'all';
    selectedTopic = 'all';
    searchText = '';
    if (search) search.value = '';
    if (topicFilter) topicFilter.value = 'all';
    filters.forEach((button) => button.setAttribute('aria-pressed', String(button.dataset.lane === 'all')));
    refreshBoard();
    if (search) search.focus();
  };

  initScheduleControls();

  try {
    if (!data || !Array.isArray(data.events)) {
      throw new Error('The public event data is missing or malformed.');
    }

    const now = Date.now();
    upcoming = data.events
      .filter((event) => {
        if (!event || event.status !== 'Scheduled') return false;
        const start = new Date(event.start).getTime();
        const end = new Date(event.end).getTime();
        if (!Number.isFinite(start) || !Number.isFinite(end) || end < now) return false;
        if (typeof event.timeZone !== 'string' || !event.timeZone) return false;
        try {
          new Intl.DateTimeFormat('en', { timeZone: event.timeZone }).format(new Date(start));
        } catch (error) {
          return false;
        }
        return true;
      })
      .sort((left, right) => new Date(left.start) - new Date(right.start));

    if (isSchedule) {
      if (topicFilter) {
        topicLabels.forEach((label, id) => {
          const option = makeText(topicFilter, 'option', '', label);
          option.value = id;
        });
        topicFilter.addEventListener('change', () => {
          selectedTopic = topicFilter.value;
          refreshBoard();
        });
      }
      if (search) search.addEventListener('input', () => {
        searchText = search.value;
        refreshBoard();
      });
      if (clearFilters) clearFilters.addEventListener('click', resetFilters);
      filters.forEach((button) => {
        button.addEventListener('click', () => {
          selectedLane = button.dataset.lane;
          filters.forEach((filter) => {
            filter.setAttribute('aria-pressed', String(filter === button));
          });
          refreshBoard();
        });
      });
    }

    renderBoard();
  } catch (error) {
    showError(error);
  }
})();
