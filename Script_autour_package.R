#---------------------------------------------------------------------#
##----------- Elements pour la construction du package --------------##
#---------------------------------------------------------------------#

#-------- package dependencies -------------

library(devtools)
use_package("igraph","imports")


#------- datasets -------------------------

#Exemple 1
data_ty <- read.csv(file = "C:/Users/renaud.jaunatre/Desktop/Exemple_graphes.csv",header = T,sep = ";")
use_data(data_ty,overwrite=TRUE)


#------------- Manuel pdf ----------------
pack <- "TransiTypha"
path <- find.package(pack)
system(paste(shQuote(file.path(R.home("bin"), "R")),
             "CMD", "Rd2pdf", shQuote(path)))

