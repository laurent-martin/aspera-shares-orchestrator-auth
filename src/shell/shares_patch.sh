#!/bin/bash
# patch shares to support special auth
if [ "$(id -u)" -ne 0 ]; then
    echo "Current user must be root."
    exit 1
fi
# main folder of patch
patch_dir="$(dirname "$0")"
# main folder under which patched files are located
controller_dir=/opt/aspera/shares/u/shares/app/controllers
# extension of backup files (original files)
backup_ext=.bak
# regex of line after which to insert patch
declare -A src_line_match
# code to insert
declare -A src_patch_file
# files to patch, key is path relative to $controller_dir
src_line_match['login_base_controller.rb']=' user = User'
src_patch_file['login_base_controller.rb']=shares_patch_login.rb
src_line_match['api/base_controller.rb']=' if user$'
src_patch_file['api/base_controller.rb']=shares_patch_api.rb
# folder where $auth_lib_file and $auth_config are located
shares_lib_dir=/opt/aspera/shares/u/shares/lib
auth_lib_file=special_shares_auth.rb
auth_config=special_shares_auth.json
# fail on any error
set -e
case "$1" in
    apply)
        echo "Applying patch"
        echo "Checking $patch_dir/$auth_config"
        if test ! -f $patch_dir/$auth_config; then
            echo "Config file not found: create $auth_config from template."
            exit 1
        fi
        if jq --version > /dev/null 2>&1; then
            jq < $patch_dir/$auth_config > /dev/null
        else
            echo "jq not found, no check performed"
        fi
        # loop on key (controller file path under $controller_dir)
        for src_rel_path in "${!src_line_match[@]}"; do
            src_full_path=$controller_dir/$src_rel_path
            src_backup=$src_full_path$backup_ext
            src_patched_tmp=$src_full_path.tmp
            if grep -q 'BEGIN PATCH' $src_full_path; then
                echo "Patch already applied to $src_rel_path"
                break
            fi
            if test -f $src_backup; then
                echo "Backup already exists for $src_rel_path: $src_backup"
                break
            fi
            echo "Patching $src_rel_path"
            line=$(grep -n "${src_line_match[$src_rel_path]}" $src_full_path|cut -f1 -d:)
            # keep all lines including the one matching the regex
            head -n $(($line+0)) $src_full_path > $src_patched_tmp
            # insert patch
            cat $patch_dir/"${src_patch_file[$src_rel_path]}" >> $src_patched_tmp
            # keep lines after the one matching the regex
            tail -n +$(($line+1)) $src_full_path >> $src_patched_tmp
            # save backup
            mv $src_full_path $src_backup
            # replace with patched file
            mv $src_patched_tmp $src_full_path
        done
        # copy lib and config files
        cp $patch_dir/$auth_lib_file $patch_dir/$auth_config $shares_lib_dir
        /etc/init.d/aspera-shares restart
        echo "Patched"
        ;;
    revert)
        for src_rel_path in "${!src_line_match[@]}"; do
            src_full_path=$controller_dir/$src_rel_path
            src_backup=$src_full_path$backup_ext
            if test -f $src_backup; then
                echo "Reverting $src_rel_path"
                mv -f $src_backup $src_full_path
            else
                echo "Backup not found for $src_rel_path" 1>&2
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
