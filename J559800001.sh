# jde_master_functions.sh 
# Author: Meir Lazar
# VersionDate: 2025-11-11 003922
# Description:
#   A portable Bash library of standard functions for migrating Control-M scripts
#   or other job automation to Bash.
#
#
#   Each function uses Log() for structured output, FirstLetterUpperCase naming,
#   lowercase locals, and compact code formatting.
#
# PREREQUISITES
#   Environment variables must be set before sourcing, for example DB connections require:
#     DB_USER   - Oracle username
#     DB_PWD    - Oracle password
#     JDE_DB    - Oracle TNS name (entry in tnsnames.ora)
#
# Usage:
#   source ./global/jde_masters_functions.sh
#   then call functions as needed.

 set -a # exports all variables 
: "${DB_USER:?}"
: "${DB_PWD:=?}"
: "${JDE_DB:=?}"
: "${ORACLE_SQLPLUS:=sqlplus -s}"
: "${DB_CONNECT:="${ORACLE_SQLPLUS} ${DB_USER}/${DB_PWD}@${JDE_DB}"}"


#################################################################################################################################
########################################### LOGGING FUNCTIONS ###################################################################
#################################################################################################################################

# all logging is handled by logging.sh and sourced in each script

#################################################################################################################
######################################### TRAPS #################################################################
#################################################################################################################

function FatalTrap() { 
# use this trap with the command -->  trap 'FATALTRAP ${FUNCNAME[0]} ${LINENO} ${BASH_LINENO[$LINENO]} $?' ERR 
local func tr_func tr_line tr_code
 func="${FUNCNAME[0]}"
 tr_func=$1;  tr_line=$2;  tr_code=$3
 log_fatal "A fatal error occured in this process. It halted the script at Function: ${tr_func}  Line:${tr_line}  Exit Code = ${tr_code}"
 exit "${tr_code}"
}

function BreakTrap() { 
# use this trap with the command -->  trap 'BreakTrap ${FUNCNAME[0]} ${LINENO} ${BASH_LINENO[$LINENO]} $?' INT
 local func tr_func tr_line src_line tr_code
 func="${FUNCNAME[0]}" 
 tr_func="$1"  tr_line="$2" src_line="$3" tr_code="$4"
 log_fatal "User interrupted this process. It halted at Function: ${tr_func}  Line Number:${tr_line} Source Line Number:${src_line}  Exit Code:${tr_code}" 
 exit ${tr_code}
}

function DebugTrap() {
# CALL THIS FUNCTION TO GO LINE BY LINE THROUGH A SCRIPT TO DEBUG IT
trap '(read -p "[$BASH_SOURCE:$LINENO] $BASH_COMMAND?")' DEBUG
}

# Use this instead in the main script at the start of execution:
# trap 'Log "HALT" "User interruptd Script: ${BASH_SOURCE[0]} execution was in Function: ${FUNCNAME[1]} Line: ${BASH_LINENO[0]} Error Code: $?"' INT


#################################################################################################################################
############################################# VAR FUNCTIONS #####################################################################
#################################################################################################################################


# ==============================================================================
# NAME
#     CheckVar - Validate shell variable properties using parameter flags
#
# SYNOPSIS
#     CheckVar --name=<varname> [--def=t|f] [--empty=t|f] [--isnum=t|f] [--linecount=<N>] [--value=<expected>]
#
# DESCRIPTION
#     Performs checks on a shell variable using standard-style flags:
#       --name       : Name of the variable to check (case-sensitive)
#       --def        : 't' if variable must be defined, 'f' if must be undefined
#       --empty      : 't' if must be empty, 'f' if must be non-empty
#       --isnum      : 't' if must be numeric, 'f' if must be non-numeric
#       --linecount  : Expected number of lines (if multiline)
#       --value      : Expected exact value
#
# RETURN VALUE
#     Returns 0 if all checks pass, otherwise returns number of failed checks.
#
# EXAMPLES
#     CheckVar --name=MYVAR --def=t --empty=f --isnum=t --linecount=1 --value=42
# ==============================================================================

function CheckVar() {
    local failcount=0 varname="" def="" empty="" isnum="" ischar="" linecount="" expected="" value="" actual_lines=""
	
    CheckFail() {
        local cond="$1" msg="$2"
        log_info "Testing: ${msg} | Condition: ${cond}"
        if eval "${cond}"; then
            log_critical  "Variable: ${varname} Failed: ${msg} | Condition: '${cond}' evaluated true"
            ((failcount++))
        fi
    }

    for arg in "$@"; do
        case "${arg,,}" in
            --name=*) varname="${arg#--name=}" ;;
            --def=*) def="${arg#--def=}" ;;
            --empty=*) empty="${arg#--empty=}" ;;
            --isnum=*) isnum="${arg#--isnum=}" ;;
            --ischar=*) ischar="${arg#--ischar=}" ;;
            --linecount=*) linecount="${arg#--linecount=}" ;;
            --value=*) expected="${arg#--value=}" ;;
            *) CheckFail "true" "Unknown parameter: ${arg}" ;;
        esac
    done

    [[ -z "${varname}" ]] && CheckFail "true" "Missing --name parameter" && return 1
    value="${!varname}"
    log_info "Checking: variable name: ${varname}   Value = '${value}'"

    case "${def,,}" in
        t|true) CheckFail "[[ -z \"${value+x}\" ]]" "should be defined" ;;
        f|false) CheckFail "[[ -n \"${value+x}\" ]]" "should be undefined" ;;
        "") ;; *) CheckFail "true" "Invalid --def value: ${def}" ;;
    esac

    case "${empty,,}" in
        t|true) CheckFail "[[ -n \"${value}\" ]]" "should be empty" ;;
        f|false) CheckFail "[[ -z \"${value}\" ]]" "should not be empty" ;;
        "") ;; *) CheckFail "true" "Invalid --empty value: ${empty}" ;;
    esac

    case "${isnum,,}" in
        pi) CheckFail "! [[ \"${value}\" =~ ^[0-9]+$ ]]" "should be a positive integer" ;;
        ni) CheckFail "! [[ \"${value}\" =~ ^-[0-9]+$ ]]" "should be a negative integer" ;;
        dec) CheckFail "! [[ \"${value}\" =~ ^-?[0-9]+\.[0-9]+$ ]]" "should be a decimal number" ;;
        fract) CheckFail "! [[ \"${value}\" =~ ^[0-9]+/[0-9]+$ ]]" "should be a fraction" ;;
        t|true) CheckFail "! [[ \"${value}\" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]" "should be numeric" ;;
        f|false) CheckFail "[[ \"${value}\" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]" "should be non-numeric" ;;
        "") ;; *) CheckFail "true" "Invalid --isnum value: ${isnum}" ;;
    esac

    case "${ischar,,}" in
        t|true) CheckFail "! [[ \"${value}\" =~ ^[a-zA-Z]+$ ]]" "should be alphabetic characters only" ;;
        f|false) CheckFail "[[ \"${value}\" =~ ^[a-zA-Z]+$ ]]" "should not be alphabetic only" ;;
        "") ;; *) CheckFail "true" "Invalid --ischar value: ${ischar}" ;;
    esac

    [[ -n "${linecount}" ]] && {
        actual_lines=$(grep -c '^' <<< "${value}")
        CheckFail "[[ ${actual_lines} -ne ${linecount} ]]" "should have ${linecount} lines (has ${actual_lines})"
    }

    [[ -n "${expected}" ]] && CheckFail "[[ \"${value}\" != \"${expected}\" ]]" "should equal '${expected}' (is '${value}')"

    ((failcount == 0)) && log_info "${varname} - All checks passed" || log_error "${varname} - ${failcount} checks failed"
    log_info "Return Code = ${failcount}"
    return ${failcount}
}




