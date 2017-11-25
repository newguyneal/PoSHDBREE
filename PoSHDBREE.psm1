<#
.SYNOPSIS
This function parses through the headers of a HTTP request and grabs the CDN URI

.DESCRIPTION
Long description

.PARAMETER Response
This parameter is the response from a HTTP response

.EXAMPLE
$CDNURI = Get-DBREECDNLink -Response $Response

.NOTES
This is a helper function used to under the assumption that the response has the specified properties
#>
function Get-DBREECDNLink
{
    param($Response)
    
    $CDNURI = ($Response.Images | Where-Object id  -EQ jp-waveform-img).src
    return  $CDNURI
}
<#
.SYNOPSIS
this function returns the response to a webrequest based on a DBREE code

.DESCRIPTION
Using the "https://dbr.ee/$code" syntax as a URI you can find a track on the dbree website and return the response to be parsed
by other helper functions later

.PARAMETER Code
This is a key that when concatenated to the DBREE website URI will take you to a song on their platform

.EXAMPLE
$Response = Get-DBREEResponse -Code $code

.NOTES
this is a wrapper on the Invoke-WebRequest cmdlet
#>
function Get-DBREEResponse
{
    param($Code)
    $URI = "https://dbr.ee/$code"
    $Response = Invoke-WebRequest -Uri $URI
    return $Response

}
<#
.SYNOPSIS
This function takes a byte array and writes data to a file in a specified location

.DESCRIPTION
By passing in a byte array this function uses a filestream to write each byte one by one to a specified location.

.PARAMETER bytearray
This is the raw data of the file that will be written to disk

.PARAMETER path
This is the location that the file will be saved to

.EXAMPLE
Write-DBREEBytestoFile -bytearray $ByteArray -path $FilePath

.NOTES
General notes
#>
function Write-DBREEBytestoFile
{
    param($bytearray,$path)
    $writer = [System.IO.FileStream]::new($path,[System.IO.FileMode]::Create)

    for($index = 0 ; $index -lt $bytearray.Count;$index++)
    {
        $writer.WriteByte($bytearray[$index])
    }
    $writer.Seek(0,[System.IO.SeekOrigin]::Begin)
    $writer.Close()
}
<#
.SYNOPSIS
Returns the Byte array from the content of a response to a webrequest

.DESCRIPTION
By passing in a URI that points to the CDN for a song, this function will perform a webrequest to specified URI. Once the response is received if valid 200 status,
the content of the response will be extracted and returned. If the status is not 200, then a null value will be returned

.PARAMETER URI
The URI parameter represents an address that points to the CDN for the requested track

.EXAMPLE
$CDNResponse = Get-DBREECDNResponse -URI $CDNURI

.NOTES
a byte array returned here is the raw data of the file and will be processed and saved by the Write-DBREEBytestoFile function
#>
function Get-DBREECDNResponse
{
    param($URI)
    $Response = Invoke-WebRequest -Uri $URI
    if($Response.StatusCode -eq 200)
    {
        
        return $Response
    }
    return $null
}
<#
.SYNOPSIS
Gets the full name of a file from a response header

.DESCRIPTION
By passing in a Http response to this function, a files fullname is found through parsing the "Content-Disposition" Header
and using a regex to match a repeatable pattern.

.PARAMETER Response
This is the response from an Invoke-Webrequest on a specified URI

.EXAMPLE
Get-DBREEFileFullName -Response Invoke-WebRequest -URI "https://dbr.ee/qC3t"

.NOTES
Is used as a helper function
#>
function Get-DBREEFileFullName
{
    param($Response)

    $String = $Response.Headers.'Content-Disposition'
    $Matchstr = "filename=`"(.*?)`""
    if($String -match $Matchstr)
    {
        $Match = $Matches[1]
        return $match
    }
    else
    {
        return $null
    }
}
<#
.SYNOPSIS
Helper Function that gets file extension from a fullname

.DESCRIPTION
Helper Function that gets file extension from a fullname

.PARAMETER string
String is a parameter that will represent the fullname of a file

.EXAMPLE
Get-DBREEFileExtension -String "myfile.mp3"
return: mp3

.NOTES
Not used but is availabel for others
#>
function Get-DBREEFileExtension
{
    param($string)
    $extenstion = [System.IO.Path]::GetExtension($string)
    return $extenstion    
}
<#
.SYNOPSIS
By using various helper functions this function is able to send web requests to DBREE to be able to find
CDN links, FileNames and Byte arrays to be able to save multiple song files to the SaveDirectoryPath location

.DESCRIPTION
This function takes a path to a CSV (which contains DBREE URI codes) and Path to a Directory where users want to download music to
and parses the CSV for individual codes. It then calls various helper functions to send web requests to DBREE to be able to find
CDN links, FileNames and Byte arrays to be able to save multiple song files to the SaveDirectoryPath location


.PARAMETER CSVPath
Path to CSV containing DBREE URI Codes

.PARAMETER SaveDirectoryPath
Dictates the location that Users want to save music to

.EXAMPLE
Download-DBREESongsFromCSVCodes -CSVPath "c:\somepath\somedirectory\somecsv.csv" -SaveDirectoryPath "c:\somepath\somedirectory\"

.NOTES
This is the main "worker" for the module all other functions are meant to act as helper functions to this one.
#>
function Download-DBREESongsFromCSVCodes
{
    param($CSVPath,$SaveDirectoryPath)
    $CSVCodes = (Get-Content $CSVPath) -split ","
    foreach($code in $CSVCodes)
    {
        $Response = Get-DBREEResponse -Code $code
        if($Response.StatusCode -eq 200)
        {
            $CDNURI = Get-DBREECDNLink -Response $Response
            

            $CDNResponse = Get-DBREECDNResponse -URI $CDNURI
            $FileName = Get-DBREEFileFullName -response $CDNResponse
            $ByteArray = $CDNResponse.content
            if($ByteArray -ne $null)
            {   
                $FilePath = Join-Path -Path $SaveDirectoryPath -ChildPath $FileName
                Write-DBREEBytestoFile -bytearray $ByteArray -path $FilePath
            }
        }
    }
}
