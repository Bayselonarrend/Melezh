import { handleFetchResponse } from '/js/error-fetch.js';
import { globalState } from '/js/components/app.js';

const cachedState = {
  handler: '',
  date: '',
};

export const logsView = () => ({
  // State
  handler: cachedState.handler,
  date: cachedState.date,
  filtersCollapsed: false,
  isEventsLoading: false,
  isEventsLoaded: false,
  events: [],
  eventsErrorMessage: '',

  get hasFilters() {
    return this.handler.trim() !== '' && this.date.trim() !== '';
  },

  toggleFilters() {
    this.filtersCollapsed = !this.filtersCollapsed;
  },

  init() {
    const parseHash = () => {
      const urlParams = new URLSearchParams(window.location.hash.split('?')[1] || '');
      const handler = urlParams.get('handler') || cachedState.handler || '';
      const date = urlParams.get('date') || cachedState.date || '';

      this.handler = handler;
      this.date = date;

      cachedState.handler = handler;
      cachedState.date = date;
    };

    parseHash();

    if (!globalState.isInitialized) {
      globalState.isInitialized = true;
      this.loadEvents();
    }
  },

  async loadEvents() {
    if (!this.hasFilters) return;

    const newHash = `#logs?handler=${encodeURIComponent(this.handler)}&date=${encodeURIComponent(this.date)}`;
    if (window.location.hash !== newHash) {
      window.history.pushState(null, '', newHash);
    }

    this.isEventsLoading = true;
    this.eventsErrorMessage = '';

    try {
      const url = `/api/getEvents?handler=${encodeURIComponent(this.handler)}&date=${encodeURIComponent(this.date)}`;
      const response = await fetch(url);
      const result = await handleFetchResponse(response);

      if (!result.success) throw new Error(result.message);

      this.events = result.data || [];
    } catch (error) {
      console.error('Failed to fetch:', error);
      this.eventsErrorMessage = error.message;
    } finally {
      this.isEventsLoaded = true;
      this.isEventsLoading = false;
      cachedState.handler = this.handler;
      cachedState.date = this.date;
    }
  },

  getStatusText(status) {
    if (status >= 200 && status < 300) return 'Success';
    if (status >= 400 && status < 500) return 'Client error';
    if (status >= 500) return 'Server error';
    return 'Unknown status';
  },

});