###########################################
# NAME
#   ValidateVar - validate variables/files/dirs
# SYNOPSIS
#   ValidateVar --variable=VAR1,VAR2 --type=<any|file|dir> --vartest=<defined|notempty|empty|undefined>
# DESCRIPTION
#   Performs simple checks for presence/emptiness/type of variables named in --variable.
# PRECHECKS
#   None.
# RETURNS
#   0 when all checks pass, non-zero otherwise

function ValidateVar() {
  local vars="" type="any" vartest="defined" rc=0
  for arg in "$@"; do case "${arg}" in
    --variable=*) vars="${arg#--variable=}" ;;
    --type=*) type="${arg#--type=}" ;;
    --vartest=*) vartest="${arg#--vartest=}" ;;
    *) log_warn "Unknown param ${arg}" ;;
  esac; done
  IFS=',' readarray -t arr< <(printf '%s\n' "${vars}");
  for v in "${arr[@]}"; do
    v="${v#"${v%%[![:space:]]*}"}"; v="${v%"${v##*[![:space:]]}"}"
    case "${vartest}" in
      defined) [ "${!v+set}" = "set" ] || { log_error "${v} undefined"; rc=2; } ;;
      notempty) [ -n "${!v-}" ] || { log_error "${v} empty"; rc=3; } ;;
      empty) [ -z "${!v-}" ] || { log_error "${v} not empty"; rc=4; } ;;
      undefined) [ "${!v+set}" != "set" ] || { log_error "${v} defined"; rc=5; } ;;
      *) log_warn "bad vartest ${vartest}"; rc=6 ;;
    esac
    [ "${type}" = "file" ] && [ -f "${!v-}" ] || [ "${type}" != "file" ] || { log_error "file ${!v-} missing"; rc=7; }
    [ "${type}" = "dir" ] && [ -d "${!v-}" ] || [ "${type}" != "dir" ] || { log_error "dir ${!v-} missing"; rc=8; }
  done; return "${rc}"
}



