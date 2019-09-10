#!/bin/bash

# A template script with a uniform approach for creating easily repeatable automated
# functions in the absense of automation tools like Ansible.

#functions that are used to <insert what the purpose of the script is>
#the functions provide: 
# -- a clear function name related to the functions action
# -- a simple or complex multiline description of the function above the function 
# -- a variable named INFO responsible for describing the functions actions (simple one liner)
# ---- (ex. Coppy file.txt to /etc/file.txt)
# -- a check that valiadates whether or not the funtion succeeded with output 
# ---- (ex. cp /file.txt /etc/file.txt if [ "/etc/file.txt" ] return "coppied to /etc/file.txt" fi)
# -- a return code of 0 for success or 1 for failure based on the validation checks and 2 for
# -- partial succes in the case of multiple tasks for one function
# ---- (ex. if [ "/etc/file.txt" ] return 0)

#### EXAMPLE FUNCTON

#A sample function that displays what a function should look like and how it should
#validate and output appropriate response codes.

# create script log 
create_script_log ()
{
    #info for task create_script_log
    local INFO="Creating </path/to/><scriptname.log>"
    echo "Executing $INFO"

    #tasks for create_script_log
    ACTION_LOG='</path/to/><scriptname.log>'
    echo "[ACTION LOG]" > $ACTION_LOG

    #validatation for create_script_log
    if [[ ! -f $ACTION_LOG ]]
        do
            echo "Failed task: $INFO with error: $ACTION_LOG"
        done
    fi
}

# Change permissions on the following file:
skeleton_function ()
{
    #info
    local INFO="<function info>"
    echo "Executing $INFO"

    #action
    local actions=
    (
        <action declaration>
    )

    for item in ${actions[@]}
        do
            local temp_stat=$($item 2> )
        done

    #validation
    if [[ "<if conditional true then task failure>" ]]
        then
            echo "Failed task: $INFO with error: <variable holding stderr>" >> $ACTION_LOG
            echo "Failed task: $INFO with error: "
    fi
}

#### COLOR VARIABLES
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
WHITE='\033[1;37m'
NO_COL='\033[0m'
BOLD='\x1b[1m'

PASSED=$(printf "${BOLD}[  ${GREEN}${BOLD}PASSED  ${NO_COL}${BOLD}] \n")
WARNING=$(printf "${BOLD}[  ${YELLOW}${BOLD}WARNING ${NO_COL}${BOLD}] \n")
FAILED=$(printf "${BOLD}[  ${RED}${BOLD}FAILED  ${NO_COL}${BOLD}] \n")

#### ACTION OUTPUTS
######## [  PASSED  ] (Green lettering) returned code 0 with validation the action was performed
######## [  WARNING ] (Yellow lettering) returned exit code 0 with no proper validation the action
########              was performed or passed with code 0 but a warning ocndition was met
######## [  FAILED  ] (Red lettering) returned exit code 1 with validation the action was performed and did not work


#### EXECUTE MAIN
main () 
{
    execute_functions=
    (
        create_script_log
        skeleton_function 
    )
    
    for func in ${execute_functions[@]}
        do
            $func
        done 
}

main
