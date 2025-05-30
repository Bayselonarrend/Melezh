import { handleFetchResponse } from '/js/error-fetch.js';

export const settingsPage = () => ({
  settings: [],
  isLoading: false,

  async init() {
    await this.loadSettings();
  },

  async loadSettings() {
    this.isLoading = true;

    try {
      const response = await fetch('/api/getSettings');
      const result = await handleFetchResponse(response);

      if (!result.success) throw new Error(result.message);

      this.settings = result.data || [];

    } catch (error) {
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Failed to fetch: ${error.message}` }
      }));
      console.error('Failed to fetch:', error);
      this.settings = [];

    } finally {
      this.isLoading = false;
    }
  },

  async saveSettings() {
    const payload = {};

    this.settings.forEach(setting => {
      payload[setting.name] = setting.value;
    });

    try {
      const response = await fetch('/api/saveSettings', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
      });

      const result = await handleFetchResponse(response);

      if (!result.success) throw new Error(result.message);

      window.dispatchEvent(new CustomEvent('show-success', {
        detail: { message: 'Settings successfully saved!' }
      }));

    } catch (error) {
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Error while saving settings: ${error.message}` }
      }));
      console.error('Error while saving settings:', error);
    }
  }
});