shopt -s extglob
is_true(){ [[ $1 =~ ^@(t|y|yes|true|1)$ ]]; }
is_false(){ [[ $1 =~ ^@(f|n|no|false|0)$ ]]; }
check_fail(){ log_warn "$1"; }
check_defined(){ [[ -v $1 ]]; }
check_equal(){ [[ ${!1} == ${!2} ]]; }
check_digit(){ [[ ${!1} =~ ^[0-9]+$ ]]; }
check_char(){ [[ ${!1} =~ ^[a-zA-Z]+$ ]]; }
check_pi(){ [[ ${!1} =~ ^[1-9][0-9]*$ ]]; }
check_length(){ [[ ${#${1}} -eq $2 ]]; }
check_length_min(){ [[ ${#${1}} -ge $2 ]]; }
check_length_max(){ [[ ${#${1}} -le $2 ]]; }
check_regex(){ [[ ${!1} =~ $2 ]]; }
check_min(){ [[ ${!1} -ge $2 ]]; }
check_max(){ [[ ${!1} -le $2 ]]; }
check_empty(){ [[ -z ${!1} ]]; }
check_lower(){ [[ ${!1} =~ ^[a-z]+$ ]]; }
check_upper(){ [[ ${!1} =~ ^[A-Z]+$ ]]; }
check_contains(){ [[ ${!1} == *$2* ]]; }
check_startswith(){ [[ ${!1} == $2* ]]; }
check_endswith(){ [[ ${!1} == *$2 ]]; }
check_inlist(){ [[ " $2 " =~ ( |^)${!1}( |$) ]]; }
check_exported(){ export -p | grep -q "declare -x $1="; }
check_readonly(){ declare -p $1 2>/dev/null | grep -q 'readonly'; }
check_array(){ declare -p $1 2>/dev/null | grep -q 'declare -a'; }
check_file(){ [[ -f ${!1} ]]; }
check_path(){ [[ -e ${!1} ]]; }
check_float(){ [[ ${!1} =~ ^[+-]?([0-9]*[.])?[0-9]+$ ]]; }
check_valid_env(){ [[ $1 =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; }

################################################################

#!/usr/bin/env bash
# =============================================================================
#  NAME
#      CheckVarAll – versatile Bash variable validation and testing utility
#
#  SYNOPSIS
#      CheckVarAll -name VAR [CHECK FLAG] [VALUE]...
#
#  DESCRIPTION
#      CheckVarAll provides a collection of variable validation functions for shell
#      scripting. It supports boolean checks, regex tests, numeric and character
#      validation, file/path existence, and environment-related tests.
#
#      You can combine multiple checks for one or more variables using `-name`.
#      Each check outputs whether the variable passes or fails the criteria.
#
#  DEPENDENCIES
#      Bash 4+ (uses `[[ -v var ]]` and `${!var}` indirection)
#      extglob (enabled via `shopt -s extglob`)
#
#  ---------------------------------------------------------------------------
#  BOOLEAN HELPERS
#      is_true <val>     # true if val ∈ {t, y, yes, true, 1}
#      is_false <val>    # true if val ∈ {f, n, no, false, 0}
#
#  ---------------------------------------------------------------------------
#  GENERIC CHECKS
#      check_defined var           # variable defined?
#      check_equal var1 var2       # equality test
#      check_digit var             # only digits
#      check_char var              # only letters
#      check_pi var                # positive integer
#      check_length var len        # exact length
#      check_length_min var len    # min length
#      check_length_max var len    # max length
#      check_regex var regex       # regex match
#      check_min var value         # numeric >= value
#      check_max var value         # numeric <= value
#      check_empty var             # empty?
#      check_lower var             # all lowercase
#      check_upper var             # all uppercase
#      check_contains var substr   # contains substring
#      check_startswith var pre    # starts with prefix
#      check_endswith var suf      # ends with suffix
#      check_inlist var "list"     # matches list item
#      check_exported var          # exported?
#      check_readonly var          # readonly?
#      check_array var             # is array?
#      check_file var              # points to file?
#      check_path var              # valid path?
#      check_float var             # float number?
#      check_valid_env var         # valid env var name?
#
#  ---------------------------------------------------------------------------
#  MAIN FUNCTION
#
#      CheckVarAll -name VAR [CHECK FLAG VALUE]...
#
#  FLAGS AND CHECKS
#      -name         <var>       variable to check (repeatable)
#      -defined      true|false  defined / undefined
#      -set          <other_var> compare to another variable
#      -digit        true|false  digits only
#      -char         true|false  letters only
#      -pi           true|false  positive integer
#      -length       <n>         exact length
#      -length_min   <n>         min length
#      -length_max   <n>         max length
#      -regex        <pattern>   regex match
#      -min          <n>         numeric minimum
#      -max          <n>         numeric maximum
#      -empty        true|false  empty / not empty
#      -lower        true|false  lowercase only
#      -upper        true|false  uppercase only
#      -contains     <substr>    substring check
#      -startswith   <prefix>    prefix check
#      -endswith     <suffix>    suffix check
#      -inlist       "<list>"    list membership
#      -exported     true|false  exported / not
#      -readonly     true|false  readonly / not
#      -array        true|false  array / not
#      -file         true|false  file / not
#      -path         true|false  existing path / not
#      -float        true|false  float / not
#      -valid_env    true|false  valid env var name
#
#  ---------------------------------------------------------------------------
#  OUTPUT
#      • Prints failure messages for each failed check
#      • Prints “VAR passes all checks.” if successful
#      • Outputs “Total fail count: N”
#      • Return code = fail count
#
#  ---------------------------------------------------------------------------
#  EXAMPLES
#
#  # Check if variable is defined and numeric
#  num=42
#  CheckVarAll -name num -defined true -digit true
#
#  # Check if a string is uppercase and min length 5
#  word="HELLO"
#  CheckVarAll -name word -upper true -length_min 5
#
#  # Ensure path is not empty and contains 'usr'
#  path="/usr/bin"
#  CheckVarAll -name path -empty false -contains usr
#
#  ---------------------------------------------------------------------------
#  RETURN VALUES
#      0    All checks passed
#      >0   Number of failed checks
#
#  ---------------------------------------------------------------------------
#  AUTHOR
#      Meir Lazar
#
#  ---------------------------------------------------------------------------
#  NOTES
#      • To silence output, redirect stdout/stderr to /dev/null
#      • Combine checks freely; failure count accumulates
# =============================================================================


function CheckVarAll (){
local names=() checks=() arg failcount=0

while [[ $# -gt 0 ]]; do 
	case "$1" in 
	-name) names+=("$2"); log_info "Checking name: $2"; shift 2;; 
	*) checks+=("$1" "$2"); log_info "Testing for these conditions: ${1//-} =  ${2}"; shift 2;; 
        esac; 
done
for name in "${names[@]}"; do
    local localfail=0
for ((i=0;i<${#checks[@]};i+=2)); do
 case "${checks[i]}" in
  -defined) is_true "${checks[i+1]}" && ! check_defined "$name" && check_fail "$name not defined" && ((localfail++)); is_false "${checks[i+1]}" && check_defined "$name" && check_fail "$name is defined" && ((localfail++));;
  -set) ! check_equal "$name" "${checks[i+1]}" && check_fail "$name != ${checks[i+1]}" && ((localfail++));;
  -digit) is_true "${checks[i+1]}" && ! check_digit "$name" && check_fail "$name is not all digits" && ((localfail++)); is_false "${checks[i+1]}" && check_digit "$name" && check_fail "$name should not be all digits" && ((localfail++));;
  -char) is_true "${checks[i+1]}" && ! check_char "$name" && check_fail "$name is not all letters" && ((localfail++)); is_false "${checks[i+1]}" && check_char "$name" && check_fail "$name should not be all letters" && ((localfail++));;
  -pi) is_true "${checks[i+1]}" && ! check_pi "$name" && check_fail "$name is not positive integer" && ((localfail++)); is_false "${checks[i+1]}" && check_pi "$name" && check_fail "$name is positive integer (shouldn't be)" && ((localfail++));;
  -length) ! check_length "$name" "${checks[i+1]}" && check_fail "$name length != ${checks[i+1]}" && ((localfail++));;
  -length_min) ! check_length_min "$name" "${checks[i+1]}" && check_fail "$name length < ${checks[i+1]}" && ((localfail++));;
  -length_max) ! check_length_max "$name" "${checks[i+1]}" && check_fail "$name length > ${checks[i+1]}" && ((localfail++));;
  -regex) ! check_regex "$name" "${checks[i+1]}" && check_fail "$name does not match regex" && ((localfail++));;
  -min) ! check_min "$name" "${checks[i+1]}" && check_fail "$name < ${checks[i+1]}" && ((localfail++));;
  -max) ! check_max "$name" "${checks[i+1]}" && check_fail "$name > ${checks[i+1]}" && ((localfail++));;
  -empty) is_true "${checks[i+1]}" && ! check_empty "$name" && check_fail "$name is not empty" && ((localfail++)); is_false "${checks[i+1]}" && check_empty "$name" && check_fail "$name is empty (shouldn't be)" && ((localfail++));;
  -lower) is_true "${checks[i+1]}" && ! check_lower "$name" && check_fail "$name is not all lowercase" && ((localfail++));;
  -upper) is_true "${checks[i+1]}" && ! check_upper "$name" && check_fail "$name is not all uppercase" && ((localfail++));;
  -contains) ! check_contains "$name" "${checks[i+1]}" && check_fail "$name does not contain ${checks[i+1]}" && ((localfail++));;
  -startswith) ! check_startswith "$name" "${checks[i+1]}" && check_fail "$name does not start with ${checks[i+1]}" && ((localfail++));;
  -endswith) ! check_endswith "$name" "${checks[i+1]}" && check_fail "$name does not end with ${checks[i+1]}" && ((localfail++));;
  -inlist) ! check_inlist "$name" "${checks[i+1]}" && check_fail "$name is not in list" && ((localfail++));;
  -exported) is_true "${checks[i+1]}" && ! check_exported "$name" && check_fail "$name is not exported" && ((localfail++));;
  -readonly) is_true "${checks[i+1]}" && ! check_readonly "$name" && check_fail "$name is not readonly" && ((localfail++));;
  -array) is_true "${checks[i+1]}" && ! check_array "$name" && check_fail "$name is not array" && ((localfail++));;
  -file) is_true "${checks[i+1]}" && ! check_file "$name" && check_fail "$name is not a file" && ((localfail++));;
  -path) is_true "${checks[i+1]}" && ! check_path "$name" && check_fail "$name is not a valid path" && ((localfail++));;
  -float) is_true "${checks[i+1]}" && ! check_float "$name" && check_fail "$name is not a float" && ((localfail++));;
  -valid_env) is_true "${checks[i+1]}" && ! check_valid_env "$name" && check_fail "$name is not a valid env name" && ((localfail++));;
 esac
