(
['','imread','@brief Loads an image from a file.

@anchor imread

The function imread loads an image from the specified file and returns it. If the image cannot be
read (because of missing file, improper permissions, unsupported or invalid format), the function
returns an empty matrix ( Mat::data==NULL ).

Currently, the following file formats are supported:

-   Windows bitmaps - \\*.bmp, \\*.dib (always supported)
-   JPEG files - \\*.jpeg, \\*.jpg, \\*.jpe (see the *Note* section)
-   JPEG 2000 files - \\*.jp2 (see the *Note* section)
-   Portable Network Graphics - \\*.png (see the *Note* section)
-   WebP - \\*.webp (see the *Note* section)
-   Portable image format - \\*.pbm, \\*.pgm, \\*.ppm \\*.pxm, \\*.pnm (always supported)
-   PFM files - \\*.pfm (see the *Note* section)
-   Sun rasters - \\*.sr, \\*.ras (always supported)
-   TIFF files - \\*.tiff, \\*.tif (see the *Note* section)
-   OpenEXR Image files - \\*.exr (see the *Note* section)
-   Radiance HDR - \\*.hdr, \\*.pic (always supported)
-   Raster and Vector geospatial data supported by GDAL (see the *Note* section)

@note
-   The function determines the type of an image by the content, not by the file extension.
-   In the case of color images, the decoded images will have the channels stored in **B G R** order.
-   When using IMREAD_GRAYSCALE, the codec\'s internal grayscale conversion will be used, if available.
    Results may differ to the output of cvtColor()
-   On Microsoft Windows\\* OS and MacOSX\\*, the codecs shipped with an OpenCV image (libjpeg,
    libpng, libtiff, and libjasper) are used by default. So, OpenCV can always read JPEGs, PNGs,
    and TIFFs. On MacOSX, there is also an option to use native MacOSX image readers. But beware
    that currently these native image loaders give images with different pixel values because of
    the color management embedded into MacOSX.
-   On Linux\\*, BSD flavors and other Unix-like open-source operating systems, OpenCV looks for
    codecs supplied with an OS image. Install the relevant packages (do not forget the development
    files, for example, "libjpeg-dev", in Debian\\* and Ubuntu\\*) to get the codec support or turn
    on the OPENCV_BUILD_3RDPARTY_LIBS flag in CMake.
-   In the case you set *WITH_GDAL* flag to true in CMake and @ref IMREAD_LOAD_GDAL to load the image,
    then the [GDAL](http://www.gdal.org) driver will be used in order to decode the image, supporting
    the following formats: [Raster](http://www.gdal.org/formats_list.html),
    [Vector](http://www.gdal.org/ogr_formats.html).
-   If EXIF information is embedded in the image file, the EXIF orientation will be taken into account
    and thus the image will be rotated accordingly except if the flags @ref IMREAD_IGNORE_ORIENTATION
    or @ref IMREAD_UNCHANGED are passed.
-   Use the IMREAD_UNCHANGED flag to keep the floating point values from PFM image.
-   By default number of pixels must be less than 2^30. Limit can be set using system
    variable OPENCV_IO_MAX_IMAGE_PIXELS

@param filename Name of file to be loaded.
@param flags Flag that can take values of cv::ImreadModes',0,'Mat',['String','filename','',['/C','/Ref']],['int','flags','IMREAD_COLOR',[]]],
);
