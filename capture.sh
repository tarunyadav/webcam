#!/bin/bash
# capture a photo from the webcam

WEB_ABSOLUTE_DIR=/var/www
CAM_RELATIVE_DIR=webcam
CURRENT_RELATIVE_PATH=/${CAM_RELATIVE_DIR}/current.jpg
CURRENT_ABSOLUTE_PATH=${WEB_ABSOLUTE_DIR}${CURRENT_RELATIVE_PATH}
TEMP_DIR=`mktemp -d`
CAPTURE_PATH=
GPHOTO2_PATH=
INCOMING_PATH=
CURRENT_DIMENSION=
THUMB_DIMENSION=
JPEGPIXI_PATH=
JPEGPIXI_ARGUMENT=
FLIP=
BACKUP_MESSAGE=

######################################################################
# command line inputs
######################################################################

usage()
{
cat <<EOF
usage: $0 options

This script captures an image, either from certain models of Canon camera using 
either Capture or gphoto2, or from an incoming dump directory, and then rebuilds 
a web directory index.  You must specify exactly one of -c, -g, or -i.

OPTIONS:
   -b      If capture fails and backup message is not null, message will
           be shown instead of last available picture.
           Defaults to ${BACKUP_MESSAGE}
   -c      Path to Capture (http://sourceforge.net/projects/capture/).  
           Defaults to null.
   -d      Absolute path to the webserver root directory.  
           Defaults to ${WEB_ABSOLUTE_DIR}
   -f      Rotate the picture this many degrees clockwise.
   -g      Path to gphoto2. Defaults to null.
   -h      This help
   -i      Path to directory of incoming photos of filename format YYYYMMDDHHMMSSxx.jpg. 
           Will erase contents of this directory.  Defaults to null.   
   -j      Path to jpegpixi image processer.  Defaults to null.   
   -p      Argument for jpexpixi processor.  Defaults to null.   
   -r      Relative path for webcam directory.  Defaults to ${CAM_RELATIVE_DIR}
   -t      Thumbnail dimension.  Defaults to ${THUMB_DIMENSION}.  
           If not null, creates thumbnail and index within daily directory
   -u      Current thumbnail dimension.  Defaults to ${CURRENT_DIMENSION}.  
           If not null, creates a thumbnail at ${CURRENT_ABSOLUTE_PATH},
           which should appear on the home page.
   -v      Debug mode
   -w      Number of seconds to wait after taking a picture.  Defaults to null.  
           If set, will try to take photos, spaced by this interval, for one minute.
           Otherwise, will take one photo and exit.
EOF
}

while getopts b:c:d:f:g:hi:j:p:r:t:u:vw: o
do	
    case "$o" in
	b)      BACKUP_MESSAGE="$OPTARG";;
	c)      CAPTURE_PATH="$OPTARG";;
	d)      WEB_ABSOLUTE_DIR="$OPTARG";;
	f)      FLIP="$OPTARG";;
	g)      GPHOTO2_PATH="$OPTARG";;
	h)	usage
		exit 1;;
	i)      INCOMING_PATH="$OPTARG";;
	j)      JPEGPIXI_PATH="$OPTARG";;
	p)      JPEGPIXI_ARGUMENT="$OPTARG";;
	r)      CAM_RELATIVE_DIR="$OPTARG";;
	t)      THUMB_DIMENSION="$OPTARG";;
        u)      CURRENT_DIMENSION="$OPTARG";;
        v)      VERBOSE=1;;
	w)      WAIT="$OPTARG";;
    esac
done

if [ "${VERBOSE}" == "1" ] 
    then
    set -x
fi

mode_count=0
if [ -e "${CAPTURE_PATH}" ]
then
    mode_count=`expr $mode_count + 1`
fi

if [ -e "${GPHOTO2_PATH}" ]
then
    mode_count=`expr $mode_count + 1`
fi

if [ -e "${INCOMING_PATH}" ]
then
    mode_count=`expr $mode_count + 1`
