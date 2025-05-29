FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y bash wget sudo dpkg libicu-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV OInt_URL="https://github.com/Bayselonarrend/OpenIntegrations/releases/download/%1/oint_%1_all_ru.deb"
ENV Melezh_URL="https://github.com/Bayselonarrend/Melezh/releases/download/%2/melezh_%2_all_ru.deb"

RUN wget -O packageA.deb "$OInt_URL" && \
    wget -O packageB.deb "$Melezh_URL" && \
    sudo dpkg -i packageA.deb packageB.deb || apt-get install -f -y
        
RUN sudo melezh СоздатьПроект --path proj.melezh

EXPOSE 1921

CMD ["melezh", "ЗапуститьПроект", "--proj", "proj.melezh", "--port", "1921"]