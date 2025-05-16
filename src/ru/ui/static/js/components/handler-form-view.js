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

  // Списки
  libraries: [],
  functions: [],
  isLibrariesLoading: true,
  isFunctionsLoading: false,
  args: [],
  isArgsLoading: false,
  argsErrorMessage: '',

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
      if (!response.ok) throw new Error('Ошибка сети');
      const result = await response.json();
      if (!result.result) throw new Error(result.error || 'Неизвестная ошибка');

      this.libraries = result.data || [];
    } catch (error) {
      console.error('Ошибка загрузки библиотек:', error);
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

      if (!response.ok) throw new Error('Ошибка сети');

      const result = await response.json();

      if (!result.result) throw new Error(result.error || 'Неизвестная ошибка');

      this.functions = result.data || [];
    } catch (error) {
      console.error('Ошибка загрузки функций:', error);
      window.dispatchEvent(new CustomEvent('show-error', { detail: { message: `Не удалось загрузить функции: ${error.message}` } }));
    } finally {
      this.isFunctionsLoading = false;
    }
  },

  onLibraryChange(libraryName) {
    if (libraryName) {
      this.loadFunctions(libraryName);
    } else {
      this.functions = [];
      this.formData.function = '';
    }
  },

  async submitForm() {
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

      const result = await response.json();
      if (!result.result) throw new Error(result.error || 'Неизвестная ошибка');

      // Успех!
      window.dispatchEvent(new CustomEvent('show-success', {
        detail: { message: 'Успешно сохранено!' }
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

      const result = await response.json();

      if (!result.result) throw new Error(result.error || 'Неизвестная ошибка');

      this.args = result.data.map(arg => ({
        ...arg,
        value: '',
        strict: false,
        active: false
      }));
    } catch (error) {
      console.error('Ошибка загрузки аргументов:', error);
      window.dispatchEvent(new CustomEvent('show-error', { detail: { message: `Ошибка загрузки аргументов: ${error.message}` } }));
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
      if (!response.ok) throw new Error('Ошибка сети');

      const result = await response.json();
      if (!result.result) throw new Error(result.error || 'Не удалось получить ключ');

      this.formData.key = result.data;
    } catch (error) {
      window.dispatchEvent(new CustomEvent('show-error', { detail: { message: `Ошибка генерации ключа: ${error.message}` } }));
    }
  }
});