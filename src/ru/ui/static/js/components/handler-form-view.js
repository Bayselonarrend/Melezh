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
  // Если есть данные для редактирования
  if (window.handlerToEdit) {
    // Загружаем библиотеки сначала
    await this.loadLibraries();

    // Теперь библиотеки точно загружены
    this.formData = { ...window.handlerToEdit };

    // Загружаем функции для этой библиотеки
    await this.loadFunctions(this.formData.library);

    // Устанавливаем функцию
    this.formData.function = window.handlerToEdit.function;

await this.loadArgs(this.formData.library, this.formData.function);

    // Проставляем значения из handlerToEdit.args
    this.args = this.args.map(arg => {
      const savedArg = window.handlerToEdit.args.find(a => a.arg === arg.name.replace(/^--/, ''));

      if (savedArg) {
        return {
          ...arg,
          active: true, // если аргумент есть в данных — он активен
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
    // Обычная загрузка при создании нового обработчика
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
    // Подготовка данных: добавляем args к formData
    const activeArgs = this.args
      .filter(arg => arg.active)
      .map(({ name, value, strict }) => ({ name, value, strict }));

    const payload = {
      ...this.formData,
      args: activeArgs
    };

    const response = await fetch('/api/createHandler', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
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