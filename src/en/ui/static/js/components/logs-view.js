import { handleFetchResponse } from '/js/error-fetch.js';
import { globalState } from '/js/components/app.js';

const cachedState = {
  handler: '',
  date: '',
};

export const logsView = () => ({

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

    const urlParams = new URLSearchParams(window.location.hash.split('?')[1] || '');
    cachedState.handler = urlParams.get('handler') || '';
    cachedState.date = urlParams.get('date') || '';

    this.$nextTick(() => {
      this.handler = cachedState.handler;
      this.date = cachedState.date;

      if (!globalState.isInitialized) {
        globalState.isInitialized = true;
        this.loadEvents();
      }
    });
  },

  async loadEvents() {

    if (!this.handler.trim() || !this.date.trim()) return;

    const focusedElement = document.activeElement;

    const newHash = `#logs?handler=${encodeURIComponent(this.handler)}&date=${encodeURIComponent(this.date)}`;
    if (window.location.hash !== newHash) {
      window.history.pushState(null, '', newHash);
    }

    cachedState.handler = this.handler;
    cachedState.date = this.date;

    this.isEventsLoading = true;

    try {
      const url = `/api/getEvents?handler=${encodeURIComponent(this.handler)}&date=${encodeURIComponent(this.date)}`;
      const response = await fetch(url);
      const result = await handleFetchResponse(response);

      this.events = result.data || [];
      this.eventsErrorMessage = '';
    } catch (error) {
      this.eventsErrorMessage = error.message;
    } finally {
      this.isEventsLoading = false;
      this.isEventsLoaded = true;

      // Inowithwithтаtoinлandinаем фotoуwith
      this.$nextTick(() => {
        if (focusedElement && focusedElement.tagName === 'INPUT') {
          focusedElement.focus();
        }
      });
    }
  },

  getStatusText(status) {
    if (status >= 200 && status < 300) return 'Success';
    if (status >= 400 && status < 500) return 'Client error';
    if (status >= 500) return 'Server error';
    return 'Unknown status';
  },

});
