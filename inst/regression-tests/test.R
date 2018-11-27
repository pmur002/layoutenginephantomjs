
library(layoutEnginePhantomJS)
library(gyre)
library(xtable)

tests <- function() {
    grid.html("<p>test</p>")
    grid.newpage()
    grid.html(xtable(head(mtcars[1:3])), 
              x=unit(1, "npc") - unit(2, "mm"),
              y=unit(1, "npc") - unit(2, "mm"),
              just=c("right", "top"))
}

pdf("tests.pdf")
tests()
dev.off()

cairo_pdf("tests-cairo.pdf", onefile=TRUE)
tests()
dev.off()

## Check graphical output
testoutput <- function(basename) {
    PDF <- paste0(basename, ".pdf")
    savedPDF <- system.file("regression-tests", paste0(basename, ".save.pdf"),
                            package="layoutEnginePhantomJS")
    diff <- tools::Rdiff(PDF, savedPDF)
    
    if (diff != 0L) {
        ## If differences found, generate images of the differences
        ## and error out
        system(paste0("pdfseparate ", PDF, " test-pages-%d.pdf"))
        system(paste0("pdfseparate ", savedPDF, " model-pages-%d.pdf"))
        modelFiles <- list.files(pattern="model-pages-.*")
        N <- length(modelFiles)
        for (i in 1:N) {
            system(paste0("compare model-pages-", i, ".pdf ",
                          "test-pages-", i, ".pdf ",
                          "diff-pages-", i, ".png"))
        } 
        stop("Regression testing detected differences")
    }
}

testoutput("tests")
testoutput("tests-cairo")