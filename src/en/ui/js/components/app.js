import { handleFetchResponse } from '#melezh_base_path#js/error-fetch.js';

export const globalState = {
  isInitialized: false,
  tooltipEl: null
};

export const logsState = {
  handler: '',
  date: '',
};

document.addEventListener('alpine:init', () => {
  const HASH_ROUTES = {
    'dashboard': '#dashboard',
    'handlers': '#handlers',
    'handler-form': '#handler-form',
    'logs': '#logs',
    'log-details': '#log',
    'settings': '#settings',
    'extensions': '#extensions',
    'code-editor': '#code-editor',
    'scheduler': '#scheduler'
  };

  const viewCache = new Map();

  function getActiveTabFromHash(routes) {
    const hash = window.location.hash.replace(/^#/, '').split('?')[0];
    return Object.entries(routes).find(
      ([_, routeValue]) => routeValue === `#${hash}`
    )?.[0] || 'dashboard';
  }

  Alpine.data('app', () => ({
    isSidebarOpen: false,
    activeTab: 'dashboard',
    currentView: '',
    isLoading: false,
    shouldShowLoader: false,
    loadingMessage: 'Loading...',
    loginPassword: '',
    loginError: false,

    init() {
      this.checkViewport();
      window.addEventListener('resize', () => this.checkViewport());

      this.activeTab = getActiveTabFromHash(HASH_ROUTES);
      this.loadView(this.activeTab);
      this.setupRouter();
    },

    setupRouter() {
      const handleRoute = () => {
        const newTab = getActiveTabFromHash(HASH_ROUTES);

        if (this.activeTab !== newTab) {

          if (globalState.tooltipEl) {
            globalState.tooltipEl.classList.remove('opacity-100');
            globalState.tooltipEl.classList.add('opacity-0');
          }
          this.activeTab = newTab;
          this.loadView(newTab);
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
        const response = await fetch('ui/login', {
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
          window.location.reload();
        } else {
          window.dispatchEvent(new CustomEvent('show-error', {
            detail: { message: result.message || 'Incorrect password' }
          }));
        }
      } catch (error) {
        window.dispatchEvent(new CustomEvent('show-error', {
          detail: { message: 'Network error. Try again later.' }
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
      globalState.isInitialized = false;
      this.isLoading = true;
      this.loadingMessage = 'Loading...';
      this.shouldShowLoader = false;

      let showLoaderTimeout = null;

      showLoaderTimeout = setTimeout(() => {
        this.shouldShowLoader = true;
      }, 500);

      try {
        if (viewCache.has(viewName)) {
          clearTimeout(showLoaderTimeout);
          this.isLoading = false;
          this.currentView = viewCache.get(viewName);
          return;
        }

        const response = await fetch(`views/${viewName}.html`);
        if (!response.ok) {
          const result = await handleFetchResponse(response);
          if (!result.success) throw new Error(result.message);
        }

        const html = await response.text();
        viewCache.set(viewName, html);
        this.currentView = html;

      } catch (error) {
        console.error(`Failed to fetch ${viewName}:`, error);
        window.dispatchEvent(new CustomEvent('show-error', { detail: { message: error.message } }));
        this.currentView = '';
      } finally {
        clearTimeout(showLoaderTimeout);

        if (this.shouldShowLoader) {
          setTimeout(() => {
            this.isLoading = false;
            this.shouldShowLoader = false;
          }, 300);
        } else {
          this.isLoading = false;
        }
      }
    }
  }));

  Alpine.data('sidebar', () => ({
    logout() {
      const form = document.createElement('form');
      form.method = 'POST';
      form.action = 'ui/logout';
      document.body.appendChild(form);
      form.submit();
    }
  }));


  Alpine.directive('tooltip', (el, { expression }, { evaluate, cleanup }) => {

    let tooltipEl = document.getElementById('global-tooltip');

    if (!tooltipEl) {
      tooltipEl = document.createElement('div');
      tooltipEl.id = 'global-tooltip';
      tooltipEl.classList.add(
        'fixed', 'z-50',
        'bg-black', 'text-white',
        'text-xs', 'py-1', 'px-2', 'rounded',
        'max-w-xs', 'break-words',
        'pointer-events-none',
        'opacity-0', 'transition-opacity', 'duration-200'
      );
      tooltipEl.style.whiteSpace = 'normal';
      tooltipEl.style.transform = 'translate(-50%, 10px)';
      document.body.appendChild(tooltipEl);
    }

    globalState.tooltipEl = tooltipEl;

    const showTooltip = (e) => {
      const text = evaluate(expression);
      const rect = e.target.getBoundingClientRect();
      const tooltipWidth = 160;
      const tooltipHeight = 32;

      tooltipEl.textContent = text;
      tooltipEl.style.top = `${rect.top + window.scrollY - tooltipHeight - 8}px`;
      tooltipEl.style.left = `${rect.left + window.scrollX + rect.width / 2}px`;
      tooltipEl.classList.remove('opacity-0');
      tooltipEl.classList.add('opacity-100');
    };

    const hideTooltip = () => {
      tooltipEl.classList.remove('opacity-100');
      tooltipEl.classList.add('opacity-0');
    };

    el.addEventListener('mouseenter', showTooltip);
    el.addEventListener('mouseleave', hideTooltip);

    cleanup(() => {
      el.removeEventListener('mouseenter', showTooltip);
      el.removeEventListener('mouseleave', hideTooltip);
    });
  });

});
