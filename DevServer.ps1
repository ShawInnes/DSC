Set-Location C:\Jobs

Configuration DevelopmentServer
{
    Import-DscResource -Module xWebAdministration 
    Import-DscResource -Module cWindowsOS

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

	    cDiskImage VS2015Mount
	    {
		    Ensure          = "Present"
		    ImagePath       = "C:\Temp\" + $ConfigurationData.NonNodeData.VisualStudioISO
		    DriveLetter     = "X"
	    }

        Script InstallVisualStudio2015
        {
            DependsOn       = @("[cDiskImage]VS2015Mount")
            GetScript =
            {
                $isInstalled = Test-Path –Path "$env:ProgramFiles\Microsoft Visual Studio 13.0\"
                $isInstalled
            }
            SetScript =
            {
                $cmd = "X:\vs_ultimate.exe /Passive /NoRestart /AdminFile X:\AdminDeployment.xml "
                Invoke-Expression cmd | Write-Verbose
            }
            TestScript =
            {
                $vsInstalled = Test-Path –Path "$env:ProgramFiles\Microsoft Visual Studio 13.0\"
                
                if ($vsInstalled) {
                    Write-Verbose "Visual Studio 2015 already installed"
                } else {
                    Write-Verbose "Visual Studio 2015 is not installed"
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
            Roles              = @("Web", "Ubet-Web", "Tatts-Web", "VS2015")
        }
    );

    NonNodeData = @{
        ISOPath            = "Z:\ISO\"
        SqlServerISO       = "en_sql_server_2014_developer_edition_x64_dvd_3940406.iso"
        VisualStudioISO    = "en_visual_studio_2015_ultimate_ctp_6_version_14.0.22609.0.d14rel_x86_dvd_6383012.iso"
    }
} 

$configData.NonNodeData.SqlServerISO

DevelopmentServer -ConfigurationData $configData 

Start-DscConfiguration .\DevelopmentServer -Debug –Wait
