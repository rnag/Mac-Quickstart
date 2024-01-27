#!/bin/bash

# Bash Script to Bootstrap SSH Key setup and config for GitHub,
# ideally on a new personal laptop or machine.
#
# Before running the script, change values inside `GH_USERS` below!
#
# Usage:
#   ./bootstrap_ssh_for_github.sh
#
# Rationale:
#   You may use the same computer for work and personal development
#   and need to separate your work.
#
# Sources:
#   - https://docs.github.com/en/authentication/connecting-to-github-with-ssh
#   - https://gist.github.com/jexchan/2351996
#   - https://gist.github.com/yinzara/bbedc35798df0495a4fdd27857bca2c1

# TODO Update this!
declare -a GH_USERS=(
    # Fields:
    #   Project|GitHub Username|GitHub Email
    #
    # Note that `Project` is optional, and defaults to `GitHub Username`
    # if empty or not specified. For example:
    #   '|user1|user1@example.com'
    'personal|user1|user1@example.com'
    'work|user2|user2@example.com'
)

# SSH Key Type, choose one of:
#  [dsa | ecdsa | ecdsa-sk | ed25519 | ed25519-sk | rsa]
#
# GitHub recommands using `ed25519`
#
# Sources:
#   - https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent?platform=mac#generating-a-new-ssh-key
#   - https://blog.peterruppel.de/ed25519-for-ssh/
KEY_TYPE='ed25519'

# Get full name of user
# Credits: https://stackoverflow.com/a/32874542/10237506
FULL_NAME=$(id -F)
# or, manually enter it:
# FULL_NAME="John Doe"

# Get Full Name of Device (ex. `John's Laptop`)
# Credits: https://www.tech-otaku.com/networking/using-terminal-find-your-macs-network-name/#4
DEVICE_NAME=$(if command -v scutil >/dev/null 2>&1; then scutil --get ComputerName; else hostname -f; fi)

# Start the ssh-agent in the background.
# not sure it's needed?
# eval "$(ssh-agent -s)"

# Create .ssh directory in user home
mkdir -p ~/.ssh

# shellcheck disable=SC2088
ssh_config="~/.ssh/config"
ssh_config_real="${ssh_config/#\~/$HOME}"

# shellcheck disable=SC2088
global_gc="~/.gitconfig"
global_gc_real="${global_gc/#\~/$HOME}"

# TODO check python is installed
command -v python3 &>/dev/null && PYTHON=python3 || PYTHON=python

# Loop through list of users to create SSH keys for
for name_email in "${GH_USERS[@]}"
do
    # shellcheck disable=SC2206
    IFS='|'; parts=($name_email); unset IFS;

    name="${parts[1]}"
    name=${name//[-. ]/_}
    email="${parts[2]}"
    project="${parts[0]:-${name}}"

    echo "GH Username:    ${name}"
    echo "GH Email:       ${email}"
    echo "Project:        ${project}"

    # shellcheck disable=SC2088
    key_path="~/.ssh/id_${KEY_TYPE}_${name}"
    key_path_real="${key_path/#\~/$HOME}"

    # shellcheck disable=SC2086
    echo ${key_path}: Generating...

    ssh-keygen -t ${KEY_TYPE} -f "${key_path_real}" -C "${email}"
    echo

    # Uncomment to use RSA-4096 keys instead
    # ssh-keygen -t rsa -b 4096 -f "${key_path_real}" -C "${email}"

    ssh-add "${key_path_real}"

    echo Added SSH key to the ssh-agent

cat <<EOT >> "${ssh_config_real}"
Host github.com-${name}
HostName github.com
UseKeychain yes
AddKeysToAgent yes
User git
IdentityFile ${key_path}
IdentitiesOnly yes

EOT

    echo ${ssh_config}: Added entry to file

    # Log into GitHub for each user and add the keys from ~/.ssh/xxxxx.pub to the respective users authorized SSH keys.

    # Register SSH Key in GitHub account
    # shellcheck disable=SC2086
    pbcopy < ${key_path_real}.pub

    url='https://github.com/settings/ssh/new'

    echo "${key_path}.pub: Copied contents to clipboard..."
    echo
    echo "Please navigate to:"
    echo "  $url"
    echo
    echo "Suggested values to fill out -"
    echo "  Title  : ${DEVICE_NAME}"
    echo "  Key    : $(cat "${key_path_real}".pub)"
    echo

    # Open page to create new SSH key in the browser
    $PYTHON -m webbrowser "${url}"

    # Prompt for user to continue
    read -p "Press any key to continue... " -n1 -sr

    # shellcheck disable=SC2088
    git_dir="~/Git-Projects/${project}"
    git_dir_real="${git_dir/#\~/$HOME}"

    # shellcheck disable=SC2086
    mkdir -p ${git_dir_real}

cat <<EOT >> "${git_dir_real}"/.gitconfig
[user]
    name = ${FULL_NAME}
    email = ${email}

[url "git@github.com-${name}"]
    insteadOf = git@github.com

EOT

    # shellcheck disable=SC2086
    echo ${git_dir}: Created directory and added .gitconfig

if [ ! -f "${global_gc_real}" ]; then
cat <<EOT >> "${global_gc_real}"
[user]
	name = ${FULL_NAME}
	email = ${email}

[url "git@github.com:"]
	insteadOf = https://github.com/

[url "git://"]
	insteadOf = https://

EOT

echo ${global_gc}: Created file

fi

cat <<EOT >> "${global_gc_real}"
[includeif "gitdir:${git_dir}/"]
	path = ${git_dir}/.gitconfig

EOT

    # shellcheck disable=SC2086
    echo ${global_gc}: Updated file

    echo 'DONE!'
    echo
    echo '-----'
    echo

done

chmod 600 "${ssh_config_real}"

# Test the SSH connection
ssh -T git@github.com

# Run the following if you want to add GitHub to "known hosts"
# See https://stackoverflow.com/q/47707922/10237506 for more info
# ssh-keyscan github.com >> ~/.ssh/known_hosts