done
if [[ $localfail -eq 0 ]]; then log_info "$name passes all checks."; fi
((failcount+=localfail))
done
log_notice "Total fail count: $failcount"
return $failcount
}



##########################################################################################
#################################### DATABASE FUNCTIONS ##################################
##########################################################################################


###########################################
# NAME
#   RunSql - execute SQL against Oracle using sqlplus
# SYNOPSIS
#   RunSql "<SQL STATEMENTS>"
# DESCRIPTION
#   Runs the provided SQL using ORACLE_SQLPLUS and ORACLE_CONNECT (constructed from DB_USER/DB_PWD/JDE_DB).
# PRECHECKS
#   DB_USER, DB_PWD, and JDE_DB must be set; sqlplus must be reachable.
# RETURNS
#   0 on success, non-zero on failure
function RunSqlCommands() {
  local sql=${*}  rc=0 out
  ValidateVar --variable=DB_USER,DB_PWD,JDE_DB,ORACLE_SQLPLUS,DB_CONNECT --vartest=notempty || return 2

out=$("${DB_CONNECT}"  << 'EOF' 2>&1  
WHENEVER SQLERROR EXIT FAILED ROLLBACK
SET FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF;
${sql}
EXIT;
EOF
) 

rc=$?; 
[ "${rc}" -eq 0 ] || { log_error "sqlplus failed"; log_error "${out}"; return "${rc}"; }
log_info "Successfully ran sql commands - output = ${out}"; 
return "${rc}"
}




###########################################
# NAME
#   RunSqlScript - execute SQL against Oracle using sqlplus
# SYNOPSIS
#   RunSqlScript "</path/to/file.sql>"
# DESCRIPTION
#   Runs the provided SQL using ORACLE_SQLPLUS and ORACLE_CONNECT (constructed from DB_USER/DB_PWD/JDE_DB).
# PRECHECKS
#   DB_USER, DB_PWD, and JDE_DB must be set; sqlplus must be reachable.
# RETURNS
#   0 on success, non-zero on failure
function RunSqlScript(){
  local sql=${*} rc=0
  ValidateVar --variable=DB_USER,DB_PWD,JDE_DB,ORACLE_SQLPLUS,DB_CONNECT,sql --vartest=notempty || return 2
  CheckFile "${sql}" exist read data || return 3

out=$("${DB_CONNECT}" @"${sql}" 2>&1) 

rc=$?

[ "${rc}" -eq 0 ] || { log_error "sqlplus failed"; log_error "${out}"; return "${rc}"; }
log_info "Successfully ran sql commands - output = ${out}";
return "${rc}"
}



########################################################


function TruncateDeleteCountTable() {
local table="${1:-}"
ValidateVar --variable=table --vartest=notempty || return 2

declare -A sql_tasks=(
  ["truncate_table"]="TRUNCATE TABLE ${OWNER_BUSDTA}.${table};"
  ["delete_from_table"]="DELETE * FROM ${OWNER_BUSDTA}.${table}; COMMIT;"
  ["count_rows_in_table"]="SELECT COUNT(*) FROM ${OWNER_BUSDTA}.${table};"
)

log_info "Running tasks: ${sql_tasks[*]}"
RunSQL_Batch "${sql_tasks[@]}"  || { log_warn "${OWNER_BUSDTA}.${table} - Failed to run tasks"; return 1; }
  log_info "${OWNER_BUSDTA}.${table} - Tasks ran Successfully"; return 0;
}



###########################################
# NAME
#   TruncateTable - truncate an Oracle table
# SYNOPSIS
#   TruncateTable <table_name>
# DESCRIPTION
#   Executes TRUNCATE TABLE <table_name>; returns 0 even if table is empty.
# PRECHECKS
#   Requires RunSql prechecks (DB_USER/DB_PWD/JDE_DB).
# RETURNS
#   0 on success, non-zero on error

function TruncateTable() {
  local table="${1:-}"
  ValidateVar --variable=table --vartest=notempty || return 2 
  log_info "${OWNER_BUSDTA}.${table} - Attempting to truncate table"; 
  RunSql "TRUNCATE TABLE ${OWNER_BUSDTA}.${table};" || { log_warn "${OWNER_BUSDTA}.${table} - Failed to truncate table"; return 1; }
  log_info "${OWNER_BUSDTA}.${table} - Truancated Successfully"; return 0; 
}


###########################################
# CountRowsInTable
###########################################
# NAME
#   TruncateTable - truncate an Oracle table
# SYNOPSIS
#   TruncateTable <table_name>
# DESCRIPTION
#   Executes TRUNCATE TABLE <table_name>; returns 0 even if table is empty.
# PRECHECKS
#   Requires RunSql prechecks (DB_USER/DB_PWD/JDE_DB).
# RETURNS
#   0 on success, non-zero on error

