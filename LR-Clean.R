# This script is intended to explore the lightroom catalog and 
# clean files on the hard drive when they don't exist in the catalog
# while they are in a folder "covered" by the catalog.
#
# It takes as command line input the catalog file itself.
#
# Copyright Antoine Lizee antoine.lizee@gmail.com 12/21014 MIT License


# Initialization ----------------------------------------------------------

# Enter the path of the folder where the catalog can be find.
folder = "/Users/antoinelizee/Pictures/Lightroom/"

file = dir(path = folder, pattern = ".lrcat$", full.names = TRUE)

library(RSQLite)
con <- dbConnect(SQLite(), file)


# Quick exploration -------------------------------------------------------
#DOES NOT RUN

if (launchExploration <- FALSE) {
  # Loading full database in memory
  TABLES <- sapply(dbListTables(con), dbReadTable, conn = con)
  
  # Define function to look for fields in the db
  findField <- function(pattern, con) {
    tableNames <- dbListTables(con)
    matches <- sapply(tableNames, function(tableName) {
      grep(pattern, dbListFields(con, tableName), value = TRUE, ignore.case = TRUE)
    })
    matches[sapply(matches, length) != 0]
  }
  
  findField("path", con)
  str(TABLES[sapply(TABLES, nrow) > 10])
  head(TABLES$AgLibraryFile)
  head(TABLES$AgLibraryFolder)
  head(TABLES$AgLibraryRootFolder)
}

# Get the files and their path fromthe catalog ------------------------------
## Directly use SQL, faster.

sqlStatement = ## folder and rootfolder fields are non-necessary
  "SELECT originalFilename, folder, pathFromRoot, rootfolder, absolutePath, name 
  FROM AgLibraryFile 
  LEFT JOIN AgLibraryFolder as folder ON folder = folder.id_local 
  LEFT JOIN AgLibraryRootFolder as rootfolder ON rootFolder = rootfolder.id_local"
# LIMIT 5;"

pictureTable <- dbGetQuery(con, sqlStatement)
pictureTable$totalFolderPath <- file.path(pictureTable$absolutePath, pictureTable$pathFromRoot)

# Reshape the data frame into a list of file, per folder:
pictureFiles <- sapply(unique(pictureTable$totalFolderPath), function(folderPath) {
  pictureTable[pictureTable$totalFolderPath == folderPath, "originalFilename"]
})

# Treat the folders -------------------------------------------------------

# Input function
checkInput <- function(ok = c("Yes", "Y", "")) {
  answer <- readLines(con = "stdin", 1) #readline("") is good for interactive sessions only (non compatible with Rscript)
  answer %in% ok
}

# Create the folder in which all files will be put.
createDirOrFail <- function(path){
  tryCatch(
    dir.create(path, recursive = TRUE),
    warning = function(w) {
      stop("Impossible to create the recovery folder to store the files, please solve this issue before proceeding further:\n", w$message)
    }
  )
}
tempFolder <- file.path("~/Desktop/tempLRCleanRemoveMe", Sys.time())
createDirOrFail(tempFolder)

# function to move files, even between drives
file.move <- function(from, to) {
  hasCopied <- file.copy(from, to)
  if (all(hasCopied)) {
  file.remove(from)
  } else {
    file.remove(to)
    warnings()
    stop("ERROR while moving files...")
  }
}

for (folder in names(pictureFiles)) {
  cat("## Folder ", folder, "--------------\n")
  extensions <- unique(sapply(lapply(strsplit(pictureFiles[[folder]], "\\."), rev), "[", 1))
  existingFiles <- dir(folder, paste(extensions, sep = "|"))
  orphanFiles <- existingFiles[!existingFiles %in% pictureFiles[[folder]]]
  
  if ((nOrphan <- length(orphanFiles)) == 0) {
    cat("No files to remove...\n")
  } else {
    if (nOrphan > length(existingFiles) * 0.5) {
      cat("WARNING! more than 50% of files to remove, there might be a problem...\n")
    }
    cat(nOrphan, "files to remove. Proceed?")
    if (checkInput()) {
      stopifnot(file.move(file.path(folder, orphanFiles), file.path(tempFolder, orphanFiles)))
      writeLines(file.path(folder, orphanFiles), con = fopen <- file(file.path(tempFolder, "movedFiles.txt"), open = "a"))
      close(fopen)
      cat("Done\n")
    } else {
      cat("Moving on...\n")
    }
  } 
}
cat(
"\nDon't forget to manually clean up the files in the temp directory
(", tempFolder, ")
if everything went well (try Lightroom),
or use the text file included in the folder to recover 
the files and revert the operation.\n")
cat("\n## Thank you for using this script! - ALizée\n")

