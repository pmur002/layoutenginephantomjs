
.onLoad <- function(libname, pkgname) {
    options(layoutEngine.backend=phantomjsEngine,
            layoutEnginePhantomJS.debug=FALSE)
}
