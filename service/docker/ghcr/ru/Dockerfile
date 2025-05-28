# Базовый образ
FROM ubuntu:22.04

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
RUN sudo melezh СоздатьПроект --path proj.melezh

EXPOSE 1921

# Запуск сервера зависит от языка
CMD ["melezh", "ЗапуститьПроект", "--proj", "proj.melezh", "--port", "1921"]
