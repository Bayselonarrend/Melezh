document.addEventListener('alpine:init', () => {
  // === Маршруты: вкладки -> хэши ===
  const HASH_ROUTES = {
    dashboard: '#dashboard',
    handlers: '#handlers',
    'handler-form': '#handler-form'
  };

  // === Кэш для загруженных представлений ===
  const viewCache = new Map();

  // Основное приложение
  Alpine.data('app', () => ({
    isSidebarOpen: false,
    activeTab: 'dashboard',
    currentView: '',
    isLoading: false,
    loadingMessage: 'Загрузка...',
    errorMessage: '',

    init() {
      this.checkViewport();
      window.addEventListener('resize', () => this.checkViewport());

      // Считываем текущий хэш из URL
      const hash = window.location.hash.replace(/^#/, '');
      const tab = Object.entries(HASH_ROUTES).find(
        ([_, value]) => value === `#${hash}`
      )?.[0] || 'dashboard';

      this.activeTab = tab;
      this.loadView(tab);

      // Настройка маршрутизации
      this.setupRouter();
    },

    setupRouter() {
      const handleRoute = () => {
        const hash = window.location.hash.replace(/^#/, '');
        const tab = Object.entries(HASH_ROUTES).find(
          ([_, value]) => value === `#${hash}`
        )?.[0] || 'dashboard';

        if (this.activeTab !== tab) {
          this.activeTab = tab;
          this.loadView(tab);
        }
      };

      window.addEventListener('hashchange', handleRoute);
      handleRoute();
    },

    checkViewport() {
      if (this.isMobile()) {
        if (this.isSidebarOpen) this.closeSidebar();
      } else {
        this.openSidebar();
      }
    },

    toggleSidebar() {
      this.isSidebarOpen = !this.isSidebarOpen;
    },

    openSidebar() {
      this.isSidebarOpen = true;
    },

    closeSidebar() {
      this.isSidebarOpen = false;
    },

    isMobile() {
      return window.innerWidth < 768;
    },

    setActiveTab(tab) {
      const hash = HASH_ROUTES[tab] || '#dashboard';

      this.activeTab = tab;
      window.location.hash = hash;

      if (this.isMobile()) this.closeSidebar();
      this.loadView(tab);
    },

    async loadView(viewName) {
      this.isLoading = true;
      this.loadingMessage = `Загрузка ${viewName}...`;
      this.errorMessage = '';

      try {
        // Используем кэшированную версию, если есть
        if (viewCache.has(viewName)) {
          this.currentView = viewCache.get(viewName);
          this.isLoading = false;
          return;
        }

        const response = await fetch(`/views/${viewName}.html`);

        if (!response.ok) {
          throw new Error(`Ошибка HTTP: ${response.status}`);
        }

        const html = await response.text();
        viewCache.set(viewName, html);
        this.currentView = html;
      } catch (error) {
        console.error(`Ошибка загрузки ${viewName}:`, error);
        this.errorMessage = `Не удалось загрузить "${viewName}": ${error.message}`;
        this.currentView = '';
      } finally {
        this.isLoading = false;
      }
    }
  }));

  // Компонент сайдбара
  Alpine.data('sidebar', () => ({
    logout() {
      const form = document.createElement('form');
      form.method = 'POST';
      form.action = '/ui/logout';
      document.body.appendChild(form);
      form.submit();
    }
  }));

});