[CmdletBinding()]
Param (
    [string]$SolutionDir = "$BuildRoot\src",
    [string]$ProjectName = "Starwars.DB",
    [string]$BuildDir = "$BuildRoot\Output",
    [string]$Configuration = "Release"
)

task Clean { 
    Remove-Item "$SolutionDir\$ProjectName\bin" -ErrorAction SilentlyContinue -Force -Recurse
    Remove-Item "$SolutionDir\$ProjectName\obj" -ErrorAction SilentlyContinue -Force -Recurse
    Remove-Item $BuildDir -ErrorAction SilentlyContinue -Force -Recurse


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

task . Clean, Build