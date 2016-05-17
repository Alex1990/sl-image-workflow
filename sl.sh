#!/bin/bash

VERSION="0.2.0"

display_version() {
  echo $VERSION
}

display_help() {
  cat <<-EOF

  Usage: sl [options] [path]

  Options:

    -c, --check     Check the dimensions, ratio, filetype etc
    -n, --normalize Normalize the filename, filetype, filesize etc
    -r, --recevie   Unzip the file to destination, make a same name directory
    -s, --send      Zip the folder
        --sum       Count the handled pictures
    -t, --transfer  Transfer the pictures in SL_TMP_HUB to a new directory
    -h, --help      Display help information
    -v, --version   Output current version of sl

EOF
}

SL_WORK_DIR="$HOME/shenlan/"
SL_TMP_HUB="${SL_WORK_DIR}tmp_hub/"
SL_PATCH_META="${SL_TMP_HUB}patch_meta"
SL_MIN_SIZE=500
SL_MAX_SIZE=1000

# Read config file

if [[ -r /etc/sl_image_workflow.cfg ]]; then
  . /etc/sl_image_workflow.cfg
fi

if [[ -r ~/.slrc ]]; then
  . ~/.slrc
fi

# Normalize the images
# - Convert gif, png to jpg
# - Convert to a square
# - Convert to the range of SL_MIN_SIZE and SL_MAX_SIZE
normalize() {
  local target_dir="$1"
  local mime;
  local filename;
  local width
  local height
  declare -a dimension

  if [[ -z "$target_dir" || ! -d "$target_dir" ]]; then
    if [[ -d "$SL_TMP_HUB" ]]; then
      target_dir="$SL_TMP_HUB"
    else
      echo "${SL_TMP_HUB} isn't exists."
    fi
  fi

  if [[ "$target_dir" != */ ]]; then
    target_dir="${target_dir}/"
  fi

  if [[ -d "$target_dir" ]]; then
    find -d "${target_dir}" -type f -print | while read f; do
      mime=$(file --brief --mime-type "$f" | tr -d "\n")

      if [[ "$mime" = "image/gif" || "$mime" = "image/png" || "$mime" = "image/jpeg" ]]; then

        filename="${f%.*}"
        # Convert gif or png to jpg
        if [[ "$mime" = "image/gif" || "$mime" = "image/png" ]]; then
          convert "$f" "${filename}.jpg"
          rm -f "$f"
        fi

        if [[ 0 -eq 0 ]]; then
          IFS=" " read -a dimension <<< $(identify -format "%w %h" "$f")
          width=$((dimension[0]))
          height=$((dimension[1]))

          # Convert to a square
          if [[ "$width" -ne "$height" ]]; then
            if [[ "$width" -lt "$height" ]]; then
              width=$((height))
            else
              height=$((width))
            fi
            # Todo: Change tmp filename and location
            convert -size "${width}x${height}" xc:white /tmp/_sl_tmp.jpg
            convert -gravity center /tmp/_sl_tmp.jpg "$f" -composite "$f"
            rm -f /tmp/_sl_tmp.jpg
            echo "$f"
          fi

          # Scale
          if [[ "$width" -lt "$SL_MIN_SIZE" ]]; then
            convert "$f" -resize "${SL_MIN_SIZE}x${SL_MIN_SIZE}" "$f"
          fi

          if [[ "$width" -gt "$SL_MAX_SIZE" ]]; then
            convert "$f" -resize "${SL_MAX_SIZE}x${SL_MAX_SIZE}" "$f"
          fi
        fi
      fi
    done
  fi

  exit 0
}

transfer() {
  local old_works_dir

  if [[ -f "$SL_PATCH_META" ]]; then
    old_works_dir=$(head -1 "$SL_PATCH_META" | tr -d "\n")
    if [[ -n "$old_works_dir" ]]; then
      if [[ ! -d "$old_works_dir" ]]; then
        mkdir "$old_works_dir" \
          && mv ${SL_TMP_HUB}*.jpg "$old_works_dir" \
          && echo "" > "$SL_PATCH_META"
      else
        mv ${SL_TMP_HUB}*.jpg "$old_works_dir" \
          && echo "" > "$SL_PATCH_META"
      fi
    fi
  fi
  return $?
}

