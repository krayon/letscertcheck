#!/bin/bash
# vim:set ts=4 sw=4 tw=80 et cindent ai cino=(0,ml,\:0:
# ( settings from: http://datapax.com.au/code_conventions/ )
#
#/**********************************************************************
#    LetsCertCheck
#    Copyright (C) 2017 Todd Harbour
#
#    This program is free software; you can redistribute it and/or
#    modify it under the terms of the GNU General Public License
#    version 2 ONLY, as published by the Free Software Foundation.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program, in the file COPYING or COPYING.txt; if
#    not, see http://www.gnu.org/licenses/ , or write to:
#      The Free Software Foundation, Inc.,
#      51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
# **********************************************************************/

# letscertcheck
#--------------
# Checks expiry on domain certificates

# Config paths
_ETC_CONF="/etc/letscertcheck.conf"
_HOME_CONF="${HOME}/.letscertcheckrc"



############### STOP ###############
#
# Do NOT edit the CONFIGURATION below. Instead generate the default
# configuration file in your home directory thusly:
#
#     ./letscertcheck.bash -C >~/.letscertcheckrc
#
####################################

# [ CONFIG_START

# hosts file update Default Configuration
# =======================================

# DEBUG
#   This defines debug mode which will output verbose info to stderr
#   or, if configured, the debug file ( ERROR_LOG ).
DEBUG=0

# ERROR_LOG
#   The file to output errors and debug statements (when DEBUG !=
#   0) instead of stderr.
#ERROR_LOG="/tmp/letscertcheck.log"

# COLOUR_OUTPUT
#   Whether or not to output the results in colour.
COLOUR_OUTPUT=1

# DOMAINS
#   An array of domains to check, in the format:
#       DOMAINS=('<domain>:<port>:<servername>' '<domain>:<port>:<servername>')
#
#   If <servername> is not present, <domain> is used as <servername>.
#
#   <port> can be service names (as listed in /etc/services (eg. 'https' instead
#   of '443'). If <port> is not present, 443 (HTTPS) is used as <port>.
#
#   Colon delimiters are still required, if excluded elements are not the last
#   element. These are valid:
#       example.com
#       example.com:https
#       example.com:1234
#       example.com::myservername.example.com
#   However, this is not:
#       example.com:myservername.example.com
DOMAINS=()


# DOMAINS_STARTTLS
#   An array of domains to check that require STARTTLS be negotiated first, in
#   the format:
#       DOMAINS_STARTTLS=(
#           '<protocol>:<domain>:<port>:<servername>'
#           '<protocol>:<domain>:<port>:<servername>'
#       )
#   <protocol> can be either 'smtp', 'pop3', 'imap', 'ftp' or 'xmpp'.
#
#   If <servername> is not present, <domain> is used as <servername>.
#
#   <port> can be service names (as listed in /etc/services (eg. 'https' instead
#   of '443'). If <port> is not present, the default port for each protocol is
#   used, respectively:
#         25 ('smtp'),
#        110 ('pop3'),
#        143 ('imap'),
#         21 ('ftp' ) or
#       5222 ('xmpp').
#
#   As DOMAINS, colon delimiters are still required, if excluded elements are
#   not the last element. These are valid:
#       xmpp:example.com
#       xmpp:example.com:1234
#       xmpp:example.com::myservername.example.com
#   However, this is not:
#       xmpp:example.com:myservername.example.com
DOMAINS_STARTTLS=()

# ] CONFIG_END

###
# Config loading
###
[ ! -z "${_ETC_CONF}"  ] && [ -r "${_ETC_CONF}"  ] && . "${_ETC_CONF}"
[ ! -z "${_HOME_CONF}" ] && [ -r "${_HOME_CONF}" ] && . "${_HOME_CONF}"

# Version
APP_NAME="Lets Cert Check"
APP_VER="0.00"
APP_URL="http://gitlab.com/krayon/letscertcheck/"

# Program name
PROG="${0##*/}"