function CountRowsInTable() {
  local table="${1:-}"
  [ -n "${table}" ] || { log_error "Missing table"; return 2; }
  log_info "Counting rows in ${OWNER_BUSDTA}.${table}"; 
   if ! RunSql "SELECT COUNT(*) FROM ${OWNER_BUSDTA}.${table};"; then log_error "Fail"; return 3; 
   else  log_info "OK"; fi
}

###########################################
function FastCountRowsInTable() {
  local table="${1:-}"
  [ -n "${table}" ] || { log_error "Missing table"; return 2; }
  log_info "Counting rows in ${OWNER_BUSDTA}.${table}";
  if RunSql "SELECT COUNT(*) FROM ${OWNER_BUSDTA}.${table} WHERE ROWNUM = 1;"; then  log_info "OK";
  else log_error "Fail"; return 3; fi
}



###########################################
# NAME
#   DeleteFromTable - delete rows from an Oracle table
# SYNOPSIS
#   DeleteFromTable <table_name> [commit|nocommit]
# DESCRIPTION
#   Executes DELETE FROM <table_name>; commits by default. Returns 0 if successful.
# PRECHECKS
#   Requires RunSql prechecks and appropriate DB privileges.
# RETURNS
#   0 on success, non-zero on error
function DeleteFromTable() {
  local table="${1:-}" commit="${2:-commit}" sql
  [ -n "${table}" ] || { log_error "Missing table"; return 2; }
  sql="DELETE * FROM ${OWNER_BUSDTA}.${table};"; [ "${commit}" = "commit" ] && sql="${sql} COMMIT;"
  log_info "Clearing ${OWNER_BUSDTA}.${table}"; 
  if RunSql "${sql}"; then log_info "OK"; else log_error "Fail"; return 3; fi
}

###########################################
# ClearTable
###########################################
# NAME
#   ClearTable - delete rows from an Oracle table
# SYNOPSIS
#   ClearTable <table_name> [commit|nocommit]
# DESCRIPTION
#   Executes DELETE FROM <table_name>; commits by default. Returns 0 if successful.
# PRECHECKS
#   Requires RunSql prechecks and appropriate DB privileges.
# RETURNS
#   0 on success, non-zero on error
function ClearTable() {
  local table="${1:-}" commit="${2:-commit}" sql
  [ -n "${table}" ] || { log_error "Missing table"; return 2; }
  sql="TRUNCATE TABLE ${OWNER_BUSDTA}.${table}; DELETE * FROM ${OWNER_BUSDTA}.${table}; SELECT COUNT(*) FROM ${OWNER_BUSDTA}.${table} WHERE ROWNUM = 1;"
  [ "${commit}" = "commit" ] && sql="${sql} COMMIT;"
  log_info "Clearing ${OWNER_BUSDTA}.${table}"; 
  if RunSql "${sql}"; then log_info "OK"; else log_error "Fail"; return 3; fi
}


#################################################################################################################################
########################################### FILE FUNCTIONS ###################################################################
#################################################################################################################################




# ==============================================================================
# NAME
#     CheckFile - Validate file properties using parameter flags
#
# SYNOPSIS
#     CheckFile --file=<filename> [--perms=<rwx>] [--exist=<t|f>] [--empty=<t|f>] [--type=<type>]
#
# DESCRIPTION
#     Performs checks on a file using standard-style flags:
#       --file   : Full path to the file (case-sensitive)
#       --perms  : Permissions to check (any combination of r, w, x)
#       --exist  : 't' to require existence, 'f' to require non-existence
#       --empty  : 't' to require empty file, 'f' to require non-empty
#       --type   : Expected file type (case-insensitive):
#                   regular, directory, symlink, socket, block, char, fifo, binary, text
#
# RETURN VALUE
#     Returns 0 if all checks pass, otherwise returns number of failed checks.
#
# EXAMPLES
#     CheckFile --file=/tmp/test.sh --perms=rwx --exist=t --empty=f --type=regular
# ==============================================================================
:<< 'EOF'
NAME
    CheckFile - Validate file properties using flexible command-line flags

SYNOPSIS
    CheckFile --file=<filename> [--perms=<rwx>] [--exist=<t|f>] [--empty=<t|f>] [--type=<type>]

DESCRIPTION
    CheckFile is a Bash function that performs a series of tests on a specified file.
    It supports flexible, Unix-style flags to check for existence, permissions, content,
    and file type. All flags are case-insensitive except for the filename and path.

OPTIONS
    --file=<filename>
        Specifies the full path to the file to be checked.
        This is required and must be case-sensitive.

    --perms=<rwx>
        Checks for file permissions. Use any combination of:
            r - readable
            w - writable
            x - executable

    --exist=<t|f>
        Checks whether the file exists.
            t or true  - file must exist
            f or false - file must not exist

    --empty=<t|f>
        Checks whether the file is empty.
            t or true  - file must be empty
            f or false - file must contain data

    --type=<type>
        Checks the file type. Supported types (case-insensitive):
            regular    - regular file
            directory  - directory
            symlink    - symbolic link
            socket     - Unix domain socket
            block      - block device
            char       - character device
            fifo       - named pipe
            binary     - detected as binary via `file` command
            text       - detected as text via `file` command

RETURN VALUE
    Returns 0 if all specified checks pass.
    Returns a non-zero value equal to the number of failed checks.

EXAMPLES
    CheckFile --file=/tmp/test.sh --perms=rwx --exist=t --empty=f --type=regular
        Checks that /tmp/test.sh exists, is not empty, is a regular file,
        and has read, write, and execute permissions.

    CheckFile --file=/dev/null --type=char
        Verifies that /dev/null is a character device.

AUTHOR
    Custom Bash utility by user request. Designed for modularity and extensibility.

NOTES
    - All flags except --file are case-insensitive.
    - Logging is handled via the Log function (must be defined externally).
    - Uses Bash extended globbing and process substitution for efficiency.
EOF

