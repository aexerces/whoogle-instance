#!/bin/ash

# create $USER group and user with UID and GID
adduser -g "$GID" \
        -u "$UID" \
        -D \
        -h "$HOMEN" \
        -s /bin/bash \
        "$USERN"

chown -R "$UID":"$GID" "$HOMEN"
chown -R "${UID}":"${GID}" /var/lib/tor

exec gosu "$USERN" "$@"
