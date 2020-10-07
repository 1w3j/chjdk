#!/usr/bin/env bash

# usage:
# chjdk [-l] [jdkfoldername]

# shellcheck disable=SC1090
source ~/1w3j/functions.sh

JDK_PATH=/opt/jdk
JFX_PATH=/opt/openjfx
JAVA_BIN_PATH=/usr/bin/java
number=0

msg "Using \`java\` path: ${JAVA_BIN_PATH}"
msg "Using JDK folder path: ${JDK_PATH}"
msg "Using OpenJFX folder path: ${JFX_PATH}"

print_usage() {
    cat <<EOF

Usage: ${0##*/} [-l|--list] [number]
Link the java* executable binary file located at JDK_PATH/{release}/{version}/bin to JAVA_BIN_PATH, this script was
necessary since Arch Linux repositories does not provide fully implement JDK releases, thus the need to download
compressed archives from the official Oracle website, after that, a \`tar xvzf -C /opt/jdk\` would be executed. However,
many applications require different versions of JDK releases, for that reason, a folder structure to store all JDK
binaries must be implemented.
Options:
        -l,--list                   List all detected jdk folders in JDK_PATH
        number                      The selected number from the listed JDKs
EOF
}

list_jdks(){
    msg "These jdks were detected:"
    for jdk in "${JDK_PATH}"/*; do
        number=$((number+1)) #increment by one
        echo "${number}) ${jdk}"
    done
}

chjdk(){
    local jdks selected_jdk full_jdk_bin_path full_jdk_bin_path_array
    if [[ -d ${JDK_PATH} ]]; then
        if [[ ! ${*} = 0 ]] && [[ ! "${1}" = "-h" ]] && [[ ! "${1}" = "--help" ]]; then
            if [[ "${1}" == "-l" ]] || [[ "${1}" == "--list" ]]; then
                list_jdks
            else
                jdks=()
                for jdk in "${JDK_PATH}"/*; do
                    jdks=("${jdks[@]}" "${jdk}");
                done
                # Checking if ${number} has actually a numeric value and that the 'number' passed is actually in the list
                if [[ "${1}" =~ ^[0-9]+$ ]] && [[ "${1}" -le ${#jdks[@]} ]]; then
                    selected_jdk=${jdks[$((${1}-1))]}
                    selected_jdk_version=$(basename ${selected_jdk})
                    full_jdk_bin_path_array=("${selected_jdk}"/*/bin/java) # the array () expands the glob
                    full_jdk_bin_path="$(printf "%s ${full_jdk_bin_path_array[*]}")"
                    [[ -e /opt/defaultjdk ]] && warn "Removing /opt/defaultjdk" && sudo rm -i /opt/defaultjdk
                    [[ -e /opt/defaultjfx ]] && warn "Removing /opt/defaultjfx" && sudo rm -i /opt/defaultjfx
                    [[ -e ${JAVA_BIN_PATH} ]] && warn "Removing ${JAVA_BIN_PATH}" && sudo rm -i ${JAVA_BIN_PATH}
                    # if sudo rm -i was successful or JAVA_BIN_PATH was already externally removed, then proceed
                    # shellcheck disable=SC2181
                    if [[ ${?} -eq 0 ]] || [[ ! -e ${JAVA_BIN_PATH} ]]; then
                        warn "${JAVA_BIN_PATH} was removed"
                        msg Linking \""${full_jdk_bin_path}"\" to \"${JAVA_BIN_PATH}\"
                        sudo ln -fs "${full_jdk_bin_path## }" ${JAVA_BIN_PATH} # trimming leading whitespace
                        msg Linking \""${selected_jdk}"\" to \"/opt/defaultjdk\"
                        sudo ln -fs "${selected_jdk}"/*/ /opt/defaultjdk
                        if [[ -e "${JFX_PATH}/${selected_jdk_version}" ]]; then
                            msg Linking \""${JFX_PATH}/${selected_jdk_version}"\" to \"/opt/defaultjfx\"
                            sudo ln -fs "${JFX_PATH}/${selected_jdk_version}"/*/lib /opt/defaultjfx
                        else
                            warn "Selected JDK respective OpenJFX release was not found on ${JFX_PATH}/${selected_jdk_version}"
                        fi
                        msg "Job Finished"
                        java -version
                    else
                        err "Must grant sudo access OR remove ${JAVA_BIN_PATH} to completely run this script"
                    fi
                else
                    err "You must choose a number from the list -l --list"
                fi
            fi
        else
            print_usage
            list_jdks
        fi
    else
        err "JDK_PATH folder does not exist"
    fi
}

chjdk "${@}"
