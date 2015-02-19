#!/bin/bash

# Matthew Walster

# USAGE: ./cidr-summarize.sh 1.2.3.4/32 4.3.2.1/8
# Spits out a single prefix if they can be summarised
# Spits out two prefixes if they can't be summarised

left=$1
right=$2

if [[ -z $1 || -z $2 || -n $3 ]]
then
	echo "ERROR: Enter two CIDR prefixes"
	exit 1
fi

cidr="^([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\."
cidr+="([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\."
cidr+="([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\."
cidr+="([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])"
cidr+="/([0-9]|[0-2][0-9]|3[0-2])$"

for addr in $left $right
do
	if [[ ! $addr =~ $cidr ]]
	then
		echo "ERROR: Those weren't CIDR prefixes..."
		exit 1
	fi
done

int2dq()
{
	local IFS=. num quad ip e
	num=$1
	for e in 3 2 1
	do
		(( quad = 256 ** e))
		(( ip[3-e] = num / quad ))
		(( num = num % quad ))
	done
	ip[3]=$num
	echo "${ip[*]}"
}

dq2int ()
{
	local IFS=. ip num e
	ip=($1)
	for e in 3 2 1
	do
		(( num += ip[3-e] * 256 ** e ))
	done
	(( num += ip[3] ))
	echo "$num"
}

maskwild()
{
	echo $(( 2 ** ( 32 - $1 ) - 1 ))
}

masksize()
{
	echo $(( ( 2 ** 32 ) - ( 2 ** ( 32 - $1 ) ) ))
}

leftip=${left%/*}
leftmask=${left#*/}
leftint=$(dq2int $leftip)
leftmaskwild=$(maskwild $leftmask)
leftmasksize=$(masksize $leftmask)
leftnetaddrint=$(( $leftint & $leftmasksize ))
leftnetaddrdq=$(int2dq $leftnetaddrint)

rightip=${right%/*}
rightmask=${right#*/}
rightint=$(dq2int $rightip)
rightmaskwild=$(maskwild $rightmask)
rightmasksize=$(masksize $rightmask)
rightnetaddrint=$(( $rightint & $rightmasksize ))
rightnetaddrdq=$(int2dq $rightnetaddrint)

if [[ $leftnetaddrint == $rightnetaddrint ]]
then
	if [[ $leftmask < $rightmask ]]
	then
		echo $leftnetaddrdq/$leftmask
	else
		echo $rightnetaddrdq/$rightmask
	fi
	exit 0
fi

if [[ $(( $leftnetaddrint + $leftmaskwild - 1 )) < $rightnetaddrint ]]
then
	echo $leftnetaddrdq/$leftmask
	echo $rightnetaddrdq/$rightmask
elif [[ $(( $rightnetaddrint + $rightmaskwild - 1 )) < $leftnetaddrint ]]
then
	echo $leftnetaddrdq/$leftmask
	echo $rightnetaddrdq/$rightmask
elif [[ $leftmask < $rightmask ]]
then
	echo $leftnetaddrdq/$leftmask
elif [[ $rightmask < $leftmask ]]
then
	echo $rightnetaddrdq/$rightmask
fi


