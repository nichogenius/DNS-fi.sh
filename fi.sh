#   * * * * * * * * * * * * * * * * * * * * * * * * *
#   * fish v1.6                                     *
#   * Written and maintained by Nick Christensen    *
#   * nichogenius@gmail.com                         *
#   * * * * * * * * * * * * * * * * * * * * * * * * *


#!/bin/bash
#*************************************************************************************
#Use This Section to customize the Text Coloring:
#Color chart can be found at http://misc.flogisoft.com/bash/tip_colors_and_formatting
#Use the chart under the 88/256 Colors Section

COLORS_ENABLED=false

SEARCHED_FOR_RECORD_COLOR=81
RECORD_HEADER_COLOR=11
NAME_SERVER_COLOR=81
RECORD_COLOR=155
GOOD_COLOR=82
BAD_COLOR=196
ERROR_COLOR=124
DIVIDE_COLOR=240
DIVIDE_LABEL_COLOR=81
DOMAIN_COLOR=27

#Use this section to customize the repeated character in the label break
#Only single characters will work

DIVIDE_CHAR="="

# Use this section to customize the default record search options. 
# At least A and MX are recommended.

DEFAULT_RECORD_SEARCH=(A MX)
MULTI_DOMAIN_DEFAULT_SEARCH=(A)
#*************************************************************************************
ERR_NO_DOMAIN="Error: No Domain Name Given"
ERR_NO_NAMESERVERS="No Nameservers Found"
ERR_NO_RECORD="  NO RECORD FOUND"
#*************************************************************************************
function main()
{
	parseArgs $@
	for domain in ${domains[@]}
	do
		echo
		processDomain "$domain"
	done
	printDiv "--COMPLETE--"
}

function parseArgs()
{
	while [ $# -gt 0 ]
	do
        	if echo "$1" | grep -q "[a-zA-Z0-9\-]\+[\.][a-zA-Z0-9\-]\+"
        	then
			local temp=${1,,}
			local domain_present=false
			for i in ${domains[@]}
			do
				if [ "$i" = "$temp" ]
				then
					domain_present=true
					break
				fi
			done
			if [ "$domain_present" = "false" ]
			then
				domains=( ${domains[@]} $temp )
			fi
        	else
			local temp=${1^^}
			local record_present=false
			for i in ${records[@]}
			do
				if [ "$i" = "$temp" ]
				then
					record_present=true
					break
				fi
			done
			if [ "$record_present" = "false" ]
			then
                		records=( ${records[@]} $temp )
			fi		
        	fi
        shift
	done

        if [ ${#domains[@]} -eq 0 ]
        then
		printError "$ERR_NO_DOMAIN"
                exit
        fi
	domain_count=$(( ${#domains[@]} - 1 ))
	for i in `seq 0 $domain_count`
	do
	        if [[ "${domains[$i]}" != *. ]]
        	then
                	domains[$i]+="."
        	fi
	done

        if [ ${#records[@]} -eq 0 ]
        then
		if [ ${#domains[@]} -gt 1 ]
		then
			records=${MULTI_DOMAIN_DEFAULT_SEARCH[@]}			
		else
                	records=${DEFAULT_RECORD_SEARCH[@]}
		fi
        fi
}

function processDomain()
{	
	record_string=$(IFS=" "; echo "${records[@]}")
        printInlineColor "$1" $DOMAIN_COLOR
        echo -n "        "
        printInlineColor "$record_string" $SEARCHED_FOR_RECORD_COLOR
        echo

        name_servers=( $(dig +trace $1 | grep ^[a-zA-Z0-9\-]*[\.][a-zA-Z0-9\-]*[\.] | grep [a-zA-Z0-9\-]*[\.][a-zA-Z0-9\-]*[\.]$ | grep NS | awk {'print $5'} | sort -u) )
        prev_server="null"

        if [ ${#name_servers[*]} -eq 0 ]
        then
                printError "$ERR_NO_NAMESERVERS"
		return
        fi

        for record_label in ${records[@]}
        do
                printDiv "$record_label"
                for server in ${name_servers[@]}
                do
                        record="$(dig @${server} ${record_label} ${1} | grep [[:blank:]]${record_label}[[:blank:]] | grep ^${1}[[:blank:]] | grep -v "^;" | sort)"
                        if [ "${prev_server}" = "null" ]
                        then
                                printServer "$server"
                                printRecord "$record"
                        else
                                compareRecord "$record" "$prev_record" "$server" "$prev_server"
                        fi
                        prev_record=$record
                        prev_server=$server
                done
                prev_server="null"
        done
		
}

function printDiv()
{
        columns_size=$(tput cols)
        label_size=${#1}

        half_columns=$(($columns_size / 2))
        half_label=$(($label_size / 2))

        columns_mod=$(($columns_size % 2))
        label_mod=$(($label_size % 2))

        half1=$(($half_columns - $half_label - $label_mod - 2))
        half2=$(($half_columns - $half_label + $columns_mod - 2))

	printStartColor $DIVIDE_COLOR
        for i in `seq 1 $half1`
        do
                echo -n "$DIVIDE_CHAR"
        done
	echo -n "[ "
	printEndColor
	printInlineColor "$1" $DIVIDE_LABEL_COLOR
	printStartColor $DIVIDE_COLOR
	echo -n " ]"
        for i in `seq 1 $half2`
        do
                echo -n "$DIVIDE_CHAR"
        done
        printEndColor
        echo
}

function printRecord()
{
	if [ -z "$1" ]
	then
		printError "$ERR_NO_RECORD"
	else
		printColor "$1" $RECORD_COLOR | sed "s/^/  /"
	fi
}

function compareRecord()
{
	if [ "${1^^}" = "${2^^}" ]
	then
		printInlineColor "$3" $NAME_SERVER_COLOR
		printInlineColor "  agrees with  " $GOOD_COLOR
		printInlineColor "$4" $NAME_SERVER_COLOR
		echo
	else
		printInlineColor "$3" $NAME_SERVER_COLOR
                printInlineColor "  disagrees with  " $BAD_COLOR
                printInlineColor "$4" $NAME_SERVER_COLOR
		echo
		printRecord "$1"				
	fi
}

function printServer()
{
	printColor "$1" $NAME_SERVER_COLOR	
}

function printError()
{
	printColor "$1" $ERROR_COLOR
}

function printInlineColor()
{
	if [ "$COLORS_ENABLED" = "true" ]
	then
		echo -en "\e[38;5;${2}m$1\e[0m"
	else
		echo -n "$1"
	fi
}

function printColor()
{	
        if [ "$COLORS_ENABLED" = "true" ]
        then
		echo -e "\e[38;5;${2}m$1\e[0m"
        else
                echo "$1"
        fi
}

function printStartColor()
{
	if [ "$COLORS_ENABLED" = "true" ]
	then
		echo -ne "\e[38;5;${1}m"
	fi
}

function printEndColor()
{	
	if [ "$COLORS_ENABLED" = "true" ]
        then
		echo -ne "\e[0m"
	fi
}

main $@	
