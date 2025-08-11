// Управление темной темой
class ThemeManager {
    constructor() {
        this.currentTheme = localStorage.getItem('theme') || 'light';
        this.init();
    }

    init() {
        // Применяем сохраненную тему
        this.applyTheme(this.currentTheme);
        
        // Создаем кнопку переключения
        this.createToggleButton();
        
        // Добавляем обработчик события
        this.addEventListeners();
    }

    createToggleButton() {
        // Проверяем, есть ли кнопка в навбаре
        const navbarButton = document.getElementById('navbar-theme-toggle');
        if (navbarButton) {
            this.updateButtonIcon(navbarButton);
            return;
        }
        
        // Если нет навбара, создаем плавающую кнопку (для страницы логина)
        const toggleButton = document.createElement('button');
        toggleButton.id = 'theme-toggle';
        toggleButton.className = 'theme-toggle';
        toggleButton.setAttribute('aria-label', 'Переключить тему');
        toggleButton.setAttribute('title', 'Переключить тему');
        
        this.updateButtonIcon(toggleButton);
        
        document.body.appendChild(toggleButton);
    }

    updateButtonIcon(button) {
        const icon = button.querySelector('#theme-icon') || button;
        
        if (this.currentTheme === 'dark') {
            icon.textContent = '☀️'; // Солнце для переключения на светлую тему
            button.setAttribute('title', 'Переключить на светлую тему');
        } else {
            icon.textContent = '🌙'; // Луна для переключения на темную тему
            button.setAttribute('title', 'Переключить на темную тему');
        }
    }

    addEventListeners() {
        // Ищем кнопку в навбаре или плавающую кнопку
        const navbarButton = document.getElementById('navbar-theme-toggle');
        const floatingButton = document.getElementById('theme-toggle');
        
        console.log('ThemeManager: Navbar button found:', !!navbarButton);
        console.log('ThemeManager: Floating button found:', !!floatingButton);
        
        if (navbarButton) {
            navbarButton.addEventListener('click', (e) => {
                e.preventDefault();
                console.log('ThemeManager: Navbar button clicked');
                this.toggleTheme();
            });
        }
        
        if (floatingButton) {
            floatingButton.addEventListener('click', (e) => {
                e.preventDefault();
                console.log('ThemeManager: Floating button clicked');
                this.toggleTheme();
            });
        }

        // Обработчик для системных настроек темы
        if (window.matchMedia) {
            const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
            mediaQuery.addListener((e) => {
                if (!localStorage.getItem('theme')) {
                    this.applyTheme(e.matches ? 'dark' : 'light');
                }
            });
        }
    }

    toggleTheme() {
        console.log('ThemeManager: Toggling theme from', this.currentTheme);
        this.currentTheme = this.currentTheme === 'light' ? 'dark' : 'light';
        console.log('ThemeManager: New theme:', this.currentTheme);
        this.applyTheme(this.currentTheme);
        localStorage.setItem('theme', this.currentTheme);
        
        // Обновляем иконку кнопки
        const navbarButton = document.getElementById('navbar-theme-toggle');
        const floatingButton = document.getElementById('theme-toggle');
        
        if (navbarButton) {
            this.updateButtonIcon(navbarButton);
        }
        
        if (floatingButton) {
            this.updateButtonIcon(floatingButton);
        }

        // Добавляем небольшую анимацию
        document.body.style.transition = 'all 0.3s ease';
        setTimeout(() => {
            document.body.style.transition = '';
        }, 300);
    }

    applyTheme(theme) {
        document.documentElement.setAttribute('data-theme', theme);
        this.currentTheme = theme;
        
        // Обновляем мета-тег для мобильных браузеров
        let metaThemeColor = document.querySelector('meta[name="theme-color"]');
        if (!metaThemeColor) {
            metaThemeColor = document.createElement('meta');
            metaThemeColor.name = 'theme-color';
            document.head.appendChild(metaThemeColor);
        }
        
        if (theme === 'dark') {
            metaThemeColor.content = '#1a1a1a';
        } else {
            metaThemeColor.content = '#ffffff';
        }
    }

    // Метод для получения текущей темы
    getCurrentTheme() {
        return this.currentTheme;
    }

    // Метод для принудительной установки темы
    setTheme(theme) {
        if (theme === 'light' || theme === 'dark') {
            this.currentTheme = theme;
            this.applyTheme(theme);
            localStorage.setItem('theme', theme);
            
            const navbarButton = document.getElementById('navbar-theme-toggle');
            const floatingButton = document.getElementById('theme-toggle');
            
            if (navbarButton) {
                this.updateButtonIcon(navbarButton);
            }
            
            if (floatingButton) {
                this.updateButtonIcon(floatingButton);
            }
        }
    }
}

// Инициализация при загрузке страницы
document.addEventListener('DOMContentLoaded', function() {
    console.log('ThemeManager: DOM loaded, initializing...');
    
    // Небольшая задержка для гарантии, что все элементы загружены
    setTimeout(() => {
        window.themeManager = new ThemeManager();
        
        // Добавляем глобальные функции для удобства
        window.toggleTheme = () => {
            console.log('Global toggleTheme called');
            if (window.themeManager) {
                window.themeManager.toggleTheme();
            } else {
                console.error('ThemeManager not initialized');
            }
        };
        window.setTheme = (theme) => window.themeManager.setTheme(theme);
        window.getCurrentTheme = () => window.themeManager.getCurrentTheme();
        
        console.log('ThemeManager: Initialization complete');
    }, 100);
});

// Предотвращаем мигание при загрузке страницы
(function() {
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme) {
        document.documentElement.setAttribute('data-theme', savedTheme);
    } else if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
        document.documentElement.setAttribute('data-theme', 'dark');
    }
})();