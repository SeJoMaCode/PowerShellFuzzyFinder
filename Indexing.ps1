function Start-BackgroundIndexing {
    param(
        [string]$RootPath,
        [int]$MaxDepth,
        [string[]]$ExcludedDirectories
    )

    $indexingJob = Start-Job -ScriptBlock {
        param($rootPath, $maxDepth, $excludedDirectories)

        function Write-IndexingLog {
            param([string]$Message)
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logMessage = "[$timestamp] $Message"
            $logMessage | Out-File -Append -FilePath "$env:TEMP\FuzzyFinderIndexing.log"
        }

        function Get-RelativePath {
            param (
                [string]$Path,
                [string]$BasePath
            )
            try {
                $relativePath = $Path.Substring($BasePath.Length)
                if ($relativePath.StartsWith([IO.Path]::DirectorySeparatorChar)) {
                    $relativePath = $relativePath.Substring(1)
                }
                return if ($relativePath -eq '') {'.'} else {$relativePath}
            }
            catch {
                Write-IndexingLog "Error in Get-RelativePath: $($_.Exception.Message)"
                return $Path
            }
        }

        # Create a HashSet and add items individually
        $excludedSet = New-Object System.Collections.Generic.HashSet[string]
        foreach ($dir in $excludedDirectories) {
            [void]$excludedSet.Add($dir.ToLower())  # Convert to lower case for case-insensitive comparison
        }

        $items = [System.Collections.Generic.List[string]]::new()

        # Use Get-ChildItem with -Recurse and -Depth parameters
        Get-ChildItem -Path $rootPath -Recurse -Depth $maxDepth -File | ForEach-Object {
            $relativePath = $_.FullName.Substring($rootPath.Length).TrimStart('\')
            $parentDir = Split-Path -Path $relativePath -Parent

            # Check if any parent directory is in the excluded set
            $isExcluded = $parentDir -split '\\' | Where-Object { $excludedSet.Contains($_) }

            if (-not $isExcluded) {
                $items.Add($relativePath)
            }
        }

        Write-IndexingLog "Indexing complete. Total items processed: $totalProcessedItems. Total errors encountered: $totalErrors"
        return $items.ToArray()
    } -ArgumentList $RootPath, $MaxDepth, $ExcludedDirectories

    return $indexingJob
}

function Update-IndexingStatus {
    param (
        $Job,
        $Stopwatch
    )

    $updateRequired = $false

    if (-not $script:IndexingComplete -and $Job.State -eq 'Completed') {
        $script:IndexingComplete = $true
        $Stopwatch.Stop()
        $script:IndexingTime = $Stopwatch.ElapsedMilliseconds
        $newItems = Receive-Job -Job $Job
        foreach ($item in $newItems) {
            [void]$script:Items.TryAdd($item, 0)
        }
        $updateRequired = $true
    }

    return $updateRequired
}