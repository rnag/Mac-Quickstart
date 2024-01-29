#!/bin/bash

# Bash Script to Bootstrap SSH (and GPG for commit verification)
# and setup necessary keys and config for GitHub, ideally on
# a new personal laptop or machine.
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
# After running this script, your user home directory (~) would be
# expected to have the following folder/file structure:
#
#   .gitignore
#   Git-Projects/
#   ├── Personal
#   └── Work
#   .dotfiles
#   ├── Personal-github.gitconfig
#   └── Work-github.gitconfig
#  .ssh
#  ├── config
#  ├── id_ed25519_<gh_user>
#  ├── id_ed25519_<gh_user>.pub
#  ├── known_hosts
#
# Sources:
#   - https://docs.github.com/en/authentication/connecting-to-github-with-ssh
#   - https://docs.github.com/en/authentication/managing-commit-signature-verification/generating-a-new-gpg-key
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
    'Personal|user1|user1@example.com'
    'Work|user2|user2@example.com'
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

# shellcheck disable=SC2088
ssh_config="~/.ssh/config"
ssh_config_real="${ssh_config/#\~/$HOME}"

# shellcheck disable=SC2088
global_gc="~/.gitconfig"
global_gc_real="${global_gc/#\~/$HOME}"

# shellcheck disable=SC2088
dotfiles="~/.dotfiles"
dotfiles_real="${dotfiles/#\~/$HOME}"

# Create .ssh directory in user home
mkdir -p ~/.ssh

# Create .dotfiles directory in user home
mkdir -p "${dotfiles_real}"

# TODO check python is installed
command -v python3 &>/dev/null && PYTHON=python3 || PYTHON=python


function main() {

    # Install gpg for mac
    install_gpg_tools

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
        echo --------------
        echo

        # shellcheck disable=SC2088
        git_dir="~/Git-Projects/${project}"
        git_dir_real="${git_dir/#\~/$HOME}"

        # shellcheck disable=SC2086
        mkdir -p ${git_dir_real}

        setup_ssh_keys

        setup_gpg_keys

        setup_git_config

        echo
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
}

# Install GPG
function install_gpg_tools() {
    if ! command -v gpg >/dev/null 2>&1; then
        echo "Installing gnupg tools via homebrew..."

        brew update
        brew upgrade
        brew install gnupg pinentry-mac

        echo "export GPG_TTY=$(tty)" >> ~/.zshenv
        # shellcheck disable=SC1090
        source ~/.zshenv

        # shellcheck disable=SC2088
        echo "~/.zshenv: Updated (and sourced) file"

        echo "pinentry-program /opt/homebrew/bin/pinentry-mac" >> ~/.gnupg/gpg-agent.conf
        # shellcheck disable=SC2088
        echo "~/.gnupg/gpg-agent.conf: Updated file to use pinentry-mac"

        killall gpg-agent
        killall gpg

        # Run gpg-agent in daemon mode
        gpg-agent --daemon

        echo "Restarted gpg agent"
    fi
}

open_browser_to_gh_settings() {
    # Open page to create new SSH key in the browser
    $PYTHON -m webbrowser "${url}"

    echo "${url}" | pbcopy

    echo "Please navigate to:"
    echo "  $url"
    echo
    echo '> URL copied to clipboard <'
    echo
    read -p "Press any key to continue... " -n1 -sr

    echo "${DEVICE_NAME}" | pbcopy

    echo
    echo
    echo '> Title copied to clipboard <'
    echo
    echo "Suggested values to fill out -"
    echo "  Title  : ${DEVICE_NAME}"
    echo
    read -p "Press any key to continue... " -n1 -sr

    echo "$key" | pbcopy

    echo
    echo
    echo "Command:"
    echo "  \$ ${key_cmd}"
    echo
    echo "> ${key_name} copied to clipboard <"
    echo
    echo "Suggested values to fill out -"
    echo "  Key  : <clipboard or command>"
    echo
    read -p "Press any key to continue... " -n1 -sr

    echo
    echo
}

