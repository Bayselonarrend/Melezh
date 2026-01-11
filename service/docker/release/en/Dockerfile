FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y bash wget sudo dpkg libicu-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV OInt_URL="https://github.com/Bayselonarrend/OpenIntegrations/releases/download/1.32.0/oint_1.32.0_all_en.deb"
ENV Melezh_URL="https://github.com/Bayselonarrend/Melezh/releases/download/0.9.0/melezh_0.9.0_all_en.deb"

RUN wget -O packageA.deb "$OInt_URL" && \
    wget -O packageB.deb "$Melezh_URL" && \
    sudo dpkg -i packageA.deb packageB.deb || apt-get install -f -y
        
RUN sudo melezh CreateProject --path proj.melezh

# ENV MELEZH_DEBUG="1931"

EXPOSE 1921 1931

CMD ["melezh", "RunProject", "--proj", "proj.melezh", "--port", "1921", "--create", "true"]