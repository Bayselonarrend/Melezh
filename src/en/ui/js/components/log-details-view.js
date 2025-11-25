import { handleFetchResponse } from '#melezh_base_path#js/error-fetch.js';
import { jsonViewer } from '#melezh_base_path#js/json-viewer.js';

export const logDetailsView = () => ({
  isLoading: true,
  eventData: null,
  errorMessage: '',
  hasFiles() {
    return Array.isArray(this.eventData?.melezh_request_files) && this.eventData.melezh_request_files.length > 0;
  },
  async init() {
    this.isLoading = true;
    this.errorMessage = '';
    const urlParams = new URLSearchParams(window.location.hash.split('?')[1] || '');
    const key = urlParams.get('key');

    if (!key) {
      this.errorMessage = 'Not specified key events';
      this.isLoading = false;
      return;
    }

    try {
      const response = await fetch(`api/getEventData?key=${encodeURIComponent(key)}`);
      const result = await handleFetchResponse(response);

      if (!result.success) throw new Error(result.message);
      this.eventData = result.data;
    } catch (error) {
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Failed to fetch: ${error.message}` }
      }));
      this.errorMessage = error.message;
    } finally {
      this.isLoading = false;
    }
  },
  getStatusText(status) {
    if (status === 0) return 'LocalLaunch';
    if (status >= 200 && status < 300) return 'Success';
    if (status >= 400 && status < 500) return 'Client error';
    if (status >= 500) return 'Server error';
    return 'Unknown status';
  },

  renderJson(value) {
    return jsonViewer.renderValue(value, 0);
  },
});
