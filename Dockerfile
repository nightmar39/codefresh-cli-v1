# go hub binary
FROM golang:alpine as go
RUN apk --update add ca-certificates git
RUN go install github.com/github/hub@latest

# python yq binary
FROM six8/pyinstaller-alpine:alpine-3.6-pyinstaller-v3.4 as yq
ARG YQ_VERSION=2.10.0
ENV PATH="/pyinstaller:$PATH"
RUN pip install yq==${YQ_VERSION}
RUN pyinstaller --noconfirm --onefile --log-level DEBUG --clean --distpath /tmp/ $(which yq)

# Main
FROM node:12.22.11-alpine3.15

RUN apk --update add --no-cache ca-certificates git curl bash jq

COPY --from=go /go/bin/hub /usr/local/bin/hub
COPY --from=yq /tmp/yq /usr/local/bin/yq

WORKDIR /cf-cli

COPY package.json /cf-cli
COPY yarn.lock /cf-cli
COPY check-version.js /cf-cli
COPY run-check-version.js /cf-cli

RUN yarn install --prod --frozen-lockfile && \
    yarn cache clean

COPY . /cf-cli

RUN yarn generate-completion

RUN ln -s $(pwd)/lib/interface/cli/codefresh /usr/local/bin/codefresh

RUN codefresh components update --location components
ENTRYPOINT ["codefresh"]
