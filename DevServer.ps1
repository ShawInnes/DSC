Set-Location C:\Jobs

Configuration DevelopmentServer
{
    Import-DscResource -Module xWebAdministration 
    Import-DscResource -Module cWindowsOS
    Import-DscResource -Module xOneGet

    Node $AllNodes.NodeName
    {
         foreach ($Feature in @("Web-Server","Web-Mgmt-Tools","web-Default-Doc", ` 
                                "Web-Dir-Browsing","Web-Http-Errors","Web-Static-Content",` 
                                "Web-Http-Logging","web-Stat-Compression")) 
        { 
            WindowsFeature "$Feature" 
            { 
                Ensure = "Present"
                Name = $Feature
            } 
        }

        # Install ASP.NET 4.5
        WindowsFeature ASP
        {
            Ensure = “Present”
            Name = “Web-Asp-Net45”
            DependsOn       = "[WindowsFeature]Web-Server" 
        }

        # Install .NET 3.5
        WindowsFeature Net35
        {
            Ensure = “Present”
            Name = “Net-Framework-Core”
        }

        # Install Powershell DSC
        WindowsFeature DSC
        {
            Ensure = “Present”
            Name = “Dsc-Service”
        }

        xWebsite DefaultSite
        { 
            Ensure          = "Absent"
            Name            = "Default Web Site" 
            State           = "Stopped" 
            PhysicalPath    = "C:\inetpub\wwwroot" 
            DependsOn       = "[WindowsFeature]Web-Server" 
        }

        cHostsFile UbetHost
        {
            Ensure          = "Present"
            hostName        = "ubet.localhost"
            IPAddress       = "127.0.0.1"
        }

        xWebsite UbetSite
        { 
            Ensure          = "Present"
            Name            = "ubet.localhost" 
            State           = "Stopped" 
            PhysicalPath    = "C:\inetpub\ubetroot" 
            DependsOn       = @("[WindowsFeature]Web-Server", "[cHostsFile]UbetHost")
        }

        cHostsFile TattsHost
        {
            Ensure          = "Present"
            hostName        = "tatts.localhost"
            IPAddress       = "127.0.0.1"
        }

        xWebsite TattsSite
        { 
            Ensure          = "Present"
            Name            = "tatts.localhost" 
            State           = "Stopped" 
            PhysicalPath    = "C:\inetpub\tattsroot" 
            DependsOn       = @("[WindowsFeature]Web-Server", "[cHostsFile]TattsHost")
        }

        xOneGet NotepadPlusPlus
        {
            Ensure = "Present"
            PackageName = "NotepadPlusPlus"
        }

        xOneGet ReSharper
        {
            Ensure = "Present"
            PackageName = "resharper-platform"
        }

        Script WebEssentials
        {
            GetScript =
            {
                $testInstalled = (Get-ChildItem -Recurse -Force "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\" -ErrorAction SilentlyContinue `
                    | Where-Object { ( $_.Name -eq "WebEssentials2015.dll") }).Exists
                $testInstalled
            }
            SetScript =
            {
                $source = "https://visualstudiogallery.msdn.microsoft.com/ee6e6d8c-c837-41fb-886a-6b50ae2d06a2/file/146119/14/Web%20Essentials%202015.0%20CTP%206%20v0.3.52.vsix"
                $destination = Join-Path -Path $env:TEMP -ChildPath "WebEssentials.vsix"

                $wc = New-Object system.net.webclient
                $wc.downloadFile($source, $destination)

                $cmd = "& ""${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\IDE\VsixInstaller"" /q /a ""$env:TEMP\WebEssentials.vsix"""
             
                Invoke-Expression -Command   $cmd | Write-Verbose
            }
            TestScript =
            {
                $testInstalled = (Get-ChildItem -Recurse -Force "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\" -ErrorAction SilentlyContinue `
                    | Where-Object { ( $_.Name -eq "WebEssentials2015.dll") }).Exists
                
                if ($testInstalled) {
                    Write-Verbose "WebEssentials already installed"
                } else {
                    Write-Verbose "WebEssentials is not installed"
                }

                $testInstalled
            }
        }
        # C:\Chocolatey\lib\resharper-platform.1.0.1\ReSharperAndToolsPacked01Update1.exe /SpecificProductNames=ReSharper;dotCover;dotPeek;dotMemory;dotTrace /Silent=True /VsVersion=0;12;14
        <#
	    cDiskImage VisualStudioMount
	    {
		    Ensure          = "Present"
		    ImagePath       = "C:\Jobs\" + $ConfigurationData.NonNodeData.VisualStudioISO
		    DriveLetter     = "X"
	    }

        Script InstallVisualStudio
        {
            DependsOn       = @("[cDiskImage]VisualStudioMount")
            GetScript =
            {
                $isInstalled = Test-Path –Path "$env:ProgramFiles\Microsoft Visual Studio 12.0\"
                $isInstalled
            }
            SetScript =
            {
                $cmd = "X:\vs_ultimate.exe /NoRestart /AdminFile C:\Jobs\AdminDeployment.xml"
                Invoke-Expression cmd | Write-Verbose
            }
            TestScript =
            {
                $vsInstalled = Test-Path –Path "$env:ProgramFiles\Microsoft Visual Studio 12.0\"
                
                if ($vsInstalled) {
                    Write-Verbose "Visual Studio already installed"
                } else {
                    Write-Verbose "Visual Studio is not installed"
                }
                $vsInstalled
            }
        }
        #>
    }
}

$configData = @{ 
    # Node specific data 
    AllNodes = @( 
       # All the WebServer has following identical information  
       @{ 
            NodeName           = "*" 
            DefaultWebSitePath = "C:\inetpub\wwwroot"
       }, 
       @{ 
            NodeName           = "localhost" 
            Roles              = @("Web", "Ubet-Web", "Tatts-Web", "VisualStudio")
        }
    );

    NonNodeData = @{
        SqlServerISO       = "en_sql_server_2014_developer_edition_x64_dvd_3940406.iso"
        VisualStudioISO    = "en_visual_studio_2015_ultimate_ctp_6_version_14.0.22609.0.d14rel_x86_dvd_6383012.iso"
    }
} 

$configData.NonNodeData.SqlServerISO

DevelopmentServer -ConfigurationData $configData 

Start-DscConfiguration .\DevelopmentServer -Verbose –Wait

