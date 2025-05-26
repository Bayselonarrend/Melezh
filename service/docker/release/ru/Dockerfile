# Базовый образ
FROM ubuntu:22.04

# Обновляем систему и устанавливаем зависимости
RUN apt-get update && \
    apt-get install -y bash wget sudo dpkg libicu-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Рабочая директория
WORKDIR /app

# Укажи здесь реальные URL своих .deb пакетов
ENV OInt_URL="https://api.athenaeum.digital/tc/job/Release/lastSuccessfulBuild/artifact/1.24.0/oint_1.24.0_all_ru.deb"
ENV Melezh_URL="https://api.athenaeum.digital/tc/job/Melezh_Release/lastSuccessfulBuild/artifact/0.1.0/melezh_0.1.0_all_ru.deb"

# Скачиваем и устанавливаем пакеты
RUN wget -O packageA.deb "$OInt_URL" && \
    wget -O packageB.deb "$Melezh_URL" && \
    sudo dpkg -i packageA.deb packageB.deb || apt-get install -f -y
        
RUN sudo melezh СоздатьПроект --path proj.melezh

# Порт можно менять при запуске через -p хост:контейнер
EXPOSE 8080

# Запускаем сервер
CMD ["melezh", "ЗапуститьПроект", "--proj", "proj.melezh", "--port", "8080"]