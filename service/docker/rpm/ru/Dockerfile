# Базовый образ
FROM almalinux:8

# Установка базовых зависимостей
RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm  && \
    dnf makecache && \
    dnf install -y wget sudo procps which git libicu jq dpkg && \
    dnf clean all

# Рабочая директория
WORKDIR /app

# URL пакетов
ENV OInt_URL="https://api.athenaeum.digital/tc/job/Release/lastSuccessfulBuild/artifact/1.24.0/oint-1.24.0-1.noarch_ru.rpm"
ENV Melezh_URL="https://api.athenaeum.digital/tc/job/Melezh_Release/lastSuccessfulBuild/artifact/0.1.0/melezh-0.1.0-1.noarch_ru.rpm"

# Скачиваем .deb пакеты
RUN wget -O packageA.rpm "$OInt_URL" && \
    wget -O packageB.rpm "$Melezh_URL"

# Распаковываем deb-файлы вручную без dpkg
RUN sudo rpm -ivh packageA.rpm packageB.rpm || \
    sudo dnf install -y ./packageA.rpm ./packageB.rpm

# Создаём проект
RUN sudo melezh СоздатьПроект --path proj.melezh

# Порт
EXPOSE 8080

# Запускаем сервер
CMD ["melezh", "ЗапуститьПроект", "--proj", "proj.melezh", "--port", "8080"]