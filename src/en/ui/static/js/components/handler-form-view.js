import { handleFetchResponse } from '/js/error-fetch.js';

export const handlerFormView = () => ({
  formData: {
    key: '',
    method: '',
    library: '',
    function: '',
    originalKey: ''
  },
  isLoading: false,
  isEditMode: false,

  // Lists
  libraries: [],
  functions: [],
  isLibrariesLoading: true,
  isFunctionsLoading: false,
  args: [],
  isArgsLoading: false,

  async init() {
    if (window.handlerToEdit) {
      this.isEditMode = true;

      await this.loadLibraries();

      this.formData = {
        key: window.handlerToEdit.key,
        method: window.handlerToEdit.method,
        library: window.handlerToEdit.library,
        function: window.handlerToEdit.function,
        originalKey: window.handlerToEdit.key
      };

      await this.loadFunctions(this.formData.library);

      this.formData.function = window.handlerToEdit.function;
      await this.loadArgs(this.formData.library, this.formData.function);

      this.args = this.args.map(arg => {
        const savedArg = window.handlerToEdit.args.find(a => a.arg === arg.arg.replace(/^--/, ''));

        if (savedArg) {
          return {
            ...arg,
            active: true,
            value: savedArg.value || '',
            strict: savedArg.strict == 1 || false
          };
        } else {
          return {
            ...arg,
            active: false,
            value: '',
            strict: false
          };
        }
      });

      window.handlerToEdit = null;
    } else {
      await this.loadLibraries();
    }
  },

  async loadLibraries() {
    try {

      const response = await fetch('/api/getLibraries');
      const result = await handleFetchResponse(response);

      if (!result.success) throw new Error(result.message);
      this.libraries = result.data || [];

    } catch (error) {
      console.error('Error upload libraries:', error);
      window.dispatchEvent(new CustomEvent('show-error', { detail: { message: error.message } }));
    } finally {
      this.isLibrariesLoading = false;
    }
  },

  async loadFunctions(libraryName) {
    this.functions = [];
    this.formData.function = '';
    this.isFunctionsLoading = true;

    try {
      const formData = new URLSearchParams();
      formData.append('library', libraryName);

      const response = await fetch('/api/getFunctions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: formData
      });

      const result = await handleFetchResponse(response);
      if (!result.success) throw new Error(result.message);
      this.functions = result.data || [];

    } catch (error) {
      console.error('Error upload фунtoцandй:', error);
      window.dispatchEvent(new CustomEvent('show-error', { detail: { message: `Not succeeded загрузandть functions: ${error.message}` } }));
    } finally {
      this.isFunctionsLoading = false;
    }
  },

  onLibraryChange(libraryName) {
    if (libraryName) {
      this.loadFunctions(libraryName);
    } else {
      this.functions = [];
      this.args = [];
      this.formData.function = '';
    }
  },

  async submitForm() {

    if (!this.formData.key.trim()) {
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: 'Field "Key" aboutязательbut for filledandя' }
      }));
      return;
    }

    if (!this.formData.method) {
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: 'Field "Method" aboutязательbut for filledandя' }
      }));
      return;
    }

    if (!this.formData.library) {
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: 'Field "Library" aboutязательbut for filledandя' }
      }));
      return;
    }

    if (!this.formData.function) {
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: 'Field "Function" aboutязательbut for filledandя' }
      }));
      return;
    }
    this.isLoading = true;

    try {
      const activeArgs = this.args
        .filter(arg => arg.active)
        .map(({ arg, value, strict }) => ({ arg, value, strict }));

      const payload = {
        key: this.formData.key,
        method: this.formData.method,
        library: this.formData.library,
        function: this.formData.function,
        originalKey: this.formData.originalKey || null,
        args: activeArgs
      };

      const url = this.isEditMode ? '/api/editHandler' : '/api/createHandler';

      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
      });

      const result = await handleFetchResponse(response);
      if (!result.success) throw new Error(result.message);

      // Success!
      window.dispatchEvent(new CustomEvent('show-success', {
        detail: { message: 'Successfully withхраnotbut!' }
      }));

      window.location.hash = '#handlers';

    } catch (error) {
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: error.message }
      }));
    } finally {
      this.isLoading = false;
    }
  },

  async loadArgs(libraryName, functionName) {
    this.args = [];
    this.isArgsLoading = true;

    try {
      const formData = new URLSearchParams();
      formData.append('library', libraryName);
      formData.append('function', functionName);

      const response = await fetch('/api/getArgs', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: formData
      });

      const result = await handleFetchResponse(response);
      if (!result.success) throw new Error(result.message);

      this.args = result.data.map(arg => ({
        ...arg,
        value: '',
        strict: false,
        active: false
      }));

    } catch (error) {
      console.error('Error upload argumentoin:', error);
      window.dispatchEvent(new CustomEvent('show-error', { detail: { message: `Error upload argumentoin: ${error.message}` } }));
    } finally {
      this.isArgsLoading = false;
    }
  },

  onFunctionChange(functionName) {
    if (functionName && this.formData.library) {
      this.loadArgs(this.formData.library, functionName);
    } else {
      this.args = [];
    }
  },

  cancel() {
    window.location.hash = '#handlers';
  },

  async generateNewKey() {
    try {

      const response = await fetch('/api/getNewKey');
      const result = await handleFetchResponse(response);

      if (!result.success) throw new Error(result.message);
      this.formData.key = result.data;

    } catch (error) {
      window.dispatchEvent(new CustomEvent('show-error', { detail: { message: `Error геnotрацandand of key: ${error.message}` } }));
    }
  },

  handleImageError(event) {
    // Заменяем notwithущеwithтinующую andtohetoу to заглушtoу
    event.target.src = '/img/libs/default.png';
    event.target.onerror = null; // Преdoтinращаем endless loop, if stub too not загрузandтwithя
  }
});
