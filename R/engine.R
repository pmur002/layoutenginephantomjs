
## CSS standard says 1px = 1/96in !?
dpi <- 96

breakText <- function(text, family, bold, italic, size, width) {

    if (is.na(text) || nchar(text) == 0)
        return(NA)
    
    ## THIS IS VERY ROUGH
    face <- 1
    if (bold) {
        face <- face + 1
    }
    if (italic) {
        face <- face + 2
    }
    pushViewport(viewport(gp=gpar(fontfamily=family, fontface=face,
                                  fontsize=size)))
    ## Remove leading/trailing white space
    words <- strsplit(gsub("^ +| +$", "", text), " ")[[1]]
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
                             valueOnly=TRUE) <= width + 1.5/dpi) {
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
    splitText <- mapply(breakText,
                        text=layout[,7], family=layout[,8],
                        bold=layout[,9], italic=layout[,10],
                        size=layout[,11], width=layout[,5]/dpi,
                        USE.NAMES=FALSE, SIMPLIFY=FALSE)
    layout[,7] <- unlist(splitText)
    layout
}

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
    writeLines(as.character(html), htmlfile)
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
                 htmlfile, outfile))
    layoutDF <- read.csv(outfile, header=FALSE, stringsAsFactors=FALSE,
                         strip.white=TRUE,
                         ## PhantomJS puts single quotes around font family
                         ## names that contain spaces (?)
                         quote="'\"")
    ## Convert font size from CSS pixels to points
    layoutDF[, 11] <- layoutDF[, 11]*72/dpi
    ## Break text if necessary
    do.call(makeLayout, unname(splitLines(layoutDF)))
}

phantomjsEngine <- makeEngine(phantomjsLayout)
