FROM ubuntu:22.04

ENV OInt_URL="file:///tmp/oint.deb"
ENV Melezh_URL="file:///tmp/melezh.deb"

RUN apt-get update && \
    apt-get install -y bash wget sudo dpkg libicu-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY oint.deb /tmp/oint.deb
COPY melezh.deb /tmp/melezh.deb

# Устанавливаем пакеты
RUN sudo dpkg -i /tmp/oint.deb /tmp/melezh.deb || apt-get install -f -y
RUN sudo melezh CreateProject --path proj.melezh

# ENV MELEZH_DEBUG="1931"

EXPOSE 1921 1931

CMD ["melezh", "RunProject", "--proj", "proj.melezh", "--port", "1921", "--create", "true"]
