import { handleFetchResponse } from '#melezh_base_path#js/error-fetch.js';

export const settingsPage = () => ({
  settings: [],
  isLoading: false,

  async init() {
    await this.loadSettings();
  },

  async loadSettings() {
    this.isLoading = true;

    try {
      const response = await fetch('api/getSettings');
      const result = await handleFetchResponse(response);

      if (!result.success) throw new Error(result.message);

      this.settings = result.data || [];

    } catch (error) {
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Ошибка загрузки: ${error.message}` }
      }));
      console.error('Ошибка загрузки:', error);
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
      const response = await fetch('api/saveSettings', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
      });

      const result = await handleFetchResponse(response);

      if (!result.success) throw new Error(result.message);

      window.dispatchEvent(new CustomEvent('show-success', {
        detail: { message: 'Настройки успешно сохранены!' }
      }));

    } catch (error) {
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Ошибка при сохранении настроек: ${error.message}` }
      }));
      console.error('Ошибка при сохранении настроек:', error);
    }
  }
});