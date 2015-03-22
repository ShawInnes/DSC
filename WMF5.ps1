if ((Get-CimInstance -ClassName Win32_OperatingSystem).Version -eq '6.3.9600')
{
    if ((Get-Ciminstance -ClassName Win32_Processor).Addresswidth -eq '64') 
    {
        $url = 'http://download.microsoft.com/download/5/5/2/55277C4B-75D1-40FB-B99C-4EAFA249F645/WindowsBlue-KB2894868-x64.msu'
    }
    else 
    {
        $url = 'http://download.microsoft.com/download/5/5/2/55277C4B-75D1-40FB-B99C-4EAFA249F645/WindowsBlue-KB2894868-x86.msu'
    }
  
    $fileName = Split-Path $url -Leaf
    $downloadPath = "$env:userprofile\Downloads\$fileName"
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($url,$downloadPath)
  
    Invoke-Expression -Command "wusa.exe $downloadPath /quiet /norestart"  
}
else 
{
    Write-Warning -message 'Windows Management Framework 5.0 requires Windows 8.1 or Windows Server 2012 R2'
} 

