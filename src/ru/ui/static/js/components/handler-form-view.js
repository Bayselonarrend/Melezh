export const handlerFormView = () => ({
  formData: {
    key: '',
    method: '',
    library: '',
    function: ''
  },
  errorMessage: '',
  isLoading: false,

  // Списки
  libraries: [],
  functions: [],
  isLibrariesLoading: true,
  isFunctionsLoading: false,
  args: [],
  isArgsLoading: false,
  argsErrorMessage: '',

  async init() {
    await this.loadLibraries();
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
      this.errorMessage = `Не удалось загрузить библиотеки: ${error.message}`;
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
      this.errorMessage = `Не удалось загрузить функции: ${error.message}`;
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
    this.errorMessage = '';
    this.isLoading = true;

    try {
      const response = await fetch('/api/createHandler', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(this.formData)
      });

      if (!response.ok) throw new Error('Ошибка сервера');

      const result = await response.json();
      if (!result.result) throw new Error(result.error || 'Неизвестная ошибка');

      window.location.hash = '#handlers';
    } catch (error) {
      console.error('Ошибка при создании обработчика:', error);
      this.errorMessage = error.message;
    } finally {
      this.isLoading = false;
    }
  },

    async loadArgs(libraryName, functionName) {
    this.args = [];
    this.argsErrorMessage = '';
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

      if (!response.ok) throw new Error('Ошибка сети');

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
      this.argsErrorMessage = error.message;
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
  }
});