function CheckFile() {
    shopt -s extglob
    local failcount=0
    local filename="" perms="" exist="" empty="" ftype=""
    log_info  "Started"
    # Helper: build "<filename> is not <desc>" message
    TellFail() { log_warn "${filename} is not $1"; }
    # Helper: log error and increment failcount if condition is true
    FailIf() { if [[ $1 ]]; then log_warn "$2"; else ((failcount++)); fi; }

    # Parse arguments
    for arg in "$@"; do
        case "${arg,,}" in
            --file=*) filename="${arg#--file=}" ;;  # case-sensitive
            --perms=*) perms="${arg#--perms=}" ;;
            --exist=*) exist="${arg#--exist=}" ;;
            --empty=*) empty="${arg#--empty=}" ;;
            --type=*) ftype="${arg#--type=}" ;;
            *) FailIf 1 "Unknown parameter: ${arg}" ;;
        esac
    done

    [[ -z "${filename}" ]] && FailIf 1 "Missing --file parameter" && return 1

    log_info "Checking file: ${filename}"

    # Existence check
    case "${exist,,}" in
        t|true) FailIf [[ ! -e "${filename}" ]] "$(TellFail exist)" ;;
        f|false) FailIf [[ -e "${filename}" ]] "${filename} exists but shouldn't" ;;
        "") ;; # no check
        *) FailIf 1 "Invalid --exist value: ${exist}" ;;
    esac

    # Empty check using process substitution
    case "${empty,,}" in
        t|true) FailIf [[ "$(grep -c '^' < <(cat -n "${filename}"))" -ne 0 ]] "$(TellFail empty)" ;;
        f|false) FailIf [[ "$(grep -c '^' < <(cat -n "${filename}"))" -eq 0 ]] "${filename} is empty" ;;
        "") ;; # no check
        *) FailIf 1 "Invalid --empty value: ${empty}" ;;
    esac

    # Permissions check
    [[ -n "${perms}" ]] && for (( i=0; i<${#perms}; i++ )); do
        case "${perms:i:1}" in
            r) FailIf [[ ! -r "${filename}" ]] "$(TellFail readable)" ;;
            w) FailIf [[ ! -w "${filename}" ]] "$(TellFail writable)" ;;
            x) FailIf [[ ! -x "${filename}" ]] "$(TellFail executable)" ;;
            *) FailIf 1 "Unknown permission flag: ${perms:i:1}" ;;
        esac
    done

    # Type check
    case "${ftype,,}" in
        regular) FailIf [[ ! -f "${filename}" ]] "$(TellFail regular file)" ;;
        directory) FailIf [[ ! -d "${filename}" ]] "$(TellFail directory)" ;;
        symlink) FailIf [[ ! -L "${filename}" ]] "$(TellFail symlink)" ;;
        socket) FailIf [[ ! -S "${filename}" ]] "$(TellFail socket)" ;;
        block) FailIf [[ ! -b "${filename}" ]] "$(TellFail block device)" ;;
        char) FailIf [[ ! -c "${filename}" ]] "$(TellFail character device)" ;;
        fifo) FailIf [[ ! -p "${filename}" ]] "$(TellFail named pipe)" ;;
        binary) FailIf ! file "${filename}" | grep -qi 'binary' "$(TellFail binary)" ;;
        text) FailIf ! file "${filename}" | grep -qi 'text' "$(TellFail text)" ;;
        "") ;; # no check
        *) FailIf 1 "Unknown --type value: ${ftype}" ;;
    esac

   if ((failcount == 0)); then log_info "${filename} - All checks passed"; else
   log_error  "${filename} - ${failcount} checks failed";
   fi

    log_info "Finished"
    return ${failcount}
}

###########################################

function ClearFile() {
   local filename=$1 rc=0
   log_info  "Started" 
   log_info "${filename} - Attempting to clear file"
   if truncate -c -s 0 "${filename}"; then log_info "${filename} - cleared successfully"; return 0; fi
    log_warn "${filename} - Failed to be cleared"; return 1
}

###########################################
# MoveFile
###########################################
# NAME
#   MoveFile - move a file atomically when possible
# SYNOPSIS
#   MoveFile <source> <destination>
# DESCRIPTION
#   Moves a file
# PRECHECKS
#   Source file must exist and be readable, dest path must exist and the dir writeable.
# RETURNS
#   0 on success, 1 on failure, 2 if src dir or file is missing, 3 if dest dir is missing, 
function MoveFile() {
  local src="${1:-}" dst="${2:-}"
  [[ -d "${src%/*}" ]] || { log_error "src dir does not exist"; return 1; }
  [[ -f "${src}" ]] || { log_error "src file does not exist"; return 1; }
  [[ -d "${dst%/*}" ]] || { log_error "dest dir does not exist"; return 2; }
  mv "${src}" "${dst}" || { log_error "move failed"; return 1; }
   log_info "${src}->${dst}"; return 0
}

###########################################
# RotateLogs
###########################################
# NAME
#   RotateLogs - compress and prune old logs
# SYNOPSIS
#   RotateLogs <days> [logdir]
# DESCRIPTION
#   Gzips files older than <days> and deletes gz archives older than 2*<days>.
# PRECHECKS
#   LOGDIR or the provided logdir must exist and be writable.
# RETURNS
#   0 on success
function RotateLogs() {
  local days="${1:-30}" dir="${2:-${LOGDIR}}"
  log_info "rotate >${days}d in ${dir}"
  find "${dir}" -type f -mtime +"${days}" ! -name '*.gz' -print0 | while IFS= read -r -d '' f; do 
    gzip -9 "${f}" 2> /dev/null
	if gunzip -lt "${f}"; then log_info "gzipped ${f}"; else log_warn "gzip fail ${f}"; fi; done
  find "${dir}" -type f -name '*.gz' -mtime +$((days*2)) -delete
}


###########################################
# TestMode
###########################################
# NAME
#   TestMode - static syntax check for scripts
# SYNOPSIS
#   TestMode <script1> [script2 ...]
# DESCRIPTION
#   Runs 'bash -n' on each provided script and logs results.
# PRECHECKS
#   bash must be installed and accessible.
# RETURNS
#   0 if all checks pass, non-zero otherwise
function TestMode() {
  local rc=0
  [ "$#" -ge 1 ] || { log_error "usage"; return 2; }
  for s in "$@"; do 
      if [[ -f "${s}" ]]; then 
	      if ! bash -n "${s}"; then log_error "fail ${s}"; rc=4; else  log_info "OK ${s}"; fi 
	  fi
   done
  return "${rc}"
}