# exit condition constants
ERR_NONE=0
ERR_UNKNOWN=1
# START /usr/include/sysexits.h {
ERR_USAGE=64       # command line usage error
ERR_DATAERR=65     # data format error
ERR_NOINPUT=66     # cannot open input
ERR_NOUSER=67      # addressee unknown
ERR_NOHOST=68      # host name unknown
ERR_UNAVAILABLE=69 # service unavailable
ERR_SOFTWARE=70    # internal software error
ERR_OSERR=71       # system error (e.g., can't fork)
ERR_OSFILE=72      # critical OS file missing
ERR_CANTCREAT=73   # can't create (user) output file
ERR_IOERR=74       # input/output error
ERR_TEMPFAIL=75    # temp failure; user is invited to retry
ERR_PROTOCOL=76    # remote error in protocol
ERR_NOPERM=77      # permission denied
ERR_CONFIG=78      # configuration error
# END   /usr/include/sysexits.h }

# Defaults not in config

pwd="$(pwd)"

nowe="$(date +%s)"
now="$(date +%Y%m%d%H%M%S%z)"
nowz="$(TZ="UTC" date +%Y%m%d%H%M%SZ)"
pid="$$"

# Must declare explicitly as array in order to iterate over keys
declare -A col colbg colfg

col['reset']="\033[0m"

colbg['black']="\033[40m"
colbg['blue']="\033[44m"
colbg['brown']="\033[43m"
colbg['cyan']="\033[46m"
colbg['green']="\033[42m"
colbg['lightgrey']="\033[47m"
colbg['purple']="\033[45m"
colbg['red']="\033[41m"

colfg['black']="\033[0;30m"
colfg['blue']="\033[0;34m"
colfg['brightblue']="\033[1;34m"
colfg['brightcyan']="\033[1;36m"
colfg['brown']="\033[0;33m"
colfg['cyan']="\033[0;36m"
colfg['darkgrey']="\033[1;30m"
colfg['green']="\033[0;32m"
colfg['lightgreen']="\033[1;32m"
colfg['lightgrey']="\033[0;37m"
colfg['lightred']="\033[1;31m"
colfg['pink']="\033[1;35m"
colfg['purple']="\033[0;35m"
colfg['red']="\033[0;31m"
colfg['white']="\033[1;37m"
colfg['yellow']="\033[1;33m"

example=0



# Params:
#   NONE
function show_version() {
    echo -e "\
${APP_NAME} v${APP_VER}\n\
${APP_URL}\n\
"
}

# Params:
#   NONE
function show_usage() {
    show_version
cat <<EOF

${APP_NAME} retrieves the expiry of provided domains' certificates.

Usage: ${PROG} -h|--help
       ${PROG} -V|--version
       ${PROG} -C|--configuration
       ${PROG} [-v|--verbose]
               [-x|--example]

-h|--help           - Displays this help
-V|--version        - Displays the program version
-C|--configuration  - Outputs the default configuration that can be placed in
                          ${_ETC_CONF}
                      or
                          ${_HOME_CONF}
                      for editing.
-n|--nocolour|--nocolor
                    - Output is not coloured. This is the same as setting
                      COLOUR_OUTPUT=0 in your config.
-v|--verbose        - Displays extra debugging information.  This is the same
                      as setting DEBUG=1 in your config.
-x|--example        - Shows example output for a series of test domains.

Example: ${PROG}
EOF
}

# cleanup
function cleanup() {
    decho "Clean Up"

    cd "${pwd}" &>/dev/null
}

function trapint() {
    echo "WARNING: Signal received: ${1}" >&2

    cleanup

    exit ${1}
}

# Output configuration file
function output_config() {
    cat "${0}"|\
         grep -A99999 '# \[ CONFIG_START'\
        |grep -v      '# \[ CONFIG_START'\
        |grep -B99999 '# \] CONFIG_END'  \
        |grep -v      '# \] CONFIG_END'  \
    #
}

# Debug echo
function decho() {
    local line

    # Not debugging, get out of here then
    [ ${DEBUG} -le 0 ] && return

    while read -r line; do #{
        echo >&2 "[$(date +'%Y-%m-%d %H:%M')] DEBUG: ${line}"
    done< <(echo "${@}") #}
}

