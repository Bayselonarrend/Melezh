FROM almalinux:9

ENV OInt_URL="file:///tmp/oint.rpm"
ENV Melezh_URL="file:///tmp/melezh.rpm"

RUN dnf upgrade -y && \
    dnf install -y bash wget sudo icu && \
    dnf clean all && \
    rm -rf /var/cache/dnf

WORKDIR /app

COPY oint.rpm /tmp/oint.rpm
COPY melezh.rpm /tmp/melezh.rpm

RUN dnf install -y /tmp/oint.rpm /tmp/melezh.rpm || (dnf check-update && exit 1)
RUN sudo melezh СоздатьПроект --path proj.melezh

# ENV MELEZH_DEBUG="1931"

EXPOSE 1921 1931

CMD ["melezh", "ЗапуститьПроект", "--proj", "proj.melezh", "--port", "1921", "--create", "true"]