import { handleFetchResponse } from '/js/error-fetch.js';

document.addEventListener('alpine:init', () => {
  // === Маршруты: вкладки -> хэши ===
  const HASH_ROUTES = {
    dashboard: '#dashboard',
    handlers: '#handlers',
    'handler-form': '#handler-form',
    settings: '#settings'
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
    loginPassword: '',
    loginError: false,

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

    async handleLoginSubmit() {
      this.isLoading = true;

      try {
        const response = await fetch('/ui/login', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: new URLSearchParams({
            password: this.loginPassword
          })
        });

        const result = await handleFetchResponse(response);

        if (result.success) {
          window.location.href = '/ui';
        } else {
          window.dispatchEvent(new CustomEvent('show-error', {
            detail: { message: result.message || 'Неверный пароль' }
          }));
        }
      } catch (error) {
        window.dispatchEvent(new CustomEvent('show-error', {
          detail: { message: 'Ошибка сети. Попробуйте позже.' }
        }));
      } finally {
        this.isLoading = false;
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
      this.isLoading = true; // внутренний флаг начала загрузки
      this.loadingMessage = 'Загрузка...';
      this.shouldShowLoader = false; // пока не показываем индикатор

      let showLoaderTimeout = null;

      // Устанавливаем таймер: покажем loader через 500 мс
      showLoaderTimeout = setTimeout(() => {
        this.shouldShowLoader = true; // показываем индикатор только после 500 мс
      }, 500);

      try {
        if (viewCache.has(viewName)) {
          clearTimeout(showLoaderTimeout);
          this.isLoading = false;
          this.currentView = viewCache.get(viewName);
          return;
        }

        const response = await fetch(`/views/${viewName}.html`);
        if (!response.ok) {
          const result = await handleFetchResponse(response);
          if (!result.success) throw new Error(result.message);
        }

        const html = await response.text();
        viewCache.set(viewName, html);
        this.currentView = html;

      } catch (error) {
        console.error(`Ошибка загрузки ${viewName}:`, error);
        window.dispatchEvent(new CustomEvent('show-error', { detail: { message: error.message } }));
        this.currentView = '';
      } finally {
        clearTimeout(showLoaderTimeout);

        // Скрываем loader с задержкой, если он был показан
        if (this.shouldShowLoader) {
          setTimeout(() => {
            this.isLoading = false;
            this.shouldShowLoader = false;
          }, 300); // плавное исчезновение
        } else {
          this.isLoading = false;
        }
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