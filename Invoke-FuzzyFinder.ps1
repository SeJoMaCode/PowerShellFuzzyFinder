$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Get-ChildItem -Path $ScriptPath -Filter *.ps1 | 
    Where-Object { $_.Name -ne 'Invoke-FuzzyFinder.ps1' } | 
    ForEach-Object { . $_.FullName }

function Invoke-FuzzyFinder {
    param(
        [int]$MaxDepth = 5,
        [string[]]$ExcludedDirectories = @('.git', 'node_modules', 'bin', 'obj'),
        [switch]$EnablePreview = $false
    )

    # Initialize variables
    $windowHeight = $Host.UI.RawUI.WindowSize.Height
    $lastWindowHeight = $windowHeight
    $rootPath = $PWD.Path
    $filteredItems = @()
    $previousFilteredItems = @()
    
    # Initialize global state (consider passing these as parameters in future refactoring)
    $script:query = ""
    $script:cursorPosition = 0
    $script:selectedIndex = 0
    $script:scrollOffset = 0
    $script:Items = [System.Collections.Concurrent.ConcurrentDictionary[string, byte]]::new([StringComparer]::OrdinalIgnoreCase)
    $script:IndexingComplete = $false
    $script:IndexingTime = 0

    # Start background indexing
    $indexingJob = Start-BackgroundIndexing -RootPath $rootPath -MaxDepth $MaxDepth -ExcludedDirectories $ExcludedDirectories
    $indexingStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Initial display setup
    Update-Display -FilteredItems $filteredItems -FullRedraw

    
    # Main loop
    while ($true) {
        $updateRequired = $false
        $fullRedrawRequired = $false
        
        $key = Get-KeyPress
        if ($null -ne $key) {
            $keyHandlingResult = Handle-KeyPress -Key $key -Query $query -CursorPosition $cursorPosition -SelectedIndex $selectedIndex -ScrollOffset $scrollOffset -FilteredItems $filteredItems
    
            if ($keyHandlingResult.Exit) {
                Clear-Host
                Stop-Job -Job $indexingJob
                Remove-Job -Job $indexingJob
                return $keyHandlingResult.ReturnValue
            }
    
            $script:query = $keyHandlingResult.Query
            $script:cursorPosition = $keyHandlingResult.CursorPosition
            $script:selectedIndex = $keyHandlingResult.SelectedIndex
            $script:scrollOffset = $keyHandlingResult.ScrollOffset
            $updateRequired = $keyHandlingResult.UpdateRequired
            
            if ($updateRequired) {
                $filteredItems = @(Get-FilteredItems -Pattern $query)
                Update-Display -FilteredItems $filteredItems -EnablePreview:$EnablePreview
                $previousFilteredItems = $filteredItems
            }
        } else {
            # Check for window resizing and update indexing status
            $fullRedrawRequired = Check-WindowResize -CurrentHeight $Host.UI.RawUI.WindowSize.Height -LastHeight $lastWindowHeight
            $updateRequired = Update-IndexingStatus -Job $indexingJob -Stopwatch $indexingStopwatch
    
            if ($updateRequired -or $fullRedrawRequired) {
                $filteredItems = @(Get-FilteredItems -Pattern $query)
                if (($filteredItems -ne $previousFilteredItems) -or $fullRedrawRequired) {
                    Update-Display -FilteredItems $filteredItems -FullRedraw:$fullRedrawRequired -EnablePreview:$EnablePreview
                    $previousFilteredItems = $filteredItems
                }
            }
        }
    
        # Short sleep to reduce CPU usage
        Start-Sleep -Milliseconds 5
    }
}

function Is-TextFile {
    param (
        [string]$FilePath
    )

    $textExtensions = @('.txt', '.md', '.json', '.xml', '.html', '.htm', '.css', '.js', '.ts', '.py', '.ps1', '.sh', '.bat', '.cmd', '.yaml', '.yml', '.ini', '.config', '.log')
    $fileExtension = [System.IO.Path]::GetExtension($FilePath).ToLower()

    if ($textExtensions -contains $fileExtension) {
        return $true
    }

    try {
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        $charCount = 0
        $nullCount = 0

        foreach ($byte in $bytes[0..1000]) {  # Check first 1000 bytes
            if ($byte -eq 0) {
                $nullCount++
            } elseif ($byte -ge 32 -and $byte -le 126) {  # Printable ASCII
                $charCount++
            }
        }

        # If more than 90% are printable chars and less than 1% are null bytes, consider it text
        return ($charCount / 1000 -gt 0.9) -and ($nullCount / 1000 -lt 0.01)
    }
    catch {
        return $false
    }
}

function Get-FilePreview {
    param (
        [string]$FilePath,
        [int]$MaxLines = 10
    )

    if (Test-Path $FilePath -PathType Leaf) {
        if (Is-TextFile -FilePath $FilePath) {
            try {
                $content = Get-Content -Path $FilePath -TotalCount $MaxLines -ErrorAction Stop
                return $content -join "`n"
            }
            catch {
                return "Unable to read file content: $($_.Exception.Message)"
            }
        } else {
            return "Preview not available: File appears to be binary or uses an unsupported encoding."
        }
    } elseif (Test-Path $FilePath -PathType Container) {
        return "Preview not available: Selected item is a directory."
    } else {
        return "Unable to preview: $FilePath"
    }
}