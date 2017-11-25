import-module ..\PoSHDBREE
#create a csv with multiple dbree codes Zomboy - Invaders (Spag Heddy Remix) , Spag Heddy - Dream & Disaster (Instrumental Mix).mp3
"qC3t","SFGX" |out-file .\codes.csv

#use the codes csv and relative location to work the main function
Download-DBREESongsFromCSVCodes -CSVPath .\codes.csv -SaveDirectoryPath C:\Users\someuser\Music
