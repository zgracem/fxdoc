# shellcheck disable=SC2120,SC2128
# ┌───────────────────────────────────────────────────────────────────────────┐
# │                                                                   f(x)doc │
# └───────────────────────────────────────────────────────────────────────────┘

[[ -n $FX_DEBUG ]] && printf '### sourcing %s\n' "${BASH_SOURCE[0]}"

unset -v FXDOC_LOADED

# -----------------------------------------------------------------------------

fxdoc()
{ #: -- displays information parsed from a shell function's docstring
  #
  #: $ fxdoc [--short] [--reload] <function>
  #: $ fxdoc [--syntax|--help]
  #
  #: |   --short  = short output
  #: |   --reload = reload FUNCTION's source file before parsing
  #: |   --syntax = print the fxdoc syntax reference
  #: |   --help   = print this help message

  if [[ -z $1 ]]; then
    fx_usage >&2
    return 64
  elif [[ $1 == --reload && -z $2 ]]; then
    # Undocumented debug behaviour: `fxdoc --reload` re-.s this file.
    # shellcheck disable=SC2064
    trap ". '$FXDOC_LOADED'; trap - RETURN" RETURN
    return
  fi

  while (( $# )); do
    case $1 in
      --help)
        fxdoc fxdoc
        return
        ;;
      --syntax)
        _fx::syntax
        return
        ;;
      --reload)
        local do_reload_first=1
        shift
        ;;
      --short)
        local do_short_output=1
        shift
        ;;
      --?*)
        printf >&2 "invalid option: %s\\n" "$1"
        return 64
        ;;
      *)
        if [[ -n $func ]]; then
          printf >&2 "%s: extraneous argument\\n" "$1"
          return 64
        elif declare -f "$1" >/dev/null; then
          local func=$1
          shift
        else
          printf >&2 "%s: function not defined\\n" "$1"
          return 1
        fi
    esac
  done

  #types
  local -a docs=() usage=() p_args=()
  local line; while read -r line; do
    case ${line:0:1} in
      '-')  docs+=(-d "${line:2}")
            ### uppercase first letter & remove trailing period
            # local doc=${line:2}; doc=${doc^}; doc=${doc/%./}
            # p_args+=(-d "${line:2}")
            ;;
      '$')  usage+=(-u "${line:2}")  ;;
      '|')  p_args+=(-s "${line:2}") ;;
      '>')  p_args+=(-i "${line:2}") ;;
      '=')  p_args+=(-r "${line:2}") ;;
      '<')  p_args+=(-p "${line:2}") ;;
      '@')  p_args+=(-q "${line:2}") ;;
      '*')  p_args+=(-n "${line:2}") ;;
    esac
  done < <(_fx::parse "$func" "${do_reload_first+--reload}")

  if [[ -n $do_short_output ]]; then
    if [[ -n $docs ]]; then
      _fx::print -f "$func" "${docs[@]}"
    elif [[ -n $usage ]]; then
      _fx::print -f "$func" "${usage[@]}"
    fi
    return
  fi

  p_args+=("${docs[@]}" "${usage[@]}")
  _fx::print -f "$func" "${p_args[@]}"
}

fx_usage()
{ #: -- prints usage information for shell function $1 (or caller if no arg)
  #: $ fx_usage [function]
  local func=${1-${FUNCNAME[1]}}

  [[ -n $func ]] || return

  local -a usage=()
  local line; while read -r line; do
    [[ ${line:0:1} == "$" ]] && usage+=(-u "${line:2}")
  done < <(_fx::parse "$func")

  [[ -n $usage ]] && _fx::print "${usage[@]}"
}

# -----------------------------------------------------------------------------

