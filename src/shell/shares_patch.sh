#!/bin/bash
if [ "$(id -u)" -ne 0 ]; then
    echo "Current user must be root."
    exit 1
fi
declare -A controllers
# files to patch
controllers['sessions_controller.rb']=sanitize
controllers['api/base_controller.rb']='user = oauth2'
# folder where patched files are located
controller_dir=/opt/aspera/shares/u/shares/app/controllers
shares_lib_dir=/opt/aspera/shares/u/shares/lib
auth_lib_file=special_shares_auth.rb
auth_config=special_shares_auth.json
backup_ext=.bak
set -e
case "$1" in
    apply)
        echo "Applying patch"
        if test ! -f $(dirname "$0")/$auth_config; then
            echo "Config file not found"
            exit 1
        fi
        for controller in "${!controllers[@]}"; do
            controller_file=$controller_dir/$controller
            controller_backup=$controller_file$backup_ext
            controller_tmp=$controller_file.tmp
            if grep -q 'BEGIN PATCH' $controller_file; then
                echo "Patch already applied to $controller"
                break
            fi
            if test -f $controller_backup; then
                echo "Backup already exists for $controller"
                break
            fi
            echo "Patching $controller"
            line=$(grep -n "${controllers[$controller]}" $controller_file|cut -f1 -d:)
            head -n $(($line+1)) $controller_file > $controller_tmp
            cat $(dirname "$0")/shares_patch.rb >> $controller_tmp
            tail -n +$(($line+2)) $controller_file >> $controller_tmp
            mv $controller_file $controller_backup
            mv $controller_tmp $controller_file
        done
        cp $(dirname "$0")/$auth_lib_file $(dirname "$0")/$auth_config $shares_lib_dir
        /etc/init.d/aspera-shares restart
        echo "Patched"
        ;;
    revert)
        echo "Reverting patch"
        for controller in "${!controllers[@]}"; do
            #echo "$key ${test_var[$key]}"
            controller_file=$controller_dir/$controller
            controller_backup=$controller_file$backup_ext
            if test ! -f $controller_backup; then
                echo "Backup not found for $controller"
                break
            fi
            mv -f $controller_backup $controller_file
        done
        rm -f $shares_lib_dir/$auth_lib_file $shares_lib_dir/$auth_config
        /etc/init.d/aspera-shares restart
        echo "Restored"
        ;;
    *)
        echo "Usage: $0 [apply|revert]"
        exit 1
        ;;
esac