# Generate GPG Keys
#
# Credits:
#   - https://docs.github.com/en/authentication/managing-commit-signature-verification/generating-a-new-gpg-key
#   - https://www.oliverspryn.com/blog/the-handbook-to-gpg-and-git
#   - https://dev.to/shostarsson/how-to-use-pgp-to-sign-your-commits-on-github-gitlab-bitbucket-3dae
function setup_gpg_keys() {
    # generate key

    # Uncomment for RSA-4096 keys!
# gpg --batch --full-generate-key <<EOF
# Key-Type: 1
# Key-Length: 4096
# Subkey-Type: 1
# Subkey-Length: 4096
# Name-Real: ${FULL_NAME}
# Name-Comment: GitHub GPG Key (${name})
# Name-Email: ${email}
# Expire-Date: 0
# %commit
# EOF

    echo "In a moment, you'll be asked to create a secure passphrase."
    echo
    echo "Please save this in a safe location, such as a password manager."
    echo
    read -p "Press any key when ready... " -n1 -sr
    echo
    echo

    # ed25519 (sign and encrypt)
    GPG_LINES=$( gpg --batch --full-generate-key 2>&1 <<EOF
Key-Type: 22
Subkey-Type: 22
Key-Curve: ed25519
Subkey-Curve: ed25519
Name-Real: ${FULL_NAME}
Name-Comment: GitHub GPG Key (${name})
Name-Email: ${email}
Expire-Date: 0
%commit
EOF
    )

    # everything after the last slash:
    gpg_key_id="${GPG_LINES##*/}"
    # everything before the last dot
    gpg_key_id="${gpg_key_id%\.*}"

    echo "Key ID: ${gpg_key_id}"

    # Copying key
    # If there's an existing GPG key pair and you want to use it to sign commits and tags, you can display the public key using the following command, substituting in the GPG key ID you'd like to use.
    key=$(gpg --armor --export "${gpg_key_id}")

    key_name="GPG Public Key"
    key_cmd="gpg --armor --export \"${gpg_key_id}\" | pbcopy"

    url="https://github.com/settings/gpg/new"

    # gpg --armor --export "${gpg_key_id}" | pbcopy

    open_browser_to_gh_settings

    echo "$key" | pbcopy
    echo
    echo "> Public Key copied to clipboard <"
    echo
    echo "Please save this in a secure location, e.g. password manager."
    echo
    read -p "Press any key when ready... " -n1 -sr
    echo
    echo
    gpg --export-secret-key -a "${gpg_key_id}" | pbcopy
    echo
    echo "> Private Key copied to clipboard <"
    echo
    echo "Please save this in a secure location, e.g. password manager."
    echo
    read -p "Press any key when ready... " -n1 -sr
    echo
    echo

    # Backup and restore
    # gpg --export-secret-keys gpg_key_id > my-private-key.asc
    # gpg --import my-private-key.asc
}


function setup_ssh_keys() {
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
    key=$(cat "${key_path_real}.pub")

    key_name="SSH Public Key"
    key_cmd="pbcopy < ${key_path}.pub"

    url='https://github.com/settings/ssh/new'

    open_browser_to_gh_settings
}

setup_git_config() {
    project_gitconfig="${dotfiles}/${project}-github.gitconfig"
    project_gitconfig_real="${project_gitconfig/#\~/$HOME}"

    cat <<EOT > "${project_gitconfig_real}"
[user]
    name = ${FULL_NAME}
    signingkey = ${gpg_key_id}
    email = ${email}

[commit]
    gpgsign = true

[tag]
    gpgsign = true

[url "git@github.com-${name}"]
    insteadOf = git@github.com

EOT

    # shellcheck disable=SC2086
    echo ${git_dir}: Created directory
    # shellcheck disable=SC2086
    echo ${project_gitconfig}: added project .gitconfig

if [ ! -f "${global_gc_real}" ]; then
cat <<EOT >> "${global_gc_real}"
[user]
	name = ${FULL_NAME}
	email = ${email}

[init]
        defaultBranch = main

[push]
        followTags = true
        autoSetupRemote = true

[url "git@github.com:"]
	insteadOf = https://github.com/

[url "git://"]
	insteadOf = https://

EOT

    echo ${global_gc}: Created file

fi

cat <<EOT >> "${global_gc_real}"
[includeif "gitdir:${git_dir}/"]
	path = ${project_gitconfig}

EOT

    # shellcheck disable=SC2086
    echo ${global_gc}: Updated file
}

main
