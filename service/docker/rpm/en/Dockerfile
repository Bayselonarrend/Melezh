# Базовый образ на основе CentOS
FROM centos:8

# Обновляем систему и устанавливаем зависимости
RUN dnf makecache && \
    dnf install -y wget sudo procps which git libicu jq && \
    dnf clean all

# Установка dpkg-эмуляции
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm  && \
    yum install -y dpkg jq && \
    yum clean all

# Рабочая директория
WORKDIR /app

# URL пакетов
ENV OInt_URL="https://api.athenaeum.digital/tc/job/Release/lastSuccessfulBuild/artifact/1.24.0/oint-1.24.0-1.noarch_en.rpm"
ENV Melezh_URL="https://api.athenaeum.digital/tc/job/Melezh_Release/lastSuccessfulBuild/artifact/0.1.0/melezh-0.1.0-1.noarch_en.rpm"

# Скачиваем .deb пакеты
RUN wget -O packageA.rpm "$OInt_URL" && \
    wget -O packageB.rpm "$Melezh_URL"

# Распаковываем deb-файлы вручную без dpkg
RUN sudo rpm -ivh packageA.rpm packageB.rpm || \
    sudo dnf install -y ./packageA.rpm ./packageB.rpm

# Создаём проект
RUN melezh CreateProject --path proj.melezh

# Порт
EXPOSE 8080

# Запускаем сервер
CMD ["melezh", "RunProject", "--proj", "proj.melezh", "--port", "8080"]