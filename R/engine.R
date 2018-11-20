
## CSS standard says 1px = 1/96in !?
dpi <- 96

breakText <- function(text, family, face, size, width) {
    ## Have to split the text ourselves if necessary
    ## THIS IS VERY ROUGH
    pushViewport(viewport(gp=gpar(fontfamily=family, fontface=face,
                                  fontsize=size)))
    words <- strsplit(text, " ")[[1]]
    if (length(words )== 1) {
        finaltext <- text
    } else {
        spaceWidth <- convertWidth(stringWidth(" "), "in", valueOnly=TRUE)
        finaltext <- ""
        linetext <- words[1]
        index <- 2
        while (index <= length(words)) {
            attempt <- paste(linetext, words[index])
            ## Nasty fudge factor based on values being rounded to nearest
            ## pixel (when PhantomJS works out its layout) 
            if (convertWidth(stringWidth(attempt), "in",
                             valueOnly=TRUE) <= width + dpi/2) {
                ## If there is room, add space then word to current line
                linetext <- attempt
            } else {
                ## Otherwise save current line and start new line 
                finaltext <- paste0(finaltext, linetext, "\n")
                linetext <- words[index]
            }
            index <- index + 1
        }
        finaltext <- paste0(finaltext, linetext)
    }
    popViewport()
    finaltext
}

splitLines <- function(layout) {
    layout
}

phantomjsLayout <- function(html, width, height, fonts, device) {
    ## Work in temp directory
    wd <- file.path(tempdir(), "PhantomJS")
    if (!dir.exists(wd))
        dir.create(wd)
    ## Copy font files
    file.copy(fontFiles(fonts, device), wd)
    ## Create HTML file
    htmlfile <- tempfile(tmpdir=wd, fileext=".html")
    writeLines(as.character(html), htmlfile)
    ## Run PhantomJS to get the layout
    phantomjs <- Sys.which("phantomjs")
    ## Ensure that PhantomJS can see the font files
    Sys.setenv(QT_QPA_FONTDIR=wd)
    ## Ensure that PhantomJS can run without X Server
    Sys.setenv(QT_QPA_PLATFORM="offscreen")
    ## Layout result file
    outfile <- file.path(wd, "layout.csv")
    system(paste(phantomjs, 
                 system.file("JS", "phantomLayout.js",
                             package="layoutEnginePhantomJS"),
                 htmlfile, outfile))
    layoutDF <- read.csv(outfile, header=FALSE, stringsAsFactors=FALSE,
                         ## PhantomJS puts single quotes around font family
                         ## names that contain spaces (?)
                         quote="'")
    ## Convert font size from CSS pixels to points
    layoutDF[, 10] <- layoutDF[, 10]*72/dpi
    ## Break text if necessary
    do.call(makeLayout, unname(splitLines(layoutDF[1:10])))
}

phantomjsEngine <- makeEngine(phantomjsLayout)