# Get certificate
#     $1 == host
#     $2 == port
#     $3 == [servername] (if not specified, uses host)
#     $4 == [protocol] (if specified, does starttls)
function getcert() {
    [ ${#} -lt 2 ] || [ ${#} -gt 4 ] && return ${ERR_USAGE}

    local host="${1}" && shift 1
    local port="${1}" && shift 1
    local serv="${host}"; [ ${#} -gt 0 ] && serv="${1}" && shift 1
    local prot="";        [ ${#} -gt 0 ] && prot="${1}" && shift 1

    local cerr=""
    local cout=""
    local cret=0

    # NOTE: As per https://rt.openssl.org/Ticket/Display.html?id=2936#txn-28848
    #       openssl s_client will load NO CA certs when no CApath/CAfile
    #       parameters are specified. When ANY CApath/CAfile parameter IS
    #       specified, openssl s_client loads the CA certificates from the
    #       default location (set at compile time) AND the path/file provided,
    #       unless overridden by the environment variable SSL_CERT_DIR.

    [ -z "${prot}" ] && {
        # -servername required due to SNI
        eval "$({ cerr=$({ cout=$(
            echo "quit"\
            |openssl\
                s_client\
                    -CApath /dev/null\
                    -showcerts\
                    -connect    "${host}:${port}"\
                    -servername "${serv}"\
        ); cret=$?; } 2>&1; declare -p cout cret >&2); declare -p cerr; } 2>&1)"

        while IFS=$'\n' read -r line; do #{
            decho "${line}"
        done < <(echo "${cout}") #}

        while IFS=$'\n' read -r line; do #{
            decho "STDERR: ${line}"
        done < <(echo "${cerr}") #}

        echo "${cout}"
        return ${cret}
    }

    eval "$({ cerr=$({ cout=$(
        echo "quit"\
        |openssl\
            s_client\
                -CApath /dev/null\
                -showcerts\
                -starttls   "${prot}"\
                -connect    "${host}:${port}"\
                -servername "${serv}"\
    ); cret=$?; } 2>&1; declare -p cout cret >&2); declare -p cerr; } 2>&1)"

    while IFS=$'\n' read -r line; do #{
        decho "${line}"
    done < <(echo "${cout}") #}

    while IFS=$'\n' read -r line; do #{
        decho "STDERR: ${line}"
    done < <(echo "${cerr}") #}

    echo "${cout}"
    return ${cret}
}

# Get certificate expiry
#     $1 == cert data (from getcert())
function getcertexp() {
    datadates="$(\
        echo "${data}"\
        |openssl\
            x509\
                -noout\
                -dates\
    )"

    TZ=UTC date +%s -d "$(\
        echo -E "${datadates}"\
        |sed -n -e 's#^notAfter=\(.*\)$#\1#p'\
    )"
}

