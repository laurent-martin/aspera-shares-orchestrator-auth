#!/bin/bash
if [ "$(id -u)" -ne 0 ]; then
    echo "Current user must be root."
    exit 1
fi
declare -A ctrl_line_match
declare -A ctrl_patch
# files to patch
ctrl_line_match['sessions_controller.rb']=' login$'
ctrl_line_match['api/base_controller.rb']=' if user$'
ctrl_patch['sessions_controller.rb']=shares_patch_web.rb
ctrl_patch['api/base_controller.rb']=shares_patch_api.rb
# location of patch files
patch_dir="$(dirname "$0")"
# folder where patched files are located
controller_dir=/opt/aspera/shares/u/shares/app/controllers
# patch common code will be here
shares_lib_dir=/opt/aspera/shares/u/shares/lib
auth_lib_file=special_shares_auth.rb
auth_config=special_shares_auth.json
backup_ext=.bak
set -e
case "$1" in
    apply)
        echo "Applying patch"
        if test ! -f $patch_dir/$auth_config; then
            echo "Config file not found"
            exit 1
        fi
        echo "Checking $patch_dir/$auth_config"
        if jq --version > /dev/null 2>&1; then
            jq < $patch_dir/$auth_config > /dev/null
        else
            echo "jq not found, no check performed"
        fi
        # loop on key (file path)
        for controller in "${!ctrl_line_match[@]}"; do
            controller_file=$controller_dir/$controller
            controller_backup=$controller_file$backup_ext
            controller_tmp=$controller_file.tmp
            if grep -q 'BEGIN PATCH' $controller_file; then
                echo "Patch already applied to $controller"
                break
            fi
            if test -f $controller_backup; then
                echo "Backup already exists for $controller: $controller_backup"
                break
            fi
            echo "Patching $controller"
            line=$(grep -n "${ctrl_line_match[$controller]}" $controller_file|cut -f1 -d:)
            head -n $(($line+0)) $controller_file > $controller_tmp
            cat $patch_dir/"${ctrl_patch[$controller]}" >> $controller_tmp
            tail -n +$(($line+1)) $controller_file >> $controller_tmp
            mv $controller_file $controller_backup
            mv $controller_tmp $controller_file
        done
        cp $patch_dir/$auth_lib_file $patch_dir/$auth_config $shares_lib_dir
        /etc/init.d/aspera-shares restart
        echo "Patched"
        ;;
    revert)
        for controller in "${!ctrl_line_match[@]}"; do
            controller_file=$controller_dir/$controller
            controller_backup=$controller_file$backup_ext
            if test -f $controller_backup; then
                echo "Reverting $controller"
                mv -f $controller_backup $controller_file
            else
                echo "Backup not found for $controller" 1>&2
            fi
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
