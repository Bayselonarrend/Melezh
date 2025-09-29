import { handleFetchResponse } from '#melezh_base_path#js/error-fetch.js';


export const extensionsView = () => ({
  extensions: [],
  isLoading: false,

  async init() {
    await this.loadExtensions();
  },

  async loadExtensions() {
    this.isLoading = true;

    try {

      const response = await fetch('api/getExtensionsList');
      const result = await handleFetchResponse(response);
      if (!result.success) throw new Error(result.message);
      this.extensions = result.data || [];

    } catch (error) {

      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Ошибка загрузки: ${error.message}` }
      }));
      console.error('Ошибка загрузки:', error);
      this.extensions = [];

    } finally {
      this.isLoading = false;
    }
  },

  async updateExtensionssCache() {
    this.isLoading = true;

    try {

      const response = await fetch('api/updateExtensionssCache');
      const result = await handleFetchResponse(response);
      if (!result.success) throw new Error(result.message);

    } catch (error) {

      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Ошибка загрузки: ${error.message}` }
      }));
      console.error('Ошибка загрузки:', error);

    } finally {
      this.isLoading = false;
      await this.loadExtensions();
    }
  },
  
});