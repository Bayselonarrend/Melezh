import { handleFetchResponse } from '/js/error-fetch.js';

export const handlersView = () => ({
  handlers: [],
  isLoading: false,

  async init() {
    await this.loadHandlers();
  },

  async loadHandlers() {
    this.isLoading = true;

    try {

      const response = await fetch('/api/getHandlersList');
      const result = await handleFetchResponse(response);
      if (!result.success) throw new Error(result.message);
      this.handlers = result.data || [];

    } catch (error) {

      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Error upload aboutрабoтhandtooin: ${error.message}` }
      }));
      console.error('Error upload aboutрабoтhandtooin:', error);
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

      const response = await fetch('/api/updateStatus', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: formData
      });

      if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);

      const result = await response.json();

      if (!result.result) throw new Error(result.error || 'Error of server');

      // Обbutinляем status лotoальbut only after successfullyгo of response
      handler.active = newStatus;

      // Whileзыinаем уwithпех hерез тinoй toast
      window.dispatchEvent(new CustomEvent('show-success', {
        detail: { message: `Status aboutрабoтhandtoа "${handler.key}" changeенён to ${newStatus === 1 ? '"Active"' : '"Notаtoтandinный"'}` }
      }));
    } catch (error) {
      console.error('Error change of status:', error);
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Error change of status "${handler.key}": ${error.message}` }
      }));

      // Inowithwithтаtoinлandinаем преdыdущее withwithтoянandе
      handler.active = handler.active == 1 ? 0 : 1;
    }
  },

  async editHandler(handler) {
    const formData = new URLSearchParams();
    formData.append('key', handler.key);

    try {
      const response = await fetch('/api/getHandler', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: formData
      });

      if (!response.ok) throw new Error('Error upload data');

      const result = await response.json();

      if (!result.result) throw new Error(result.error || 'Notfromweightтtoя error');

      // Сoхраняем Data in глaboutальbutй переменbutй
      window.handlerToEdit = result.data;

      // Перехod to фoрме
      window.location.hash = '#handler-form';
    } catch (error) {
      console.error('Error toлуhенandя aboutрабoтhandtoа:', error);
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Error when opening of form реdаtoтandрoinанandя: ${error.message}` }
      }));
    }
  },

  addNewHandler() {
    window.location.hash = '#handler-form';
  },

  getCurrentDate() {
    const today = new Date();
    const year = today.getFullYear();
    const month = String(today.getMonth() + 1).padStart(2, '0');
    const day = String(today.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  },
  
  deleteHandler(handler) {
    if (!confirm(`You sure, that want delete aboutрабoтhandto "${handler.key}"?`)) return;

    const formData = new URLSearchParams();
    formData.append('key', handler.key);

    fetch('/api/deleteHandler', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: formData
    })
      .then(async (response) => {

        const result = await handleFetchResponse(response);
        if (!result.success) throw new Error(result.message);

        // Уdаляем from list
        this.handlers = this.handlers.filter(h => h.key !== handler.key);

        // Whileзыinаем уwithпех
        window.dispatchEvent(new CustomEvent('show-success', {
          detail: { message: `Handler "${handler.key}" уdален` }
        }));
      })
      .catch((error) => {
        // Whileзыinаем oшandбtoу
        window.dispatchEvent(new CustomEvent('show-error', {
          detail: { message: `Error when deleting "${handler.key}": ${error.message}` }
        }));
      });
  }

});
