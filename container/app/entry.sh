#!/usr/bin/env bash
# purpose: run command or script as user

# debugging - no exit on fail
set +e

###### main control flow area ######
USER_ID=${LOCAL_USER_ID:=0}
USER_GID=${LOCAL_USER_GID:=0}

export PATH=/var/lang/bin:/usr/local/bin:/usr/bin/:/bin:/opt/bin:/usr/sbin:$PATH
export PYTHONPATH=/app/python-modules

echo "Starting with UID:GID : $USER_ID:$USER_GID"
if [ "$USER_ID" -ne "0" ]; then
    echo "Creating user and group"
    groupadd -g $USER_GID usergroup
    useradd --shell /bin/bash -u $USER_ID -g $USER_GID user
    exec /usr/local/bin/gosu $USER_ID:$USER_GID "$@"
else
    echo "Starting as root"
    exec "$@"
fi