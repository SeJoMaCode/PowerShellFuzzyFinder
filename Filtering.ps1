$script:LastFilteredItems = @()
$script:LastPattern = ""

function Get-FilteredItems {
    param (
        [string]$Pattern
    )
    
    if ($Pattern -eq '') { 
        $script:LastFilteredItems = $script:Items.Keys | ForEach-Object { @{Item = $_; Matches = @() } }
        $script:LastPattern = ""
        return $script:LastFilteredItems
    }

    if ($Pattern.StartsWith($script:LastPattern)) {
        return Get-IncrementalFilteredItems -Pattern $Pattern
    } else {
        return Get-FullFilteredItems -Pattern $Pattern
    }
}

function Get-FullFilteredItems {
    param (
        [string]$Pattern
    )
    
    $patternParts = $Pattern.ToLower() -split '/' | Where-Object { $_ -ne '' }
    $patternRegex = '(?i)' + (($patternParts | ForEach-Object {
        $part = [regex]::Escape($_)
        $part -replace '\\\*', '.*?'  # Replace \* (escaped *) with .* for wildcard matching
    }) -join '.*\\.*')
    
    $filteredItems = $script:Items.Keys | ForEach-Object {
        $path = $_
        $results = [regex]::Matches($path, $patternRegex, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        
        if ($results.Count -gt 0) {
            $highlightMatches = @()
            foreach ($match in $results) {
                foreach ($capture in $match.Captures) {
                    $highlightMatches += @{Start = $capture.Index; Length = $capture.Length}
                }
            }
            @{Item = $path; Matches = $highlightMatches}
        }
    } | Where-Object { $null -ne $_ }

    $script:LastFilteredItems = $filteredItems
    $script:LastPattern = $Pattern
    return $filteredItems
}

function Get-IncrementalFilteredItems {
    param (
        [string]$Pattern
    )
    
    $patternParts = $Pattern.ToLower() -split '/' | Where-Object { $_ -ne '' }
    $patternRegex = '(?i)' + (($patternParts | ForEach-Object {
        $part = [regex]::Escape($_)
        $part -replace '\\\*', '.*?'  # Replace \* (escaped *) with .* for wildcard matching
    }) -join '.*\\.*')
    
    $filteredItems = $script:LastFilteredItems | ForEach-Object {
        $path = $_.Item
        $results = [regex]::Matches($path, $patternRegex, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        
        if ($results.Count -gt 0) {
            $highlightMatches = @()
            foreach ($match in $results) {
                foreach ($capture in $match.Captures) {
                    $highlightMatches += @{Start = $capture.Index; Length = $capture.Length}
                }
            }
            @{Item = $path; Matches = $highlightMatches}
        }
    } | Where-Object { $null -ne $_ }

    $script:LastFilteredItems = $filteredItems
    $script:LastPattern = $Pattern
    return $filteredItems
}

function Update-FilteredResults {
    param (
        [string]$Query,
        [array]$PreviousFilteredItems
    )

    $filteredItems = @(Get-FilteredItems -Pattern $Query)
    if (Compare-Object $filteredItems $PreviousFilteredItems) {
        return $filteredItems, $true
    }
    return $PreviousFilteredItems, $false
}

function Get-NextIndex {
    param (
        [int]$CurrentIndex,
        [int]$TotalCount,
        [int]$Direction
    )

    return ($CurrentIndex + $Direction + $TotalCount) % $TotalCount
}

function Update-ScrollOffset {
    param (
        [int]$SelectedIndex,
        [int]$ScrollOffset,
        [int]$WindowHeight
    )

    if ($SelectedIndex -lt $ScrollOffset) {
        return $SelectedIndex
    } elseif ($SelectedIndex -ge ($ScrollOffset + $WindowHeight - 6)) {
        return $SelectedIndex - ($WindowHeight - 7)
    }
    return $ScrollOffset
}