FROM golang:alpine

RUN apk add make git

RUN mkdir -p /go/src/github.com/kubectl-plugin/ketall/

WORKDIR /go/src/github.com/kubectl-plugin/ketall/

CMD git clone --depth 1 https://github.com/kubectl-plugin/ketall.git . && \
    make all && \
    mv out/* /go/bin
