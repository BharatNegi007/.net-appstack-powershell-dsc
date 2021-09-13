configuration DemoDotNet1 
    {


          

    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName PsDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration
    Import-DscResource -ModuleName xNetworking


    node localhost {
    <# Install Windows Feature  #>
    WindowsFeature IIS
    {
         name = "web-server"
         ensure = "present"
         IncludeAllSubFeature = $true
    }

    WindowsFeature EnableWinAuth
    {
        Name = "Web-Windows-Auth"
        Ensure = "Present"
       DependsOn = "[WindowsFeature]IIS"
    }
    WindowsFeature EnableURLAuth
     {
         Name = "Web-Url-Auth"
         Ensure = "Present"
         DependsOn = "[WindowsFeature]IIS"
    }
    WindowsFeature HostableWebCore
    {
          Name = "Web-WHC"
          Ensure = "Present"
          DependsOn = "[WindowsFeature]IIS"
    }
    WindowsFeature IISConsole
    {
        Ensure = "Present"
        Name = "Web-Mgmt-Console"
        DependsOn = '[WindowsFeature]IIS'
    }
    WindowsFeature IISScriptingTools
    {
        Ensure = "Present"
        Name = "Web-Scripting-Tools"
        DependsOn = '[WindowsFeature]IIS'
    }
    WindowsFeature AspNet
    {
      ensure = "present"
      name  = "Web-Asp-Net45"
      DependsOn = @('[WindowsFeature]IIS')
    }

        
<# Download dotnet core hosting bundle   #>
    xRemoteFile DownloadDotNetCoreHostingBundle
     {
        Uri = $dotnethostinguri
        DestinationPath = 'C:\temp\dotnethosting.exe'
        MatchSource = $false
     }
     Package InstallDotNetCoreHostingBundle
         {
               Name = "Microsoft ASP.NET Core Module"
               ProductId = '5C742CE3-6DA4-4B12-A7D0-77D38311297C'
               Arguments = "/quiet /norestart /log C:\temp\dnhosting_install.log"
               Path = 'C:\temp\dotnethosting.exe'
               DependsOn = @("[WindowsFeature]IIS",
                             "[xRemoteFile]DownloadDotNetCoreHostingBundle")
          }
    
        #stopping default website#
     xWebsite DefaultSite
        {
            Ensure = "Present"
            Name = "Default Web Site"
            State = "Stopped"
            PhysicalPath = 'C:\inetput\wwwroot'
            DependsOn = @('[WindowsFeature]IIS', '[WindowsFeature]AspNet')
        }

     xWebAppPool sampleAppPool
     {
         Ensure = "Present"
         State = "Started"
         Name = $apppoolname
     }
     xWebsite sampleSite
     {
        Ensure = "Present"
        State = "Started"
        Name = $Sitename
        PhysicalPath = $physicalpathforsite
        ApplicationPool = $apppoolname
        BindingInfo     = @(
            MSFT_xWebBindingInformation
            {
               
                Protocol              = $protocol
                Port                  =  $Port
                IPAddress             = $IpAddress
                HostName              = $HostName
                               
            })
        LogPath = "E:\inetpub\logs\webSite"
        ServerAutoStart = $true
     }
     xWebApplication demoapplication
     {
         Name = $AppName
         Website = $SiteName
         WebAppPool = $apppoolname
         PhysicalPath = $AppPhysicalPath
         Ensure = "Present"
         DependsOn = @('[xWebSite]sampleSite')
     }

     }


    }

    $dotnethostinguri = "https://download.visualstudio.microsoft.com/download/pr/a0f49856-eec9-4962-8d81-b09af6be9435/1d5fc0083b7f7e10ebed181329ca88ae/dotnet-hosting-5.0.9-win.exe"
    $apppoolname = 'samplepool'
    $SiteName = 'testsite'
    $physicalpathforsite = 'C:\Test'
    #------ Binding Info--------#
    $protocol = 'HTTP'
    $Port = 8080
    $IpAddress = 127.0.0.1 #---Default * --- #
    $HostName = 'testsite.com'
    #-------Application Info------#
    $AppName = 'demo'
    $AppPhysicalPath = 'C:\Test'
    

    DemoDotNet1 -verbose 

    Start-DscConfiguration -Path 'C:\DSC\DemoDotnet1' -wait -Force -Verbose
