# Download, Crunch, and Comb your CrunchBase data!

Create a file called `api.key` with your API Key.

Then:
`bundle install`
`ruby downloader.rb`
`ruby cruncher.rb`
`ruby comb.rb` ... or something like that.


# File Structure:

Path: /data
Notes: Ignored in the .gitignore. Holds information from fetching JSON files from Crunchbase.com/Api

Path: /resources
Notes: Just some documents to save related to analysis and other things on top of the core code base

# Files:

common.rb - some shared monkey patches and constants used by other files
downloader.rb - parallel fetching of crunchbase people and companies in json format, stores to /data
cruncher.rb - loads crunchbase data into mongodb. will read from /data, data will not be overwritten into MongoDB.
exploration/comb.rb - sift through people and pull out data

# Future notes:
It'd be good to timestamp the data directories so we can do pulls daily and then run the cruncher on the new directories, by date. 