fi

if [ "${mode_count}" -ne "1" ]
    then
    echo "Must specify exactly one of capture, gphoto2, or incoming"
    exit 1
fi

PRETTY_DAY=`date "+%A, %d %B %Y"`
PRETTY_TIME=`date "+%l:%M %p %Z"`
YEAR_STRING=`date +%Y`
MONTH_STRING=`date +%m`
DAY_STRING=`date +%d`
HOUR_STRING=`date +%H`
MINUTE_STRING=`date +%M`
PIC_RELATIVE_DIR=/${CAM_RELATIVE_DIR}/${YEAR_STRING}/${MONTH_STRING}/${DAY_STRING}
PIC_ABSOLUTE_DIR=${WEB_ABSOLUTE_DIR}${PIC_RELATIVE_DIR}
INDEX_MASTER_ABSOLUTE_DIR=${WEB_ABSOLUTE_DIR}/index_day.php
INDEX_ABSOLUTE_DIR=${PIC_ABSOLUTE_DIR}/index.php
CURRENT_RELATIVE_PATH=/${CAM_RELATIVE_DIR}/current.jpg
CURRENT_ABSOLUTE_PATH=${WEB_ABSOLUTE_DIR}${CURRENT_RELATIVE_PATH}
CURRENT_HTML_PATH=${WEB_ABSOLUTE_DIR}/${CAM_RELATIVE_DIR}/current.html
mkdir -p ${PIC_ABSOLUTE_DIR}
if [ ! -e INDEX_ABSOLUTE_DIR ]
then
    ln -s $INDEX_MASTER_ABSOLUTE_DIR $INDEX_ABSOLUTE_DIR
fi
TEMP_FILE_NAME=temp.jpg
TEMP_FILE_PATH=${TEMP_DIR}/${TEMP_FILE_NAME}

