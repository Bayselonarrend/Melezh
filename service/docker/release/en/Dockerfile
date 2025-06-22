FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y bash wget sudo dpkg libicu-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV OInt_URL="https://github.com/Bayselonarrend/OpenIntegrations/releases/download/1.25.0/oint_1.25.0_all_en.deb"
ENV Melezh_URL="https://github.com/Bayselonarrend/Melezh/releases/download/0.2.1/melezh_0.2.1_all_en.deb"

RUN wget -O packageA.deb "$OInt_URL" && \
    wget -O packageB.deb "$Melezh_URL" && \
    sudo dpkg -i packageA.deb packageB.deb || apt-get install -f -y
        
RUN sudo melezh CreateProject --path proj.melezh

EXPOSE 1921

CMD ["melezh", "RunProject", "--proj", "proj.melezh", "--port", "1921"]