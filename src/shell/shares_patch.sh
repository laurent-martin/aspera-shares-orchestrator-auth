#!/bin/bash
patched=/opt/aspera/shares/u/shares/app/controllers/sessions_controller.rb
backup=$patched.bak
lib=/opt/aspera/shares/u/shares/lib
added=special_shares_auth.rb
config=special_shares_auth.json
set -e
case "$1" in
    apply)
        echo "Applying patch"
        tmpfile=$patched.tmp
        if grep -q 'BEGIN PATCH' $patched; then
            echo "Patch already applied"
            exit 1
        fi
        if test ! -f $(dirname "$0")/$config; then
            echo "Config file not found"
            exit 1
        fi
        line=$(grep -n sanitize $patched|cut -f1 -d:)
        head -n $(($line+1)) $patched > $tmpfile
        cat $(dirname "$0")/shares_patch.rb >> $tmpfile
        tail -n +$(($line+2)) $patched >> $tmpfile
        if test -f $backup; then
            echo "Backup already exists"
            exit 1
        fi
        cp $(dirname "$0")/$added $lib
        cp $(dirname "$0")/$config $lib
        mv $patched $backup
        mv $tmpfile $patched
        /etc/init.d/aspera-shares restart
        echo "Done"
        ;;
    revert)
        echo "Reverting patch"
        if test ! -f $backup; then
            echo "Backup not found"
            exit 1
        fi
        mv -f $backup $patched
        rm -f $lib/$added
        /etc/init.d/aspera-shares restart
        echo "Done"
        ;;
    *)
        echo "Usage: $0 [apply|revert]"
        exit 1
        ;;
esac
