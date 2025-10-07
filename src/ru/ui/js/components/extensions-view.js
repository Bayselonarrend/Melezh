import { handleFetchResponse } from '#melezh_base_path#js/error-fetch.js';


export const extensionsView = () => ({
  extensions: [],
  isLoading: false,
  
  showCreateModal: false,
  createName: '',
  createCatalog: '',
  catalogs: [],
  isCreating: false,
  createError: '',

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

  async updateExtensionsCache() {
    this.isLoading = true;
    try {
      const response = await fetch('api/updateExtensionsCache');
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

  async openCreateModal() {
    this.createName = '';
    this.createCatalog = '';
    this.createError = '';
    this.showCreateModal = true;
    this.isCreating = false;
    this.catalogs = [];
    try {
      const response = await fetch('api/getExtensionsCatalogs');
      const result = await handleFetchResponse(response);
      if (!result.success) throw new Error(result.message);
      this.catalogs = result.data || [];
      if (this.catalogs.length > 0) this.createCatalog = this.catalogs[0];
    } catch (error) {
      this.createError = `Ошибка загрузки каталогов: ${error.message}`;
    }
  },

  closeCreateModal() {
    this.showCreateModal = false;
    this.createName = '';
    this.createCatalog = '';
    this.createError = '';
    this.isCreating = false;
  },

  async createExtension() {
    if (!this.createName.trim() || !this.createCatalog) {
      this.createError = 'Заполните все поля';
      return;
    }
    this.isCreating = true;
    this.createError = '';
    try {
      const response = await fetch('api/createExtension', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: this.createName.trim(),
          catalog: this.createCatalog
        })
      });
      
      const result = await handleFetchResponse(response);
      if (!result.success) throw new Error(result.message);
      this.closeCreateModal();
      await this.loadExtensions();

    } catch (error) {
      this.createError = `Ошибка создания: ${error.message}`;
    } finally {
      this.isCreating = false;
    }
  },

  deleteExtension(extension) {

    if (!confirm(`Вы уверены, что хотите удалить расширение "${extension.name}"?`)) return;

    fetch('api/deleteExtension', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
        body: JSON.stringify({
          name: extension.name,
        })
    })
      .then(async (response) => {
        const result = await handleFetchResponse(response);
        if (!result.success) throw new Error(result.message);

        this.extensions = this.extensions.filter(e => e.name !== extension.name);

        window.dispatchEvent(new CustomEvent('show-success', {
          detail: { message: `Расширение "${extension.name}" удалено` }
        }));
      })
      .catch((error) => {
        window.dispatchEvent(new CustomEvent('show-error', {
          detail: { message: `Ошибка при удалении "${extension.name}": ${error.message}` }
        }));
      });
  },
});