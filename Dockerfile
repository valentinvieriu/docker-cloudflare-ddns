ARG S6_ARCH
FROM valentinvieriu/s6-alpine:3.11-${S6_ARCH:-amd64}

RUN apk add --no-cache jq curl bind-tools

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 CF_API=https://api.cloudflare.com/client/v4 RRTYPE=A

COPY root /
