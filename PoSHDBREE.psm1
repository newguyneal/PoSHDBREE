
function Get-DBREECDNLink
{
    param($Response)
    
    $CDNURI = $Response.BaseResponse.ResponseUri
    return  $CDNURI
}

function Get-DBREEResponse
{
    param($Code)
    $URI = "https://dbr.ee/$code"
    $Response = Invoke-WebRequest -Uri $URI
    return $Response

}

function Write-DBREEBytestoFile
{
    param($bytearray,$path)
    $writer = [System.IO.FileStream]::new($path,[System.IO.FileMode]::Create)

    for($index = 0 ; $index -lt $bytearray.Count;$index++)
    {
        $writer.WriteByte($bytearray[$index])
    }
    $writer.Close()
}

function Get-DBREEFileBytes
{
    param($URI)
    $Response = Invoke-WebRequest -Uri $URI
    if($Response.StatusCode -eq 200)
    {
        $bytearray = $Response.Content
        return $bytearray
    }
    return $null
}



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

function Get-DBREEFileExtension
{
    param($string)
    $extenstion = [System.IO.Path]::GetExtension($string)
    return $extenstion    
}

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
            $FileName = Get-DBREEFileFullName -response $Response

            $ByteArray = Get-DBREEFileBytes -URI $CDNURI
            if($ByteArray -ne $null)
            {
                Write-DBREEBytestoFile -bytearray $ByteArray
            }
        }
    }
}
