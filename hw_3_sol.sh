
# create an array of md5sums
declare -A md5sum_duplicate_count_array;
declare -A md5sum_to_filenames_array;
declare -A group_sizes_to_md5sums_array;

# sweep through the list of files to count and organize files by thier md5sums 
find_and_count_duplicates () {
	# initialize an indexed array of files to loop over using command substitution
	file_list=( $(find "`pwd`" -type f) )
	echo "FINDING AND COUNTING DUPLICATES." 
	for temp_file_path in ${file_list[@]}; do
		# initialize a temporary array with the md5sum hash and the filepath 
		# (because they are space separated)
		temp_md5sum_output=(`md5sum $temp_file_path`)
		# extract the output from each of the temporary array positions
		temp_md5=${temp_md5sum_output[0]}
		temp_file=${temp_md5sum_output[1]} # not needed; we already have this value 
	
		# get the current number of times the md5sum has been seen
		current_temp_md5sum_count=${md5sum_duplicate_count_array["${temp_md5sum_output[0]}"]}
		
		# arithmetically evaluate the increment expression and store it
		let md5sum_duplicate_count_array["${temp_md5sum_output[0]}"]=$((current_temp_md5sum_count+1))

		# add to comma separated list/string of md5sums to files. if the count is 1, don't include a comma
		if [ ${md5sum_duplicate_count_array[${temp_md5sum_output[0]}]} -eq 1 ]
		then
			md5sum_to_filenames_array["$temp_md5"]="${temp_file}"
		else
			md5sum_to_filenames_array["$temp_md5"]+=', '"${temp_file}"
		fi
	done;
	echo "DUPLICATES FOUND AND COUNTED." 

}

find_and_count_duplicates

# organize md5sums into group sizes so the same group sizes can be printed out together
assign_md5sums_to_group_sizes () {
	# loop over the count array to store a (kind of) reverse of its content
	for temp_md5sum in ${!md5sum_duplicate_count_array[@]}
	do 
			
		# retrieve the number of times the md5sum has appeared, 
		# i.e. the group size of the md5sum
		let duplicate_count=${md5sum_duplicate_count_array["$temp_md5sum"]}

		# get the number of characters in the group size array 
		let size_in_characters=${#group_sizes_to_md5sums_array["$duplicate_count"]}
		# use the length above to determine if the temp md5sum is the first being added to the list
		if [ "$size_in_characters" -eq 0 ]
		then
			group_sizes_to_md5sums_array[$duplicate_count]=$temp_md5sum
		else
			group_sizes_to_md5sums_array[$duplicate_count]+=" "$temp_md5sum
		fi
	done
}

assign_md5sums_to_group_sizes


colorize_path(){
	# create an array with the comma separated list
	comma_separated_list=($@)
	# iterate over the 
	for comma_separated_file in ${comma_separated_list[@]}; do
		# remove everything after the last forward slash
		path_string=${comma_separated_file%/*}
		# remove everything before the last forward slash
		filename_string=${comma_separated_file##*/}
		# store last comma if it's there
		comma_string=""
		let filename_length=${#filename_string}
		# also remove the last comma
		filename_string=${filename_string%,}
		if [ ${#filename_string} -lt $filename_length ];
		then
			comma_string=","
		fi
		echo -en "\033[0;36m"
		echo -n $path_string
		echo -en "\033[0;35m"
		echo -n /
		echo -en "\033[0;37m"
		echo -n "$filename_string"
		echo -en "\033[0;33m"
		echo -n "$comma_string "
		echo -en "\033[0;37m"
	done
}


# using the md5sums organized by size
print_group_sizes (){
	echo "PRINTING MD5SUM GROUP SIZES IN ORDER"
	# loop through group sizes sorted numerically 
	# associative array stores values in arbitrary order
	# example: declare -A wrong_order_array=([111]=1 [22]=2 [3]=3); echo ${!wrong_order_array[@]}
	for group_size in `echo ${!group_sizes_to_md5sums_array[@]} | tr ' ' '\n' | sort -n`
	do
		echo
		# print the group size
		echo -en "\033[0;31m"
		echo "Groups of size "$group_size"..."
		echo -en "\033[0;32m"
		echo "MD5S in group:" ${group_sizes_to_md5sums_array["$group_size"]}
		echo -en "\033[0;37m"

		# setup for the while loop
		temp_group_md5sum_list=${group_sizes_to_md5sums_array["$group_size"]}
		remaining_string=$temp_group_md5sum_list
		# split the list of file string until there's nothing left
		while [ ${#remaining_string} -gt 0 ] ; do
			# use parameter expansion features to split up the string incrementally
			temp_md5sum=${remaining_string%% *} 
			remaining_string=${remaining_string#* } 
			echo -en "\033[0;34m"
			echo "Current hash: "$temp_md5sum
			echo -en "\033[0;37m"
			# colorize the path
			colorize_path ${md5sum_to_filenames_array["$temp_md5sum"]}
			if [ "$temp_md5sum" = "$remaining_string" ] ;
			then
				break;
			fi
			echo
		done
		echo
	done
}
print_group_sizes

