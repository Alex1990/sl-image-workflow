# sl-image-workflow
A workflow shell script to handle the images

## Installation

```shell
curl https://raw.githubusercontent.com/Alex1990/sl-image-workflow/master/sl.sh?token=AC_wL4TBftr4Vyh8dThpU4TcGW4VnHvcks5XrdoFwA%3D%3D -o /usr/local/bin/sl && chmod +x /usr/local/bin/sl
```

## Usage

```text
  Usage: sl [options] [path]

  Options:

    -c, --check     Check the dimensions, ratio, filetype etc
    -n, --normalize Normalize the filename, filetype, filesize etc
    -r, --recevie   Unzip the file to destination, make a same name directory
    -s, --send      Zip the folder
        --sum       Count the handled pictures
    -t, --transfer  Transfer the pictures in SL_TMP_DEST to a new directory
    -h, --help      Display help information
    -v, --version   Output current version of sl
```

## License

MIT
