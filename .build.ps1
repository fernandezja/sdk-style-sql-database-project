[CmdletBinding()]
Param (
    [string]$SolutionDir = "$BuildRoot\src",
    [string]$ProjectName = "Starwars.DB",
    [string]$BuildDir = "$BuildRoot\Output",
    [string]$Configuration = "Release",
    [string]$ToolsPath = "$BuildRoot\Tools",
    [string]$SqlPackageToolsPath = ""
)

task Clean { 
    Remove-Item "$SolutionDir\$ProjectName\bin" -ErrorAction SilentlyContinue -Force -Recurse
    Remove-Item "$SolutionDir\$ProjectName\obj" -ErrorAction SilentlyContinue -Force -Recurse
    Remove-Item $BuildDir -ErrorAction SilentlyContinue -Force -Recurse

}

task Init {
    $SqlPackageToolsPath = (Resolve-Path "$ToolsPath\SqlPackage\sqlpackage.exe")

    Write-Build Yellow $SqlPackageToolsPath
    if (-not(Test-Path $SqlPackageToolsPath)) {
         Write-Build Yellow "SqlPackage > Not found"

         if (-not(Test-Path $ToolsPath)) {
            New-Item -Path $ToolsPath -ItemType Directory
        }
        
        Write-Build Yellow "Downloading SqlPackage.exe..."
        $Uri = 'https://aka.ms/sqlpackage-windows'
        $Download = Invoke-WebRequest -Uri $Uri -OutFile "$ToolsPath\SqlPackage.zip"
        
        Expand-Archive -Path "$ToolsPath\SqlPackage.zip" -DestinationPath "$ToolsPath\SqlPackage" -Force
    }
    else
    {
        Write-Build Green "SqlPackage > Found > $($SqlPackageToolsPath)"
    }    
   
}

task Deploy {
    Set-Alias SqlPackage (Resolve-Path "$ToolsPath\SqlPackage\sqlpackage.exe").Path
    $LocalPublishProfile = (Get-ChildItem "$BuildRoot\src\$ProjectName\publish\Local.publish.xml").FullName
    Write-Build Yellow "Deploying database with profile: $LocalPublishProfile"

    #https://learn.microsoft.com/en-us/sql/tools/sql-database-projects/tutorials/create-deploy-sql-project
    exec {
        sqlpackage /Action:Publish /Profile:$LocalPublishProfile /SourceFile:$DacPacFile

    }
}


task Build {
    $Projects = @()
    $Projects += "$SolutionDir\$ProjectName\$ProjectName.sqlproj"
    $Projects | Foreach-Object {
        Write-Build Yellow "Project build: $_"
        exec {
            dotnet build $_ -c $Configuration /p:NetCoreBuild=True -o $BuildDir
        }
    }

    $Script:DacPacFile = (Resolve-Path "$BuildDir\$ProjectName.dacpac").Path
    Write-Build Yellow "DacPac path: $DacPacFile"
}

task . Clean, Build, Init, Deploy