import { handleFetchResponse } from '#melezh_base_path#js/error-fetch.js';

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

  // State dropdown'oin
  libraryDropdownOpen: false,
  functionDropdownOpen: false,

  // Lists
  libraries: [],
  functions: [],
  isLibrariesLoading: true,
  isFunctionsLoading: false,
  args: [],
  isArgsLoading: false,

  // Search
  librarySearch: '',
  functionSearch: '',

  // Геттеры for filterацandand
  get filteredLibraries() {
    if (!this.librarySearch.trim()) return this.libraries;
    const term = this.librarySearch.toLowerCase();
    return this.libraries.filter(lib =>
      lib.title.toLowerCase().includes(term) ||
      lib.name.toLowerCase().includes(term)
    );
  },

  get filteredFunctions() {
    if (!this.functionSearch.trim()) return this.functions;
    const term = this.functionSearch.toLowerCase();
    return this.functions.filter(func =>
      func.title.toLowerCase().includes(term) ||
      func.name.toLowerCase().includes(term)
    );
  },

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

      await this.loadFunctions(this.formData.library, true);
      await this.loadArgs(this.formData.library, this.formData.function);

      this.args = this.args.map(arg => {
        const savedArg = window.handlerToEdit.args.find(a => a.arg === arg.arg.replace(/^--/, ''));
        if (savedArg) {
          return {
            ...arg,
            active: true,
            value: savedArg.value || '',
            strict: savedArg.strict == 1
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
      const response = await fetch('api/getLibraries');
      const result = await handleFetchResponse(response);
      if (!result.success) throw new Error(result.message);
      this.libraries = result.data || [];
    } catch (error) {
      console.error('Error loading libraries:', error);
      window.dispatchEvent(new CustomEvent('show-error', { detail: { message: error.message } }));
    } finally {
      this.isLibrariesLoading = false;
    }
  },

  async loadFunctions(libraryName, shouldPreserveFunction = false) {
    this.functions = [];
    if (!shouldPreserveFunction) {
      this.formData.function = '';
    }
    this.isFunctionsLoading = true;
    this.functionSearch = '';

    try {
      const payload = {
        library: libraryName
      };

      const response = await fetch('api/getFunctions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });

      const result = await handleFetchResponse(response);
      if (!result.success) throw new Error(result.message);
      this.functions = result.data || [];
    } catch (error) {
      console.error('Function loading error:', error);
      window.dispatchEvent(new CustomEvent('show-error', { detail: { message: `Failed to fetch: ${error.message}` } }));
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

  openLibraryDropdown() {

    if (this.isLibrariesLoading || this.isLoading) return;

    if (this.libraryDropdownOpen){
      this.closeLibraryDropdown();
      return;
    }

    this.librarySearch = '';
    this.libraryDropdownOpen = true;
    this.$nextTick(() => {
      if (this.$refs.librarySearchInput) {
        this.$refs.librarySearchInput.focus();
      }
    });
  },

  closeLibraryDropdown() {
    this.libraryDropdownOpen = false;
  },

  openFunctionDropdown() {

    if (!this.formData.library || this.isFunctionsLoading || this.isLoading) return;

    if (this.functionDropdownOpen){
      this.closeFunctionDropdown();
      return;
    }

    this.functionSearch = '';
    this.functionDropdownOpen = true;
    this.$nextTick(() => {
      if (this.$refs.functionSearchInput) {
        this.$refs.functionSearchInput.focus();
      }
    });
  },

  closeFunctionDropdown() {
    this.functionDropdownOpen = false;
  },

  selectLibrary(name) {
    this.formData.library = name;
    this.closeLibraryDropdown();
    this.onLibraryChange(name);
  },

  selectFunction(name) {
    this.formData.function = name;
    this.closeFunctionDropdown();
    this.onFunctionChange(name);
  },

  async loadArgs(libraryName, functionName) {
    this.args = [];
    this.isArgsLoading = true;

    try {
      const payload = {
        library: libraryName,
        function: functionName
      };

      const response = await fetch('api/getArgs', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
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
      console.error('Argument loading error:', error);
      window.dispatchEvent(new CustomEvent('show-error', { detail: { message: `Failed to fetch: ${error.message}` } }));
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

  async submitForm() {
    if (!this.formData.key.trim()) {
      window.dispatchEvent(new CustomEvent('show-error', { detail: { message: 'The "Key" field is required' } }));
      return;
    }
    if (!this.formData.method) {
      window.dispatchEvent(new CustomEvent('show-error', { detail: { message: 'The "Method" field is required' } }));
      return;
    }
    if (!this.formData.library) {
      window.dispatchEvent(new CustomEvent('show-error', { detail: { message: 'The "Library" field is required' } }));
      return;
    }
    if (!this.formData.function) {
      window.dispatchEvent(new CustomEvent('show-error', { detail: { message: 'The "Function" field is required' } }));
      return;
    }

    this.isLoading = true;

    try {
      const activeArgs = this.args
        .filter(arg => arg.active)
        .map(({ arg, value, strict }) => ({
          arg: arg.replace(/^--/, ''),
          value,
          strict
        }));

      const payload = {
        key: this.formData.key,
        method: this.formData.method,
        library: this.formData.library,
        function: this.formData.function,
        originalKey: this.isEditMode ? this.formData.originalKey : null,
        args: activeArgs
      };

      const url = this.isEditMode ? 'api/editHandler' : 'api/createHandler';

      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });

      const result = await handleFetchResponse(response);
      if (!result.success) throw new Error(result.message);

      window.dispatchEvent(new CustomEvent('show-success', { detail: { message: 'Successfully saved!' } }));
      window.location.hash = '#handlers';
    } catch (error) {
      window.dispatchEvent(new CustomEvent('show-error', { detail: { message: error.message } }));
    } finally {
      this.isLoading = false;
    }
  },

  cancel() {
    window.location.hash = '#handlers';
  },

  async generateNewKey() {
    try {
      const response = await fetch('api/getNewKey');
      const result = await handleFetchResponse(response);
      if (!result.success) throw new Error(result.message);
      this.formData.key = result.data;
    } catch (error) {
      window.dispatchEvent(new CustomEvent('show-error', { detail: { message: `Key generation error: ${error.message}` } }));
    }
  },

  handleImageError(event) {
    event.target.src = 'img/libs/default.png';
    event.target.onerror = null;
  }
});
