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

      // Убеdandмwithя, that all values — stringsand
      this.settings = (result.data || []).map(setting => ({
        ...setting,
        value: String(setting.value)
      }));

    } catch (error) {
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Error upload settings: ${error.message}` }
      }));
      console.error('Error upload settings:', error);
      this.settings = [];

    } finally {
      this.isLoading = false;
    }
  },

  async saveSettings() {
    const payload = {};

    this.settings.forEach(setting => {
      payload[setting.name] = setting.value; // remains as string
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
        detail: { message: 'Settings successfully withхраnotны!' }
      }));

    } catch (error) {
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Error when withхраnotнandand settings: ${error.message}` }
      }));
      console.error('Error when withхраnotнandand settings:', error);
    }
  }
});
