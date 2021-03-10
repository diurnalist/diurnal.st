---
title: Compressing PDFs on Mac OS X with custom filters
layout: post
---

I learned recently that not only is it possible to add custom Quartz filters to Mac OS X, it's very easy. [Quartz][1] is a 2D graphics library that sits behind the scenes on macOS. I'm not sure how much it's used for these days, but at some point a nice developer [made it possible to create simple Quartz filters via the ColorSync Utility app][2]. The app has some pre-defined options for common needs and it can do far more than just adjust colors, despite its name.

The built-in "Reduce File Size" filter is very aggressive: it will downsample all images to 512px wide. For PDFs where the entire page is a single image, this usually renders the document illegible. I created a "Reduce File Size (300dpi)" to downsample to a decent resolution density. It still can save tons of space on most documents.

![](/images/2021-03-10-mac-reduce-pdf-size-custom-filter/preview.png)

## Adding a new filter in ColorSync Utility

The app opens to the "Filters" tab by default presumably because this is its most common function. The easiest way to create a filter is to duplicate an existing one via the dropdown-arrow to the right of the filter in question. I duplicated the "Reduce File Size" filter, and then tweaked the options. I disabled "Constrain size" and instead enabled "Set Resolution" to 300 pixels/inch. I left Image Compression in the middle where it was.

![](/images/2021-03-10-mac-reduce-pdf-size-custom-filter/colorsync-utility.png)

The filter is automatically available when you're done editin.

## Using the new filter in Preview

You can apply the filter via the "Export..." option (**not** "Export as PDF..." counterintuitively.) Simple as that!

![](/images/2021-03-10-mac-reduce-pdf-size-custom-filter/preview-new-option.png)

[1]: http://archive.today/2021.03.10-174351/https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Introduction/Introduction.html
[2]: https://support.apple.com/lt-lt/guide/colorsync-utility/csync006/mac
