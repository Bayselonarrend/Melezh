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
        detail: { message: `Failed to fetch: ${error.message}` }
      }));
      console.error('Failed to fetch:', error);
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
        detail: { message: `Failed to fetch: ${error.message}` }
      }));
      console.error('Failed to fetch:', error);
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
      this.createError = `Failed to fetch catalogs: ${error.message}`;
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
      this.createError = 'Fill in all fields';
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
      this.createError = `Creation error: ${error.message}`;
    } finally {
      this.isCreating = false;
    }
  },

  deleteExtension(extension) {

    if (!confirm(`Are you sure you want to delete the extension named "${extension.name}"?`)) return;

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

        // Уdаляем from list
        this.extensions = this.extensions.filter(e => e.name !== extension.name);

        window.dispatchEvent(new CustomEvent('show-success', {
          detail: { message: `Extension "${extension.name}" deleted` }
        }));
      })
      .catch((error) => {
        window.dispatchEvent(new CustomEvent('show-error', {
          detail: { message: `Deletion error "${extension.name}": ${error.message}` }
        }));
      });
  },
});