###########################################
# DateVars
###########################################
# NAME
#   DateVars - export common date/time variables
# SYNOPSIS
#   DateVars [VAR1 VAR2 ...]
# DESCRIPTION
#   Exports TODAY, NOW, JULIAN, FULLDATETIME. When args given, updates only specified vars.
# PRECHECKS
#   date command must be available.
# RETURNS
#   0 on success
function DateVars() {
  local today now julian full
  today="$(date +%F)"; now="$(date +%FT%T%z)"; julian="$(date +%Y%j)"; full="$(date +%Y%m%d_%H%M%S)"
  if [ "$#" -eq 0 ]; then export TODAY="${today}" NOW="${now}" JULIAN="${julian}" FULLDATETIME="${full}"; else
    export TODAY="${today}" ; export NOW="${now}" ; export JULIAN="${julian}" ; export FULLDATETIME="${full}" ; 
  fi
return 0
}

###########################################
# NAME
#   StageFile - copy a file into the staging area
# SYNOPSIS
#   StageFile /full/path file
# DESCRIPTION
#   Copies the source file into STAGE_DIR 
# PRECHECKS
#   Source file must exist and be readable.
# RETURNS
#   0 on success
function StageFile() {
  local src="$1" 
  local name="$2" 
  [ -d "${src}" ] || { log_error "src dir ${src} - is missing"; return 2; }
  echo "testdata" >>  "${src}/${name}"  || { log_error "staging file failed ${src}/${name}"; return 3; }
  log_info "Created File with data ${src}/${name}" ; return 0;
}



###########################################
# NAME
#   FileIsEmpty - determine if a file has zero lines
# SYNOPSIS
#   FileIsEmpty /path/to/file
# DESCRIPTION
#   Returns 0 if file exists and has zero lines; 1 if it has lines; 2 on error.
# PRECHECKS
#   File must exist.
# RETURNS
#   0 if empty, 1 if not empty, 2 if error

function FileIsEmpty() {
  local f="${1:-}"
  [[ -f "${f}" ]] || { log_error "file missing"; return 2; }
  [[ "$(wc -l <"${f}")" -eq 0 ]] ||  { log_info "not empty"; return 1; }
  log_info "empty"; return 0; 
}



