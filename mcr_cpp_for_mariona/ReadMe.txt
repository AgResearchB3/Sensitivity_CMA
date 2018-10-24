16 July 2015: The 3 July 2015 version of 'ClimateMatchV3' in this dir was modified by RJ to correct a divide by zero error in the rainfall pattern index calculation. 

C++ reads variables by column number, not name.

If you run the app from a commandline with a /? Parameter or incorrect parameters it prints out the usage info. The /? Is pretty much the standard way of asking a commandline app what parameters it takes. You may not have seen the output but it reads:

Usage: ClimateMatchV3.exe <location1File> <location2File> <outputFile> [startLocation] [numLocations]

Produces outputFile containing the locations in location1File with the best CMI index match from loc2File

[startLocation] is the nth location to start from in loc1File. Absent or 0 = 1
[numLocations] is the number of locations to process from loc1File.  Absent or 0 = to end of file.

NOTE: the input files must contain a header row, which will always be ignored.
loc1 and loc2 files must contain the same number of readings per location

Input file format: Key,Lat,Lon,Continent,ReadingNum,Tmax,Tmin,Rain,RH9,RH3
Craig's excel file headers: Key,Lat,Long,Continent,Week,Tmax,Tmin,Rain,RH9,RH3,UnrotWk

Craig's NOTE: Southern Hemisphere climate data must be ordered by Key & UnrotWk before comparing them to Northern Hemisphere data.

Output file format: Loc1Key,Loc1Lat,Loc1Lon,BestCMI,BestKey,BestLat,BestLon

Example Run.bat file. Use "RecordsPerCoreCalculator.xlsx"
start ClimateMatchV3.exe AwayDataByWeek28May2015.csv HomeDataByWeek30May2015.csv out1.csv 1 453707
start ClimateMatchV3.exe AwayDataByWeek28May2015.csv HomeDataByWeek30May2015.csv out2.csv 453708 453707
start ClimateMatchV3.exe AwayDataByWeek28May2015.csv HomeDataByWeek30May2015.csv out3.csv 907416 453707
start ClimateMatchV3.exe AwayDataByWeek28May2015.csv HomeDataByWeek30May2015.csv out4.csv 1361123 453707
start ClimateMatchV3.exe AwayDataByWeek28May2015.csv HomeDataByWeek30May2015.csv out5.csv 1814831 453707
start ClimateMatchV3.exe AwayDataByWeek28May2015.csv HomeDataByWeek30May2015.csv out6.csv 2268538 453707
start ClimateMatchV3.exe AwayDataByWeek28May2015.csv HomeDataByWeek30May2015.csv out7.csv 2722246 453707

# May 2018: There is a bug in ClimateMatch_V3.exe. If there is only 1 AWAY pp/climate cell, then the 1st HOME location is recorded as matching that cell. However, all the remaining HOME locations have NA as the best matched AWAY cell, when it should obviously be the ID of the sole AWAY cell rather than NA. This will influence the script that identifies particularly influential AWAY climate cells. 
# It is possible this same bug causes the observed sporadic NAs in projections that involve >1 AWAY cells.
