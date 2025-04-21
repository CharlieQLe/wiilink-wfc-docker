# Build wwfc payloads

FROM python:3.13.2-bullseye AS wwfc-patcher
ARG WFC_DOMAIN=mariokart.com

COPY --from=devkitpro/devkitppc:20250102 /opt/devkitpro /opt/devkitpro
ENV DEVKITPRO=/opt/devkitpro
ENV DEVKITPPC=${DEVKITPRO}/devkitPPC
ENV DEVKITARM=${DEVKITPRO}/devkitARM
ENV PATH=${DEVKITPRO}/tools/bin:$PATH

RUN pip install cryptography==44.0.0
COPY ./wfc-patcher-wii /wfc-patcher-wii
WORKDIR /wfc-patcher-wii
RUN ./make.sh --all -- -j$(nproc) -DWWFC_DOMAIN=\"${WFC_DOMAIN}\"

# Build wwfc-server

FROM golang:1.24.2-alpine3.21 AS wwfc-server

COPY ./wfc-server /wfc-server
WORKDIR /wfc-server
RUN go build

# Package files

FROM scratch AS final

WORKDIR /app

COPY --from=wwfc-server /wfc-server/wwfc /wfc-server/game_list.tsv /wfc-server/motd.txt .
COPY --from=wwfc-patcher /wfc-patcher-wii/dist /app/payload
COPY --from=wwfc-patcher /wfc-patcher-wii/patch/build/*.txt /app/codes/

ENTRYPOINT ["/app/wwfc"]