###########################################
# DirFileExists
###########################################
# NAME
#   DirFileExists - check if a file or dir exists
# SYNOPSIS
#   DirFileExists <DIR / FILE>
# DESCRIPTION
#   Returns 0 if either it is a dir or file and it exists, 1 if does not exist, 2 if variable (if used) is undefined.
# PRECHECKS
#   Variable name must be supplied.
# RETURNS
#   0 if exists, 1 if not exist, 2 if undefined
function DirFileExists() {
    local var="${1}" path
    [ -n "${var}" ] || { log_error  "no var"; return 2; }
    # Check if argument is a valid, defined variable
    if [[ "${var}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] && [[ "${!var+set}" = "set" ]]; then path="${var%/*}"; else path="${!var}";  fi
    [ -n "${path}" ] || { log_error "undef or empty"; return 2; }
    [ -f "${path}" ] && { log_info "File exists: ${path}"; return 0; }
    [ -d "${path}" ] && { log_info "Dir exists: ${path}"; return 0; }
    log_warn "Dir/File does not exist: ${path}"; return 1
}


#################################################################################################################################
########################################### LOGGING FUNCTIONS ###################################################################
#################################################################################################################################

:<< 'EOF'
NAME
    CheckParams - Flexible parameter validation for Bash scripts and functions

SYNOPSIS
    CheckParams --expected="param1,param2,param3" [args...]

DESCRIPTION
    CheckParams is a reusable Bash function that validates positional parameters
    passed to a script or function. It maps each parameter to a named variable
    and ensures required values are present and non-empty.

    This function is designed to be portable across scripts and functions,
    allowing you to define expected parameters dynamically and access them
    by name after validation.

OPTIONS
    --expected="param1,param2,param3"
        A comma-separated list of expected parameter names.
        The order of names must match the order of positional arguments passed to the script.

    args...
        Positional arguments corresponding to the expected parameter names.

BEHAVIOR
    - Validates that the number of provided arguments matches the expected count.
    - Ensures each expected parameter has a non-empty value.
    - Logs errors using the Log function (must be defined externally).
    - Exits with code 1 if validation fails.
    - On success, exports each parameter as a named variable for use in the script.

RETURN VALUE
    Returns 0 if all checks pass.
    Exits with code 1 if validation fails.

EXAMPLES
    CheckParams --expected="mode,env,file" "$@"
        Validates that three parameters were passed and maps them to:
            $mode, $env, $file

    CheckParams --expected="action,target" "$@"
        Validates two parameters and maps them to:
            $action, $target

NOTES
    - Parameter names are case-sensitive.
    - All parameters are treated as required.
    - Logging requires a pre-defined Log function with INIT, INFO, DEBUG, ERROR, FATAL levels.
EOF


function CheckParams() {
    local failcount=0 name value
    unset PARAMS_MAP expected_names
    declare -A PARAMS_MAP=()
    declare -a expected_names=()
    local expected_list=""
    local raw_args=()
   log_info  "Starting Parameter Checks"
    # Helper: log error and increment failcount
    FailIf() { if [[ $1 ]]; then log_warn "$2" ; ((failcount++));fi; }

    # Parse arguments
    for arg in "$@"; do
        case "${arg,,}" in
            --expected=*) expected_list="${arg#--expected=}" ;;
            *) raw_args+=("${arg}") ;;
        esac
    done
    [[ -z "${expected_list}" ]] && { FailIf 1 "Missing --expected parameter"; }

    # Split expected names
    IFS=',' read -ra expected_names <<< "${expected_list}"

    # Validate count
    if [[ ${#raw_args[@]} -lt ${#expected_names[@]} ]]; then FailIf 1 "Expected ${#expected_names[@]} parameters, but received ${#raw_args[@]}";  fi

    # Map values to names
    for i in "${!expected_names[@]}"; do
	 name="${expected_names[$i]}" ; value="${raw_args[$i]}"
      if [[ -z "${value}" ]]; then FailIf 1 "Missing value for ${name}"; else PARAMS_MAP["${name}"]="${value}" ; log_debug "${func}" "${name} = ${value}"; fi;
    done

    case ${failcount} in 
	0 ) log_info "All parameter checks passed";;
	* ) log_error "Parameter validation failed with ${failcount} error(s)"; 
   esac
   
    # Export mapped variables for use
    for key in "${!PARAMS_MAP[@]}"; do 
	  log_debug  "Mapping ${key} = ${PARAMS_MAP[$key]}"; 
	  export "${key}"="${PARAMS_MAP[$key]}"; 
	done
	
    log_info "Return code = ${failcount}"
    return ${failcount}
}

function ElapsedTime() {

local OLD_CONSOLE_LOG="$CONSOLE_LOG"
CONSOLE_LOG="false"  # Quiet mode ON

local start=$1
start=${start:=${STARTTIME}}
# Calculate elapsed time in nanoseconds
local end="$(date +%s%N)"
local elapsed_ns=$((end - start))

# Convert to components
local elapsed_ms=$((elapsed_ns / 1000000))
local elapsed_sec=$((elapsed_ns / 1000000000))
local elapsed_min=$((elapsed_sec / 60))
local remaining_sec=$((elapsed_sec % 60))
local remaining_ms=$(( (elapsed_ns / 1000000) % 1000 ))
local remaining_ns=$((elapsed_ns % 1000000))

# Display result
log_info "Elapsed time: ${elapsed_min} min ${remaining_sec} sec ${remaining_ms} ms ${remaining_ns} ns"
echo "Elapsed time: ${elapsed_min} min ${remaining_sec} sec ${remaining_ms} ms ${remaining_ns} ns"
CONSOLE_LOG="$OLD_CONSOLE_LOG"  # Restore previous setting

}

###########################################
# CleanupAndExit
###########################################
# NAME
#   CleanupAndExit - cleanup tmp files and exit
# SYNOPSIS
#   CleanupAndExit <exitcode>
# DESCRIPTION
#   Removes any dangling files, exports LAST_EXIT_CODE, and exits.
# RETURNS
#   Exits the process with given code

function CleanupAndExit() {
  local func="${FUNCNAME[0]}" 
  log_fatal "${func}" "Script failed at function $1 Line number =$2 exit code $3"
  exit "${3}"
}

###########################################
# _OnExitHandler (trap)
###########################################
# NAME
#   _OnExitHandler - trap handler for EXIT/HUP/INT/TERM
# SYNOPSIS
#   _OnExitHandler
# DESCRIPTION
#   Performs light cleanup and logs the exit signal.
# PRECHECKS
#   None.
# RETURNS
#   none
#function _OnExitHandler() { local rc="$?"; log_warn "_OnExitHandler" "Signal rc=${rc}"; rm -f "${TMPDIR}"/* 2>/dev/null || true; }
# trap _OnExitHandler EXIT HUP INT TERM



:<< 'EOF'
NAME
    ConvertDate - Convert dates from various formats into a specified output format

SYNOPSIS
    ConvertDate --input=<date> [--format=<output_format>]

DESCRIPTION
    ConvertDate is a Bash function that parses and converts dates from multiple input styles
    into a user-defined output format. It supports natural language inputs, standard date strings,
    Julian dates, and Unix timestamps.

OPTIONS
    --input=<date>
        Specifies the input date to convert. Supported formats include:
            - Standard date strings (e.g., 2025-10-31, 10/31/2025)
            - Natural language (e.g., "yesterday", "now", "next Friday")
            - Unix timestamp (e.g., 1698710400)
            - Julian date (e.g., 2459965)

    --format=<output_format>
        Specifies the desired output format using `date` formatting syntax.
        Common examples:
            %Y%m%d       → 20251031
            %F           → 2025-10-31
            %A, %B %d    → Friday, October 31
            %s           → Unix timestamp
            %j           → Julian day of the year (001–366)

        Default format is `%F` (ISO 8601: YYYY-MM-DD).

RETURN VALUE
    Prints the converted date to stdout.
    Returns 0 on success, 1 on failure.

EXAMPLES
    ConvertDate --input="yesterday" --format="%Y%m%d"
        → Outputs yesterday's date in YYYYMMDD format.

    ConvertDate --input="1698710400" --format="%F"
        → Converts Unix timestamp to ISO date.

    ConvertDate --input="2459965" --format="%A, %B %d"
        → Converts Julian date to full weekday and date.

    ConvertDate --input="next Friday" --format="%Y-%m-%d"
        → Outputs the date of next Friday in ISO format.

	ConvertDate --input="yesterday" --format="%Y%m%d"
	ConvertDate --input="1698710400" --format="%F"
	ConvertDate --input="2459965" --format="%A, %B %d"
	ConvertDate --input="next Friday" --format="%Y-%m-%d"

NOTES
    - All flags are case-insensitive except for the input date string.
    - Logging is handled via the Log function (must be defined externally).
    - Uses Bash and GNU `date` with support for `--date` and `--utc`.
    - Julian date conversion assumes astronomical Julian Day Number (JDN).
    - For Julian conversion, the function subtracts 2440587.5 to get Unix timestamp.
EOF

ConvertDate() {
    
    local OLD_CONSOLE_LOG="$CONSOLE_LOG"    
    CONSOLE_LOG="false"  # Quiet mode ON, this function outputs the cojversion, so nothing can echo out to stdout

    local func="${FUNCNAME[0]}"
    local input="" format="%F" failcount=0   result ts

    # Logging helpers (assumes Log function exists)
   log_info  "Started"
    FailIf() { [[ $1 ]] && log_error "${func}" "$2" && ((failcount++)); }

    for arg in "$@"; do
        case "${arg,,}" in
            --input=*) input="${arg#--input=}" ;;
            --format=*) format="${arg#--format=}" ;;
            *) FailIf 1 "Unknown parameter: ${arg}" ;;
        esac
    done

    [[ -z "${input}" ]] && FailIf 1 "Missing --input parameter" && return 1

    # Convert Julian to Unix timestamp if input is a Julian date (5+ digits starting with 24 or 25)
    if [[ "${input}" =~ ^24[0-9]{4}$|^25[0-9]{4}$ ]]; then
        # Julian Day Number to Unix timestamp: (JDN - 2440587.5) * 86400
        ts=$(awk "BEGIN { print int((${input} - 2440587.5) * 86400) }")
        input="@${ts}"
    elif [[ "${input}" =~ ^[0-9]{10}$ ]]; then
        # Unix timestamp
        input="@${input}"
    fi

    # Try conversion
    result=$(date --utc --date="${input}" +"${format}" 2>/dev/null)

    if [[ -z "${result}" ]]; then  FailIf 1 "Failed to convert input: ${input}";    
    else  log_info "${func}" "Converted '${input}' → ${result}";      
	   echo "${result}"
    fi
    log_info "Completed"
    CONSOLE_LOG="$OLD_CONSOLE_LOG"  # Restore previous setting
    return ${failcount}
}


