
## CSS standard says 1px = 1/96in !?
dpi <- 96

phantomjsLayout <- function(html, width, height, fonts, device) {
    ## Work in temp directory
    wd <- file.path(tempdir(), "PhantomJS")
    if (!dir.exists(wd))
        dir.create(wd)
    assetDir <- file.path(wd, "assets")
    if (!dir.exists(assetDir))
        dir.create(assetDir)    
    ## Copy font files
    file.copy(fontFiles(fonts, device), assetDir)
    ## Copy any assets
    copyAssets(html, assetDir)
    ## Create HTML file
    htmlfile <- tempfile(tmpdir=wd, fileext=".html")
    writeLines(as.character(html$doc), htmlfile)
    ## Run PhantomJS to get the layout
    phantomjs <- Sys.which("phantomjs")
    ## Ensure that PhantomJS can see the font files
    Sys.setenv(QT_QPA_FONTDIR=wd)
    ## Ensure that PhantomJS can run without X Server
    Sys.setenv(QT_QPA_PLATFORM="offscreen")
    ## Layout result file
    outfile <- file.path(wd, "layout.csv")
    debug <- ""
    if (getOption("layoutEnginePhantomJS.debug")) {
        debug <- "--debug=true"
    }
    system(paste(phantomjs, debug,
                 system.file("JS", "phantomLayout.js",
                             package="layoutEnginePhantomJS"),
                 htmlfile, width*dpi, height*dpi, outfile))
    layoutDF <- read.csv(outfile, header=FALSE, stringsAsFactors=FALSE,
                         strip.white=TRUE,
                         ## PhantomJS puts single quotes around font family
                         ## names that contain spaces (?)
                         quote="'\"")
    names(layoutDF) <- names(layoutFields)
    ## Convert font size from CSS pixels to points
    layoutDF$size <- layoutDF$size*72/dpi
    ## Break text if necessary
    do.call(makeLayout, unname(layoutDF))
}

phantomjsEngine <- makeEngine(phantomjsLayout)
