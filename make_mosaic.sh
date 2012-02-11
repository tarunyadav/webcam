#!/bin/bash
# make a montage picture out of a set of daily picture directories

# TODO
# 1) set up control file
# 2) fix daylight saving time
# 3) fix or customize crop

######################################################################
# Default values
######################################################################

START_DATE=20090509
END_DATE=20110626

SOURCE_DIR=/var/tmp/beachcam/www/beachcam
working_dir=`mktemp -d`

SCALE_FRAME='64x16'
CROP_FRAME='2360x590'
OFFSET='+152+413'
DAILY_STRIP_GEOMETRY='+0+0'
CONTROL_FILE=control.txt

declare -a control

######################################################################
# command line inputs
######################################################################

usage()
{
cat <<EOF
usage: $0 options

This script makes a vertical montage of multiple daily montage strips

OPTIONS:
   -e      Set the end date, as YYYYMMDD.  Defaults to ${END_DATE}
   -h      Help (this message)
   -s      Set the start date, as YYYYMMDD.  Defaults to ${START_DATE}

EOF
}

while getopts e:hs: o
do	
    case "$o" in
	e)	END_DATE="$OPTARG";;
	h)	usage
		exit 1;;
	s)	START_DATE="$OPTARG";;

    esac
done

if [ ${END_DATE} -lt ${START_DATE} ]
then
    echo "End date is before start date."
    exit 1
fi

START_DATE_EPOCHAL=`date -d ${START_DATE} +%s`
END_DATE_EPOCHAL=`date -d ${END_DATE} +%s`
START_DATE_IN_DAYS=`expr ${START_DATE_EPOCHAL} / 86400`
END_DATE_IN_DAYS=`expr ${END_DATE_EPOCHAL} / 86400`


######################################################################
# load control file in control array
######################################################################

for line in `cat ${CONTROL_FILE}`
do
    date=`echo $line | cut -d: -f1`
    action=`echo $line | cut -d: -f2`
    control[$date]="$action"
done

######################################################################
# working loop
######################################################################

count=0
i=${START_DATE_IN_DAYS}
while [ $i -le ${END_DATE_IN_DAYS} ]
do

    epoch=`expr $i \* 86400`
    WORKING_DATE=`date -d @${epoch} +%Y%m%d`
    # build the control file
#    echo ${WORKING_DATE}:default
#    i=`expr $i + 1`
#    continue

    # check this day against control
    control_today=${control[${WORKING_DATE}]}
    case $control_today in
        black)
        # use a black strip
        convert -size 3072x16 -fill black $working_dir/${year_dir}-${month_dir}-${day_dir}.jpg
        continue
        ;;
        default)
            # no action
            working_crop=${CROP_FRAME}${OFFSET}
            ;;
        *)
            # assume a new offset is provided
            working_crop=$control_today
            ;;
    esac

    YEAR=`date -d @${epoch} +%Y`
    MONTH=`date -d @${epoch} +%m`
    DAY=`date -d @${epoch} +%d`
    
    pushd ${SOURCE_DIR}/${YEAR}/${MONTH}/${DAY}
    daily_dir=${working_dir}/daily
    mkdir ${daily_dir}
    
    for file in `ls`
    do
        convert -crop $working_crop  $file ${daily_dir}/$file
        mogrify -scale ${SCALE_FRAME}  ${daily_dir}/$file
    done
    
    # make the strip for the day

    montage ${daily_dir}/*jpg -tile `ls ${daily_dir} | wc -l`x1 -geometry $DAILY_STRIP_GEOMETRY $working_dir/${year_dir}-${month_dir}-${day_dir}.jpg
    
    rm -rf ${daily_dir}
    popd

    i=`expr $i + 1`

done

# make the master montage

#tile_count=`ls ${working_dir}/*jpg | wc -l`
#montage ${working_dir}/*jpg -tile 1x{$tile_count} -geometry +0+0 output.jpg
