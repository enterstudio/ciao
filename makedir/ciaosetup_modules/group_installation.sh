# Group of commands for installation

# todo: When should we print this message?
# "Important: installation modifies the .bashrc/.cshrc files. In order
#  for these changes to be visible you need to log out and back in."

command_group "Installation"
command_help <<EOF
  install      Install the whole CiaoDE system 
               (neeed to build the system before).

  uninstall    Uninstall CiaoDE.
EOF
command_help_exp <<EOF
  install_to_destroot [not documented]
  install_ciao        [not documented]
  install_extras      [not documented]

  generate_revision   [not documented]
  fullinstall         build+docs+install
  uninstallciao       [not documented]

  register_all        Register all components in your system (update shell scripts
                      and emacs configuration files). If some component was already
                      registered, this command updates the registered information.

  show_components     Show all available components
EOF
register_command "install"
do__install() {
    get_install_options "$@" 
    bold_message "Installing CiaoDE"
    do__install_ciao
    do__install_extras
    # Note: we don't use lpmake install to work around a bug in doc
    # generation that should be solved
    #     lpmake install
    bold_message "CiaoDE installation completed"
}
register_command "uninstall"
do__uninstall() {
    lpmake uninstall
}
register_command "install_to_destroot"
# TODO: Used from ./makedir/distpkg_gen_mac.pl; but only ciao seems to be installed, is it correct?
do__install_to_destroot() {
    if echo expr $* : '\(--destdir*=[^=][^=]*\)' >/dev/null  ; then 
	DESTDIR=`expr $* : '--destdir=\([^=][^=]*\)'`
    else
	exit_on_error  "incorrect option \"$ARG\". Should be of the form --destdir=[value]".
    fi
    export BUILD_ROOT=$DESTDIR
    bold_message "Installing CiaoDE into $DESTDIR"
    do__install_ciao
    
    bold_message "CiaoDE installation completed"
}

register_command "install_ciao"
do__install_ciao() {
    ( cd ${CIAODESRC}/ciao; lpmake install ) || return 1
}
register_command "install_extras"
do__install_extras() {
    lpmake install_extras
}

register_command "generate_revision"
do__generate_revision() {
    lpmake generate_revision
}

register_command "fullinstall"
do__fullinstall() {
    do__build
    do__docs
    do__install
}

register_command "uninstallciao"
do__uninstallciao() {
    lpmake uninstallciao
}

register_command "register_all"
do__register_all() {
    lpmake register_all
}

register_command "show_components"
do__show_components() {
    lpmake show_components
}
