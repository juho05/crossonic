# Login: docker login ghcr.io -u juho05
# Build and deploy: docker buildx build --platform linux/arm64,linux/amd64 --tag ghcr.io/juho05/crossonic-server:latest --push .

# Build
FROM --platform=$BUILDPLATFORM golang:alpine AS build
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download && go mod verify

COPY . .
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o bin/crossonic-server .

# Run
FROM alpine AS h-finanzen
ARG BUILDPLATFORM
WORKDIR /
COPY --from=build /app/bin/crossonic-server /crossonic-server

EXPOSE 8080

CMD [ "/crossonic-server" ]
