#!/usr/bin/bash
# This file is autogenerated, do not edit

if [ $# == 0 ]; then
    echo "ERROR: $0 expects one argument (result_dir)"
    exit 1
fi

result_dir="$1"

# need to stitch the time sequence
module load CDO

# copy the netcdf files to a common directory while
# renaming the files along the way
for idir in $result_dir/[0-9][0-9][0-9][0-9][0-9]/nc; do
    if [ -f $idir ]; then
        # not a directory
        continue
    fi
    index=$(basename $idir)
    echo "*** index=$index"
    for sdir in $idir/*; do
        if [ -f $sdir ]; then
            # not a directory
            continue
        fi
        sbase=$(basename $sdir)
        echo "*** sdir=$sdir"
        mkdir -p $sdir
        for nfile in $sdir/*.nc; do
            nf=$(basename $nfile)
            echo "*** nfile=$nfile nf=$nf copying $nfile to $result_dir/tmp/nc/$sbase/$nf_$index"
            cp $nfile $result_dir/tmp/nc/$sbase/$nf_$index
        done
    done
done

# each directory under nc/ maps to a statistic operation/diagnostic
for nc_dir in $(ls -d $result_dir/tmp/nc/*); do

    if [ -f $nc_dir ]; then 
        # not a directory
        echo "Warning: $nc_dir is not a directory, skipping..."
        continue
    fi

    # collect all the (unique) models and stashcodes
    model_list=""
    stashcode_list=""
    for filename in $(ls $nc_dir/*.nc_[0-9][0-9][0-9][0-9][0-9]); do

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
            file_list=$(ls $nc_dir/${model}_*_${stashcode}_*.nc_[0-9][0-9][0-9][0-9][0-9])

            # name of the time merged file. Take the first file and remove the
            # indexing
            out=$(echo $file_list | awk '{print $1;}' | sed 's/\.nc\_[0-9][0-9][0-9][0-9][0-9]/.nc/')
            # build the output file name and full path
            out_dir=$(dirname $out)
            out_base=$(basename $out)
            # replace land_global by global, seems to be required
            
            # eg awmean, awsum, ...
            statop=$(basename $out_dir)

            # the output file has to be one level above
            mkdir -p $result_dir/nc/$statop
            outname="$result_dir/nc/$statop/$out_base"

            # merge time command
            cdo mergetime $file_list $outname
            
        done
    done

done
