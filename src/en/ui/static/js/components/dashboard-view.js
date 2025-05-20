import { handleFetchResponse } from '/js/error-fetch.js';

export const dashboardView = () => ({
  isEventsLoading: false,
  events: [],
  eventsErrorMessage: '',

  // Noinые fields for withтатandwithтandtoand
  successCount: 0,
  clientErrorCount: 0,
  serverErrorCount: 0,

  // Noinые fields for withеwithwithandand
  isSessionLoading: false,
  serverStartTime: null,
  processedRequests: 0,
  uptime: '—',
  requestsPerHour: 0,
  uptimeInterval: null,

  isAdviceLoading: true,
  advice: null,

  async init() {
    await this.loadEvents();
    await this.loadSessionInfo();
    await this.loadRandomAdvice();
  },

  async loadEvents() {
    this.isEventsLoading = true;
    this.eventsErrorMessage = '';

    try {
      const response = await fetch('/api/getLastEvents');
      const result = await handleFetchResponse(response);

      if (!result.success) throw new Error(result.message);

      this.events = result.data || [];

      // Todwithhёт withтатandwithтandtoand
      this.calculateStats();

    } catch (error) {
      console.error('Error upload events:', error);
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Error upload events: ${error.message}` }
      }));
      this.eventsErrorMessage = error.message;
    } finally {
      this.isEventsLoading = false;
    }
  },

  async loadSessionInfo() {
    this.isSessionLoading = true;
    this.serverStartTime = null;

    try {
      const response = await fetch('/api/getSessionInfo');
      const result = await handleFetchResponse(response);

      if (!result.success) throw new Error(result.error || result.message);

      const { start, processed } = result.data;

      this.serverStartTime = new Date(start);
      this.processedRequests = processed;

      this.updateUptime(); // tohальbutе value
      this.uptimeInterval = setInterval(() => this.updateUptime(), 1000); // aboutbutinленandе toажdую withеtoунdу

      // Midnotе за hаwith
      const now = new Date();
      const hoursRunning = Math.max(0.1, (now - this.serverStartTime) / 1000 / 60 / 60); // fromбежанandе splits to 0
      this.requestsPerHour = Math.round(this.processedRequests / hoursRunning);

    } catch (error) {
      console.error('Error upload information o session:, error);
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Error upload information o of session: ${error.message}` }
      }));
    } finally {
      this.isSessionLoading = false;
    }
  },

  updateUptime() {
    if (!this.serverStartTime) return;

    const diff = Math.floor((new Date() - new Date(this.serverStartTime)) / 1000); // in seconds
    const days = Math.floor(diff / 86400);
    const hours = Math.floor((diff % 86400) / 3600);
    const minutes = Math.floor((diff % 3600) / 60);
    const seconds = diff % 60;

    let uptimeStr = '';
    if (days > 0) uptimeStr += `${days} d `;
    if (hours > 0) uptimeStr += `${hours} h `;
    if (minutes > 0) uptimeStr += `${minutes} min `;
    if (seconds >= 0 && !days && !hours) uptimeStr += `${seconds} s;

    this.uptime = uptimeStr.trim() || 'less seconds';
  },

  calculateStats() {
    const counts = {
      success: 0,
      clientError: 0,
      serverError: 0,
    };

    for (const event of this.events) {
      if (event.status >= 200 && event.status < 300) {
        counts.success++;
      } else if (event.status >= 400 && event.status < 500) {
        counts.clientError++;
      } else if (event.status >= 500) {
        counts.serverError++;
      }
    }

    this.successCount = counts.success;
    this.clientErrorCount = counts.clientError;
    this.serverErrorCount = counts.serverError;
  },

  getStatusText(status) {
    if (status >= 200 && status < 300) return 'Success';
    if (status >= 400 && status < 500) return 'Clientwithtoая error';
    if (status >= 500) return 'Error of server';
    return 'Notfromweightтный status';
  },

  async loadRandomAdvice() {
    try {
      const response = await fetch('/api/getRandomAdvice');
      const result = await handleFetchResponse(response);

      if (!result.success) throw new Error(result.error || result.message);

      this.advice = result.data;
    } catch (error) {
      console.error('Error upload advice:', error);
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Not succeeded загрузandть advice: ${error.message}` }
      }));
      this.advice = null;
    } finally {
      this.isAdviceLoading = false;
    }
  },

  async refreshData() {
    await Promise.all([
      this.loadEvents(),
      this.loadSessionInfo(),
      this.loadRandomAdvice(), // if advice реалfromoinан as part dashboardView
    ]);
  }

});