init_tmp_hub() {
  local new_works_dir="$1"

  transfer && echo "$new_works_dir" > "$SL_PATCH_META"
}

receive() {
  local zip_pathname="$1"
  local zip_basename=$(basename "$zip_pathname" ".zip")
  local works_dir="${SL_WORK_DIR}${zip_basename}.new"

  if [[ -f "$zip_pathname" && "$zip_pathname" == *.zip ]]; then
    unzip -d "$SL_WORK_DIR" "$zip_pathname" -x "__MACOSX/*" \
      && init_tmp_hub "$works_dir"
  else
    echo "${zip_pathname}: isn't exist or not a zip file"
  fi
  
  exit
}

send() {
  local filename="$1"
  local zipfilename="${filename}.zip"

  if [[ -d "$filename" ]]; then
    zip -r "${SL_WORK_DIR}$zipfilename" "$filename"
  else
    echo "file must be exist and a folder"
  fi
}

check() {
  local target_dir="$1"
  local width
  local height
  local failed_msg
  declare -a dimension
  declare -a pics
  local ok_count=0

  if [[ -z "$target_dir" || ! -d "$target_dir" ]]; then
    if [[ -d "$SL_TMP_HUB" ]]; then
      target_dir="$SL_TMP_HUB"
    else
      echo "${SL_TMP_HUB} isn't exists."
    fi
  fi

  if [[ "$target_dir" != */ ]]; then
    target_dir="${target_dir}/"
  fi

  # ls -1 ${target_dir}*.jpg 2> /dev/null && IFS="\n" read -a pics <<< $(ls -1 ${target_dir}*.jpg)

  if [[ -d "$target_dir" ]]; then
    for f in ${target_dir}*.jpg; do
      IFS=" " read -a dimension <<< $(identify -format "%w %h" "$f")
      width=$((dimension[0]))
      height=$((dimension[1]))

      if [[ "$width" -ne "$height" ]]; then
        failed_msg="${failed_msg}$f: is not a square\n"
      fi

      if [[ "$width" -lt "$SL_MIN_SIZE" || "$height" -lt "$SL_MIN_SIZE" ]]; then
        failed_msg="${failed_msg}$f: is less than ${SL_MIN_SIZE}x${SL_MIN_SIZE}\n"
      fi

      if [[ "$width" -gt "$SL_MAX_SIZE" || "$height" -gt "$SL_MAX_SIZE" ]]; then
        failed_msg="${failed_msg}$f: is greater than ${SL_MAX_SIZE}x${SL_MAX_SIZE}\n"
      fi

      let "ok_count += 1 "
    done
  fi

  if [[ -z "$failed_msg" ]]; then
    echo "$ok_count OK."
    return $?
  else
    printf "%b" "$failed_msg"
    return 1
  fi
}

count_total() {
  local start_date="$1"
  local end_date="$2"
  local filename
  local sum

  if [[ -z "$start_date" ]]; then
    start_date="20160101"
  fi

  if [[ -z "$end_date" ]]; then
    end_date="20251231"
  fi

  sum=$(find "$SL_WORK_DIR" -depth 1 -type d -name "*.new" -print | while read f; do
    filename=$(basename "$f")
    local n=$(echo "$filename" | sed 's/[^0-9].*//g')
    if [[ "$n" -ge "$start_date" && "$n" -lt "$end_date" ]]; then
      find "$f" -depth 1 -name *.jpg | wc -l | tr -d " "
    fi
  done | paste -sd+ - | bc)

  if [[ -z "$sum" ]]; then
    sum=0
  fi

  echo "$sum"
}

if [[ "$#" -eq 0 ]]; then
  display_help
else
  while [[ "$#" -ne 0 ]]; do
    case "$1" in
      -v|--version) display_version; exit ;;
      -h|--help) display_help; exit ;;
      -c|--check) check "$2"; exit ;;
      -n|--normalize) normalize "$2"; exit ;;
      -r|--receive) receive "$2"; exit ;;
      -s|--send) send "$2"; exit ;;
         --sum) shift; count_total "$@"; exit ;;
      -t|--transfer) check && transfer; exit ;;
      *) display_help; exit;;
    esac
    shift
  done
fi

exit 0

