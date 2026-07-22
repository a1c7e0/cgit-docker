FROM alpine:latest AS builder

ARG CGIT_VERSION=1.3.1

RUN apk add --no-cache \
    git gcc make musl-dev \
    asciidoc xmlto docbook-xsl libxslt \
    cpio python3 \
    curl xz patch \
    openssl-dev curl-dev expat-dev zlib-dev gettext-dev \
    libzip-dev pkgconf

# Download and extract cgit
WORKDIR /src
RUN curl -L https://github.com/zx2c4/cgit/archive/refs/tags/v${CGIT_VERSION}.tar.gz | tar xz && \
    mv cgit-${CGIT_VERSION} cgit

# Use cgit's own mechanism to fetch the correct git version
WORKDIR /src/cgit
RUN make get-git NO_LUA=1

# Build and install cgit
RUN make CGIT_SCRIPT_PATH=/usr/share/webapps/cgit \
         CGIT_DATA_PATH=/usr/share/webapps/cgit \
         NO_LUA=1 \
         NO_REGEX=NeedsStartEnd \
         NO_GETTEXT=1 \
         DESTDIR=/build \
         all install

# ---- Runtime stage ----
FROM alpine:latest

RUN apk add --no-cache \
    git git-daemon fcgiwrap nginx spawn-fcgi \
    highlight python3 py3-pip py3-pygments groff \
    openssh-server openssh-client \
    bash inotify-tools

RUN pip3 install --break-system-packages markdown

RUN adduser -D -s /home/git/git-shell-wrapper git && \
    passwd -u git

RUN mkdir -p /var/run/sshd /home/git/.ssh && \
    chmod 700 /home/git/.ssh && \
    chown -R git:git /home/git
RUN mkdir -p /var/lib/git /var/cache/cgit && \
    chown -R git:git /var/lib/git /var/cache/cgit

# Copy built cgit from staging
COPY --from=builder /build/usr/share/webapps/cgit /usr/share/webapps/cgit

# Filters from cgit upstream
COPY filters/ /var/www/cgit/filters/
RUN chmod +x /var/www/cgit/filters/about-formatting.sh \
             /var/www/cgit/filters/syntax-highlighting.py \
             /var/www/cgit/filters/html-converters/*

COPY nginx.conf /etc/nginx/http.d/default.conf
COPY sshd_config /etc/ssh/sshd_config
COPY git-shell-wrapper.sh /home/git/git-shell-wrapper
RUN chown git:git /home/git/git-shell-wrapper && \
    chmod +x /home/git/git-shell-wrapper
COPY sync-keys.sh /home/git/sync-keys.sh
RUN chown git:git /home/git/sync-keys.sh && \
    chmod +x /home/git/sync-keys.sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80 2222
VOLUME ["/var/lib/git"]

ENTRYPOINT ["/entrypoint.sh"]
