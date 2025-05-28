# Базовый образ
FROM ubuntu:22.04

# Аргументы для версий
ARG OINT_VERSION
ARG MELEZH_VERSION
ARG LANG=en

# Установка URL на основе версий
ENV OInt_URL="file:///tmp/oint.deb"
ENV Melezh_URL="file:///tmp/melezh.deb"

# Обновляем систему и устанавливаем зависимости
RUN apt-get update && \
    apt-get install -y bash wget sudo dpkg libicu-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Рабочая директория
WORKDIR /app

# Копируем deb-файлы внутрь контейнера (контекст сборки)
COPY oint.deb /tmp/oint.deb
COPY melezh.deb /tmp/melezh.deb

# Устанавливаем пакеты
RUN sudo dpkg -i /tmp/oint.deb /tmp/melezh.deb || apt-get install -f -y

# Создание проекта зависит от языка
RUN if [ "$LANG" = "en" ]; then \
        sudo melezh CreateProject --path proj.melezh; \
    else \
        sudo melezh СоздатьПроект --path proj.melezh; \
    fi

# Порт можно менять при запуске через -p хост:контейнер
EXPOSE 8080

# Запуск сервера зависит от языка
CMD if [ "$LANG" = "en" ]; then \
        melezh RunProject --proj proj.melezh --port 8080; \
    else \
        melezh ЗапуститьПроект --proj proj.melezh --port 8080; \
    fi