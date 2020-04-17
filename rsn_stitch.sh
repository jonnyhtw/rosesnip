#!/usr/bin/bash
# This file is autogenerated, do not edit

if [ $# == 0 ]; then
    echo "ERROR: $0 expects one argument (result_dir)"
    exit 1
fi

result_dir="$1"

# need to stitch the time sequence
module load CDO

# each directory under nc/ maps to a statistic operation/diagnostic
for statop in $(ls -d $result_dir/nc/*); do

    if [ -f $statop ]; then 
        # not a directory
        echo "Warning: $statop is not a directory, skipping..."
        continue
    fi

    res_dir="$statop"

    # collect all the (unique) models and stashcodes
    model_list=""
    stashcode_list=""
    for filename in $(ls $res_dir/*.nc); do

        bn=$(basename $filename)

        # get the model and stashcode from the file name
        model=$(echo $bn | awk -F_ '{print $1;}')
        stashcode=$(echo $bn | awk -F_ '{print $3;}')

        # append to list
        model_list="$model_list $model"
        stashcode_list="$stashcode_list $stashcode"
    done

    # sort and remove duplicates
    model_list=$(echo $model_list | tr ' ' '\n' | sort -u | tr '\n' ' ') 
    stashcode_list=$(echo $stashcode_list | tr ' ' '\n' | sort -u | tr '\n' ' ')

    # combine time steps
    for model in $model_list; do
        for stashcode in $stashcode_list; do

            # get all the files for this model and stashcode
            file_list=$(ls $res_dir/${model}_*_${stashcode}_*_[0-9]*.nc)

            # name of the time merged file. Take the first file and remove the
            # indexing
            out=$(echo $file_list | awk '{print $1;}' | sed 's/\_[0-9]*\.nc/.nc/')
            # build the output file name and full path
	    out_dir=$(dirname $out)
	    out_base=$(basename $out)
	    # replace land_global by global, seems to be required
	    out_base=$(echo $out_base | sed 's/land_global/global/')
            # the output file has to be one level above
	    outname="$out_dir/../$out_base"

            # merge time command
            cdo mergetime $file_list $outname
            
        done
    done

done