# outputstatus [-b] <date_in_%s> <extra> [<print_rem>]
#     -b         - NOT colour output
#     date_in_%s - Date in secs since unix epoch
#     extra      - host name etc
#     print_rem  - print human readable remaining time
function outputstatus() {
    local usecolour=1; [ "${1}" == "-b" ] && usecolour=0 && shift 1

    [ ${#} -gt 3 ] || [ ${#} -lt 2 ] && return ${ERR_USAGE}

    local to="${1}"; shift 1
    local extra="${1}"; shift 1
    local rem=""; [ ${#} -gt 0 ] && rem="${1}" && shift 1

    # Determine false
    [ "${rem}" == "0" ] || [ "${rem,,}" == "false" ] && rem=""

    local colon="${colfg['lightgreen']}"
    local coloff="${col['reset']}"

    local exp="(>6w)    "

    # One week  ==  604800 secs
    [ "${to}" -lt "$((${nowe} + (604800 * 6)))" ] && colon="${colfg['green']}"      && exp="(6w)     "
    [ "${to}" -lt "$((${nowe} + (604800 * 5)))" ] && colon="${colfg['blue']}"       && exp="(5w)     "
    [ "${to}" -lt "$((${nowe} + (604800 * 4)))" ] && colon="${colfg['brightblue']}" && exp="(4w)     "
    [ "${to}" -lt "$((${nowe} + (604800 * 3)))" ] && colon="${colfg['purple']}"     && exp="(3w)     "
    [ "${to}" -lt "$((${nowe} + (604800 * 2)))" ] && colon="${colfg['pink']}"       && exp="(2w)     "
    [ "${to}" -lt "$((${nowe} + (604800 * 1)))" ] && colon="${colfg['red']}"        && exp="(1w)     "
    [ "${to}" -lt "${nowe}" ]                     && colon="${colfg['lightred']}"   && exp="(EXPIRED)"

    # Disable colours if requested
    [ ${usecolour} -eq 0 ] && {
        colon=""
        coloff=""
    }

    echo -e "${colon}$(
        date --rfc-3339=seconds -d "@${to}"
    )${rem:+ ${exp}} ${extra}${coloff}"
}



# START #

# If debug file, redirect stderr out to it
[ ! -z "${ERROR_LOG}" ] && exec 2>>"${ERROR_LOG}"

decho "START"

# SIGINT  =  2 # (CTRL-c etc)
# SIGKILL =  9
# SIGUSR1 = 10
# SIGUSR2 = 12
for sig in 2 9 10 12; do #{
    trap "trapint ${sig}" ${sig}
done #}

# Check for required commands

# Process command line parameters
opts=$(\
    getopt\
        --options v,h,V,C,n,x\
        --long verbose,help,version,configuration,nocolour,nocolor,example\
        --name "$PROG"\
        --\
        "$@"\
)
eval set -- "${opts}"
unset opts

while :; do #{
    case "$1" in #{
        # Verbose mode # [-v|--verbose]
        -v|--verbose)
            decho "Verbose mode specified"
            DEBUG=1
        ;;

        # Help # -h|--help
        -h|--help)
            decho "Help"

            show_usage
            exit ${ERR_NONE}
        ;;

        # Version # -V|--version
        -V|--version)
            decho "Version"

            show_version
            exit ${ERR_NONE}
        ;;

        # Configuration output # -C|--configuration
        -C|--configuration)
            decho "Configuration"

            output_config
            exit ${ERR_NONE}
        ;;

        # No Colour output # -n|--nocolour|--nocolor
        -n|--nocolour|--nocolor)
            decho "No-colour"
            COLOUR_OUTPUT=0
        ;;

        # Example # -x|--example
        -x|--example)
            decho "Example"
            example=1
        ;;

        --)
            shift
            break
        ;;

        *)
            >&2 echo "ERROR: Unrecognised parameter ${1}..."
            exit ${ERR_USAGE}
        ;;
    esac #}

    shift

done #}
[ "${COLOUR_OUTPUT}" == "1" ] && COLOUR_OUTPUT=""

# Maybe we just want an example?
[ ${example} -eq 1 ] && {
    to="$(date -d '+6 weeks +1 day' +%s)"; outputstatus ${COLOUR_OUTPUT:+ -b} "${to}" "6weeks1day.example.com" 1
    to="$(date -d '+5 weeks +1 day' +%s)"; outputstatus ${COLOUR_OUTPUT:+ -b} "${to}" "5weeks1day.example.com" 1
    to="$(date -d '+4 weeks +1 day' +%s)"; outputstatus ${COLOUR_OUTPUT:+ -b} "${to}" "4weeks1day.example.com" 1
    to="$(date -d '+3 weeks +1 day' +%s)"; outputstatus ${COLOUR_OUTPUT:+ -b} "${to}" "3weeks1day.example.com" 1
    to="$(date -d '+2 weeks +1 day' +%s)"; outputstatus ${COLOUR_OUTPUT:+ -b} "${to}" "2weeks1day.example.com" 1
    to="$(date -d '+1 weeks +1 day' +%s)"; outputstatus ${COLOUR_OUTPUT:+ -b} "${to}" "1weeks1day.example.com" 1
    to="$(date -d '         +1 day' +%s)"; outputstatus ${COLOUR_OUTPUT:+ -b} "${to}" "1day.example.com"       1
    to="$(date -d '-1 weeks +1 day' +%s)"; outputstatus ${COLOUR_OUTPUT:+ -b} "${to}" "expired.example.com"    1

    # Clean up
    cleanup

    exit ${ERR_NONE}
}

# Check for non-optional parameters



[ ${#} -gt 0 ] && {
    >&2 echo "ERROR: Too many parameters: ${@}..."
    exit ${ERR_USAGE}
}

# Clean up
cleanup

decho "DONE"

exit ${ret}