_fx::parse()
{ #: -- parses information from a shell function's docstring
  #
  #: $ _fx::parse [--reload] <function>
  #: | --reload = reload FUNCTION's source file before parsing
  #
  #: @fxdoc()
  #: @fx_usage()
  local Prefix="#:"
  local Types='*@<=>|$-' #types

  local func=${1?}

  local src src_file src_line
  src=$(_fx::whence "$func") || return
  src_file=${src%:*}; src_file=${src_file/#$'~'/$HOME} # tilde expansion
  src_line=${src##*:}

  if [[ $2 == --reload ]]; then
    # shellcheck disable=SC1090
    . "$src_file" || {
      printf >&2 "fxdoc: failed to reload '%s'\\n" "$src_file"
      return 1
    }
  fi

  local -a sed_cmds=()

  # First, isolate the section between the beginning of our function definition
  # and the next line consisting of a lone "}" or ")" character.
  sed_cmds+=(-e "${src_line},/^[[:space:]]*[})][[:space:]]*$/!d")

  # Next, isolate all lines that match the docstring syntax.
  #
  # Undocumented behaviour: the type indicator can repeat as many times as you
  # want, surrounded by as much whitespace as you want (or none at all!).
  # In case you don't care about things lining up nicely, or if you want to use
  # two dashes for the main/top docstring, or you're into concrete poetry,
  # or whatever.
  #
  #   #:-this is okay
  #   #:     $$$ this is also okay
  #   #:             ************************             this is fine but why
  #
  local a b c
  printf -v a '[^#]*%s[[:space:]]*([%s])+[[:space:]]*(.*)' "$Prefix" "$Types"
  printf -v b '\\1 \\2' # prefix & types
  printf -v c 's/^%s$/%s/p' "$a" "$b"
  sed_cmds+=(-e "$c")

  sed -nE "${sed_cmds[@]}" "$src_file"
}

_fx::whence()
( #: -- prints the source file and line number where function $1 was defined
  #: @_fx::parse
  shopt -s extdebug
  local regex="^${1}[[:space:]]([[:digit:]]+)[[:space:]](.+)$"
  local loc; if loc=$(declare -F "$1") && [[ $loc =~ $regex ]]; then
    printf "%s:%d" "${BASH_REMATCH[2]}" "${BASH_REMATCH[1]}"
  else
    return 66
  fi
)

_fx::print()
{ #: -- prints information about a shell function
  #: @fxdoc()
  #: @fx_usage()

  #types
  local -a docs=() usage=() switches=() urls=() rets=() reqs=() used=() notes=()
  local func=""

  local OPT OPTIND OPTARG
  while getopts ':f:d:u:s:i:r:p:q:n:' OPT; do #types
    case $OPT in
      #types
      f)  func=$OPTARG ;;
      d)  docs+=("$OPTARG") ;;
      u)  usage+=("$OPTARG") ;;
      s)  switches+=("$OPTARG") ;;
      i)  urls+=("$OPTARG") ;;
      r)  rets+=("$OPTARG") ;;
      p)  reqs+=("$OPTARG") ;;
      q)  used+=("$OPTARG") ;;
      n)  notes+=("$OPTARG") ;;
    '?')  : ;; # discard/ignore invalid options
    esac
  done
  shift $((OPTIND - 1))

  if ! [[ -n $docs || -n $usage ]]; then
    printf >&2 "%s: no docstrings found\\n" "$func"
    return 1
  fi

  if [[ -n $docs ]]; then
    printf "%s – %s\\n" "$func" "${docs[*]}"
  fi

  if [[ -n $usage ]]; then
    ### Hanging indent style
    # printf "Usage: %s\\n" "${usage[0]}"
    # if (( ${#usage[@]} > 1 )); then
    #   printf "       %s\\n" "${usage[@]:1}"
    # fi
    printf "Usage: "
    if (( ${#usage[@]} > 1 )); then
      printf "\\n  %s" "${usage[@]}"
    else
      printf "%s" "${usage[0]}"
    fi
    printf "\\n"
  fi

  if [[ -n $switches ]]; then
    printf "Options:\\n"
    printf "  %s\\n" "${switches[@]}"
  fi

  # not implemented
  if [[ -n $urls ]]; then : ; fi
  if [[ -n $rets ]]; then : ; fi

  if [[ -n $reqs ]]; then
    printf "Requires: %s" "${reqs[0]}"
    if (( ${#reqs[@]} > 1 )); then
      printf ", %s" "${reqs[@]:1}"
    fi
    printf "\\n"
  fi

  if [[ -n $used ]]; then
    printf "Used by: %s" "${used[0]}"
    if (( ${#used[@]} > 1 )); then
      printf ", %s" "${used[@]:1}"
    fi
    printf "\\n"
  fi

  if [[ -n $notes ]]; then
    if (( ${#notes[@]} == 1 )); then
      printf "Note: %s\\n" "${notes[0]}" \
      | fold -s
    else
      printf "Notes:\\n"
      printf "  %s\\n" "${notes[@]}"
    fi
  fi
}

_fx::syntax()
{ #: -- prints the fxdoc syntax reference
  local b=$'\e[1m' X=$'\e[22m' x=$'\e[0m'
  local ye=$'\e[33m' bl=$'\e[34m' ma=$'\e[35m' cy=$'\e[36m' wh=$'\e[37m'

  local h=$bl # headings
  local p=$ye # prefix
  local s=$cy # strings
  local t=$ma # type indicator

  local Prefix="#:" #prefix
  cat <<EOF
${h}\
╔═╣ ${b}f(x)doc${X} ╠═══════════════════════════════════════════════════════════════╗
║                                                          syntax reference ║
╚═══════════════════════════════════════════════════════════════════════════╝${x}
EOF
  [[ -z $do_short_output ]] && cat <<EOF
${b}f(x)doc${X} syntax lets you document shell functions with comments included
anywhere within the function definition. Typical shell comments begin with
a ${p}#${x} character; f(x)doc docstrings begin with ${p}${Prefix}${x} (the ${p}prefix${x}). The prefix is
followed by whitespace, a single symbol (the ${t}type indicator${x}), more white-
space, and finally the ${s}docstring${x} itself.

For example, the following function definition--

  daysold()
  { ${p}${Prefix} ${t}- ${s}finds files that have been modified in the last N days
    ${p}${Prefix} ${t}$ ${s}daysold <n> [dir]
    ${p}${Prefix} ${t}| ${s}n   = maximum age of found files, in days
    ${p}${Prefix} ${t}| ${s}dir = directory to search (default: PWD)

    ${x}mdfind -onlyin "\${2-.}" "kMDItemFSContentChangeDate>\\\$time.today(-\$1)"
  }

--will result in the following output:

  ${bl}\$ ${x}fxdoc daysold${x}
  ${x}daysold – finds files that have been modified in the last N days
  Usage: daysold <n> [dir]
  Options:
    n   = maximum age of found files
    dir = directory to search (default: PWD)${x}
EOF
  [[ -z $do_short_output ]] && cat <<EOF
${h}
┌───────────────────────────────────────────────────────────────────────────┐
│                                                           type indicators │
└───────────────────────────────────────────────────────────────────────────┘${x}
EOF
  cat <<EOF
${p}${Prefix} ${t}- ${x}describes the purpose of the function
${p}${Prefix} ${t}$ ${x}usage synopsis
${p}${Prefix} ${t}| ${x}description of option or argument
${p}${Prefix} ${t}> ${x}source or reference URL
${p}${Prefix} ${t}= ${x}expected return value(s) of function
${p}${Prefix} ${t}< ${x}required software package, version, or functionality
${p}${Prefix} ${t}@ ${x}external function or script that relies on this function
${p}${Prefix} ${t}* ${x}miscellaneous note
EOF
}

# -----------------------------------------------------------------------------

# complete function names as arguments to fxdoc
complete -o nospace -A function -- fxdoc

export FXDOC_LOADED=${BASH_SOURCE[0]}
