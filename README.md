LR-Clean
========

Delete files on disk that have been "removed" from the Lightroom catalog.

## Goal

When removing files in Lightroom (e.g, by pressing delete), the user can either "remove" the file from the catalog of lightroom or "delete" the file from the disk totally (non-reversible). This script deletes the files that have been removed.

To achieve this, it reads in the Lightroom catalog, locate the different imported folders and subfolders by Lightroom and removes any file that is on the file system that isn't in the catalog.

## How to use

First, open lightroom and go to Lightroom/Catalog Settings or press `Ctrl + Alt + , ` (for Windows) `Cmd + Option + , ` (for OSX). Then copy paste the folder into the script (first coding line):
```
# Enter the path of the folder where the catalog can be find.
folder = "/Users/antoinelizee/Pictures/Lightroom/"
```

Then install R if you don't have it already, go into the script directory, and launch it:
```
Rscript LR-Clean.R
```
