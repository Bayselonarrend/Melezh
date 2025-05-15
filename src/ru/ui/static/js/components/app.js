document.addEventListener('alpine:init', () => {
  // Кэш для загруженных представлений
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
      this.loadView('dashboard');
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
    
    async loadView(viewName) {
      this.activeTab = viewName;
      this.isLoading = true;
      this.loadingMessage = `Загрузка ${viewName}...`;
      this.errorMessage = '';
      
      try {
        // Используем кэшированную версию если есть
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