# sl-image-workflow
A workflow shell script to handle the images

## Installation

```shell
curl -s https://raw.githubusercontent.com/Alex1990/sl-image-workflow/master/install.sh?token=AC_wL81HjRhffXGtwzu2fcVRAxYPRHVoks5XTZH1wA%3D%3D | bash
```

## Usage

```text
chaoalex:shenlan$ ./sl.sh -help

  Usage: sl [options] [path]

  Options:

    -c, --check     Check the dimensions, ratio, filetype etc
    -n, --normalize Normalize the filename
    -r, --recevie   Unzip the file to destination, make a same name directory
    -s, --send      Zip the folder
        --sum       Count the handled pictures
    -t, --transfer  Transfer the pictures in SL_TMP_HUB to a new directory
    -h, --help      Display help information
    -v, --version   Output current version of sl
```

## License

MIT
