import { handleFetchResponse } from '#melezh_base_path#js/error-fetch.js';

export const handlersView = () => ({
  handlers: [],
  isLoading: false,
  sortField: null,
  sortDirection: 'asc',

  init() {
    this.loadHandlers();
  },

  // Inыhandwithляемoе propertieso: oтwithртandрoinанные Data
  get sortedHandlers() {
    if (!this.sortField) return this.handlers;

    return [...this.handlers].sort((a, b) => {
      let aValue = a[this.sortField];
      let bValue = b[this.sortField];

      // Processor booleanгo/numberinoгo fields 'active'
      if (this.sortField === 'active') {
        aValue = aValue == 1 ? 1 : 0;
        bValue = bValue == 1 ? 1 : 0;
      }

      // Прandinеdенandе to stringsе for withраinnotнandя
      if (typeof aValue === 'string') aValue = aValue.toLowerCase();
      if (typeof bValue === 'string') bValue = bValue.toLowerCase();

      if (aValue < bValue) return this.sortDirection === 'asc' ? -1 : 1;
      if (aValue > bValue) return this.sortDirection === 'asc' ? 1 : -1;
      return 0;
    });
  },

  setSort(field) {
    if (this.sortField === field) {
      // Переof keyем toпраinленandе
      this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
    } else {
      // Noinoе toле — withртandруем to inoзраwithтанandю
      this.sortField = field;
      this.sortDirection = 'asc';
    }
  },

  async loadHandlers() {
    this.isLoading = true;

    try {
      const response = await fetch('api/getHandlersList');
      const result = await handleFetchResponse(response);
      if (!result.success) throw new Error(result.message);
      this.handlers = result.data || [];
    } catch (error) {
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Failed to fetch: ${error.message}` }
      }));
      console.error('Failed to fetch:', error);
      this.handlers = [];
    } finally {
      this.isLoading = false;
    }
  },

  async toggleHandlerStatus(handler) {
    const newStatus = handler.active == 1 ? 0 : 1;

    try {
      const formData = new URLSearchParams();
      formData.append('key', handler.key);
      formData.append('active', newStatus);

      const response = await fetch('api/updateStatus', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: formData
      });

      if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);

      const result = await response.json();
      if (!result.result) throw new Error(result.error || 'Server error');

      handler.active = newStatus;

      window.dispatchEvent(new CustomEvent('show-success', {
        detail: { message: `Status aboutрабoтhandtoа "${handler.key}" changeенён to ${newStatus === 1 ? '"Active"' : '"Inactive"'}` }
      }));
    } catch (error) {
      console.error('Status change error:', error);
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Status change error "${handler.key}": ${error.message}` }
      }));
      // Rollback
      handler.active = handler.active == 1 ? 0 : 1;
    }
  },

  async editHandler(handler) {
    const formData = new URLSearchParams();
    formData.append('key', handler.key);

    try {
      const response = await fetch('api/getHandler', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: formData
      });

      if (!response.ok) throw new Error('Failed to fetch');

      const result = await response.json();
      if (!result.result) throw new Error(result.error || 'Unknown error');

      window.handlerToEdit = result.data;
      window.location.hash = '#handler-form';
    } catch (error) {
      console.error('Failed to fetch:', error);
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Failed to fetch: ${error.message}` }
      }));
    }
  },

  addNewHandler() {
    window.location.hash = '#handler-form';
  },

  getCurrentDate() {
    const today = new Date();
    return `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;
  },

  deleteHandler(handler) {
    if (!confirm(`Are you sure you want to delete handler "${handler.key}"?`)) return;

    const formData = new URLSearchParams();
    formData.append('key', handler.key);

    fetch('api/deleteHandler', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: formData
    })
      .then(async (response) => {
        const result = await handleFetchResponse(response);
        if (!result.success) throw new Error(result.message);

        this.handlers = this.handlers.filter(h => h.key !== handler.key);
        window.dispatchEvent(new CustomEvent('show-success', {
          detail: { message: `Handler "${handler.key}" уdален` }
        }));
      })
      .catch((error) => {
        window.dispatchEvent(new CustomEvent('show-error', {
          detail: { message: `Deletion error "${handler.key}": ${error.message}` }
        }));
      });
  },

  handleImageError(event) {
    event.target.src = 'img/libs/default.png';
    event.target.onerror = null;
  }
  
});