######################################################################
# stay in the loop for the current minute
######################################################################
while [ "`date +%H%M`" -le "${HOUR_STRING}${MINUTE_STRING}" ]
do
    BASE=`date +%H:%M:%S`
    FILE_NAME=${BASE}.jpg
    THUMB_NAME=${BASE}_thumb.jpg
    THUMB_HTML_NAME=${BASE}.html
    PIC_ABSOLUTE_PATH=${PIC_ABSOLUTE_DIR}/${FILE_NAME}
    PIC_RELATIVE_PATH=${PIC_RELATIVE_DIR}/${FILE_NAME}
    THUMB_ABSOLUTE_PATH=${PIC_ABSOLUTE_DIR}/${THUMB_NAME}
    THUMB_RELATIVE_PATH=${PIC_RELATIVE_DIR}/${THUMB_NAME}
    THUMB_HTML_PATH=${PIC_ABSOLUTE_DIR}/${THUMB_HTML_NAME}

    ######################################################################
    # Capture via one of the methods
    ######################################################################

    if [ -e "${CAPTURE_PATH}" ]
    then
        # the kill deals with any lingering capture from previous runs
        killall -9 capture

        pushd ${TEMP_DIR}
        # The premise of capture is that you can start once, then capture many times 
        # without closing and re-opening the lens, but that didn't seem to work, so
        # we go through the full cycle each time
        ${CAPTURE_PATH} 'start'
        ${CAPTURE_PATH} "capture ${TEMP_FILE_NAME}"
        ${CAPTURE_PATH} 'quit'
        popd
    fi

    if [ -e "${GHOTO2_PATH}" ]
    then
        # gphoto2 does not seem to like it if the filename is pathed, so run it from the working directory
        pushd ${TEMP_DIR}
        capture_result=`gphoto2 --filename ${TEMP_FILE_NAME} --capture-image-and-download`
        popd
    fi

    if [ -e "${INCOMING_PATH}" ]
    then
        pushd ${INCOMING_PATH}
        # grab most recent file for this minute
        incoming_array=(`ls -t *jpg`)
        newest_file=${incoming_array[0]}

	if [ -z "${newest_file}" ]
	then
	    break
	fi

        year=${newest_file:0:4}
        month=${newest_file:4:2}
        day=${newest_file:6:2}
        hour=${newest_file:8:2}

        if [ "${year}${month}${day}${hour}" -eq "${YEAR_STRING}${MONTH_STRING}${DAY_STRING}${HOUR_STRING}" ]
        then
    	    cp -f $newest_file ${TEMP_FILE_PATH}
    	    rm ${INCOMING_PATH}/*jpg
        fi
	popd
    fi

    ######################################################################
    # Image post-processing
    ######################################################################

    if [ ! -e "${TEMP_FILE_PATH}" ] 
    then
	if [ -n "${BACKUP_MESSAGE}" ]
	then
            cat > $CURRENT_HTML_PATH <<EOF 
${BACKUP_MESSAGE}
<p>${PRETTY_TIME}, ${PRETTY_DAY}</p>
EOF
	fi
        break
    fi

    if [ -n "${FLIP}" ]
    then
	mogrify -rotate 180 ${TEMP_FILE_PATH}
    fi

    if [ -n "${JPEGPIXI_PATH}" ] && [ -n "${JPEGPIXI_ARGUMENT}" ]
    then
	jpegpixi $TEMP_FILE_PATH $TEMP_FILE_PATH ${JPEGPIXI_ARGUMENT}
    fi

    cp $TEMP_FILE_PATH $PIC_ABSOLUTE_PATH

    ######################################################################
    # make thumbnail image and html snippet
    ######################################################################

    if [ ! -e "${PIC_ABSOLUTE_PATH}" ]
    then
	break
    fi

    dimension=`identify -verbose ${PIC_ABSOLUTE_PATH} | grep Geometry`
    dimension=${dimension#  Geometry: }
    dimension=${dimension%+0+0}

    if [ -n "${CURRENT_DIMENSION}" ]
    then
	if [ "${dimension}" != "${CURRENT_DIMENSION}" ]
	then
            convert -geometry ${CURRENT_DIMENSION} ${PIC_ABSOLUTE_PATH} ${CURRENT_ABSOLUTE_PATH}
            cat > ${CURRENT_HTML_PATH} <<EOF 
    <a href="${PIC_RELATIVE_PATH}"><img src="${CURRENT_RELATIVE_PATH}" alt="${CAM_RELATIVE_DIR}"/></a>
EOF
	else
            cat > ${CURRENT_HTML_PATH} <<EOF 
    <img src="${PIC_RELATIVE_PATH}" alt="${CAM_RELATIVE_DIR}"/>
EOF
	fi
	cat >> ${CURRENT_HTML_PATH} <<EOF
<p>${PRETTY_TIME}, <a href="${PIC_RELATIVE_DIR}">${PRETTY_DAY}</a></p>
EOF
    fi

    if [ -n "${THUMB_DIMENSION}" ] 
    then
	if [ "${dimension}" != "${THUMB_DIMENSION}" ]
	then
            convert -geometry ${THUMB_DIMENSION} ${PIC_ABSOLUTE_PATH} ${THUMB_ABSOLUTE_PATH}
            cat > ${THUMB_HTML_PATH} <<EOF 
    <a href="${PIC_ABSOLUTE_PATH}"><img src="${THUMB_RELATIVE_PATH}" alt="Thumbnail for ${PRETTY_TIME}, ${PRETTY_DAY}"/></a><br/>
EOF
	else
            cat > ${THUMB_HTML_PATH} <<EOF 
    <img src="${PIC_ABSOLUTE_PATH}" alt="Thumbnail for ${PRETTY_TIME}, ${PRETTY_DAY}"/><br/>
EOF
	fi
    fi
    
    if [ -z "${WAIT}" ]
    then
	break
    else 
	sleep ${WAIT}
    fi

done

######################################################################
# clean up
######################################################################

if [ "$VERBOSE" == "0" ] 
    then
    rm -rf $TEMP_DIR
fi
