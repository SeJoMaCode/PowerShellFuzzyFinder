function Get-HighlightedMatches {
    param (
        [string]$Item,
        [array]$Matches,
        [bool]$IsSelected
    )
    $highlightColor = if ($IsSelected) {"92;33"} else {"33"}
    $resetColor = if ($IsSelected) {"32"} else {"0"}
    $result = $Item
    
    # Sort matches in reverse order to avoid messing up string indices
    $sortedMatches = $Matches | Sort-Object {$_.Start} -Descending
    
    foreach ($match in $sortedMatches) {
        $start = $match.Start
        $length = $match.Length
        $result = $result.Insert($start + $length, "$([char]27)[${resetColor}m")
        $result = $result.Insert($start, "$([char]27)[${highlightColor}m")
    }
    
    return $result
}

function Update-Display {
    param (
        [array]$FilteredItems,
        [switch]$FullRedraw,
        [switch]$UpdateStatusOnly,
        [switch]$EnablePreview
    )
    
    if ($FullRedraw) {
        Clear-Host
        $Host.UI.RawUI.CursorPosition = @{X=0; Y=1}
        Write-Host "Enter your search query (Enter to select, Esc to cancel, Tab to cycle):" -NoNewline -ForegroundColor Blue
    }

    # Update indexing status
    $Host.UI.RawUI.CursorPosition = @{X=72; Y=1}
    if ($script:IndexingComplete) {
        Write-Host "[Indexed $($script:Items.Count) items in $($script:IndexingTime) ms]" -NoNewline -ForegroundColor DarkGray
    } else {
        Write-Host "[Indexing... $($script:Items.Count) items so far]" -NoNewline -ForegroundColor DarkYellow
    }
    Write-Host "".PadRight($Host.UI.RawUI.WindowSize.Width - $Host.UI.RawUI.CursorPosition.X)

    # Update status line
    $Host.UI.RawUI.CursorPosition = @{X=0; Y=2}
    if ($FilteredItems.Count -gt 0) {
        Write-Host "Results: $($script:SelectedIndex + 1)/$($FilteredItems.Count)" -NoNewline -ForegroundColor DarkCyan
    } else {
        Write-Host "Results: " -NoNewline -ForegroundColor DarkCyan
        Write-Host "0/0" -NoNewline -ForegroundColor Red
    }
    Write-Host "".PadRight($Host.UI.RawUI.WindowSize.Width - $Host.UI.RawUI.CursorPosition.X)

    if (-not $UpdateStatusOnly) {
        $windowHeight = $Host.UI.RawUI.WindowSize.Height
        $previewWidth = if ($EnablePreview) { [math]::Floor($Host.UI.RawUI.WindowSize.Width / 2) } else { 0 }
        $listWidth = $Host.UI.RawUI.WindowSize.Width - $previewWidth
        $displayCount = [Math]::Min($FilteredItems.Count, $windowHeight - 6)
        $startIndex = [Math]::Max(0, [Math]::Min($script:ScrollOffset, $FilteredItems.Count - $displayCount))

        # Display filtered items
        # Display filtered items
        for ($i = 0; $i -lt $windowHeight - 6; $i++) {
            $index = $startIndex + $i
            $Host.UI.RawUI.CursorPosition = @{X=0; Y=($i + 4)}

            if ($index -lt $FilteredItems.Count) {
                $itemData = $FilteredItems[$index]
                $isSelected = $index -eq $script:SelectedIndex
                $displayItem = Get-HighlightedMatches -Item $itemData.Item -Matches $itemData.Matches -IsSelected $isSelected
                if ($isSelected) {
                    Write-Host "   > " -NoNewline -ForegroundColor Green
                    Write-Host $displayItem.PadRight($listWidth - 5) -ForegroundColor DarkGreen
                } else {
                    Write-Host "     " -NoNewline
                    Write-Host $displayItem.PadRight($listWidth - 5)
                }
            } else {
                # Clear any remaining lines when the list shrinks
                Write-Host "".PadRight($listWidth)
            }
        }

        # Display ellipsis if there are more items
        if ($FilteredItems.Count -gt $displayCount) {
            $Host.UI.RawUI.CursorPosition = @{X=0; Y=($windowHeight - 2)}
            Write-Host "    ..." -ForegroundColor DarkGray
        } else {
            $Host.UI.RawUI.CursorPosition = @{X=0; Y=($windowHeight - 2)}
            Write-Host "".PadRight($listWidth)
        }

        # Display file preview if enabled
        if ($EnablePreview) {
            if ($FilteredItems.Count -gt 0) {
                $selectedItem = $FilteredItems[$script:SelectedIndex].Item
                $previewContent = Get-FilePreview -FilePath $selectedItem -MaxLines ($windowHeight - 7)
                $previewLines = $previewContent -split "`n"

                for ($i = 0; $i -lt ($windowHeight - 6); $i++) {
                    $Host.UI.RawUI.CursorPosition = @{X=$listWidth; Y=($i + 4)}
                    if ($i -lt $previewLines.Count) {
                        Write-Host ($previewLines[$i].PadRight($previewWidth).Substring(0, $previewWidth)) -ForegroundColor Magenta
                    } else {
                        Write-Host "".PadRight($previewWidth)
                    }
                }
            } else {
                # Clear the preview area if there are no matches
                for ($i = 0; $i -lt ($windowHeight - 6); $i++) {
                    $Host.UI.RawUI.CursorPosition = @{X=$listWidth; Y=($i + 4)}
                    Write-Host "".PadRight($previewWidth)
                }
            }
        }
    }

    # Update query line
    $Host.UI.RawUI.CursorPosition = @{X=0; Y=$Host.UI.RawUI.WindowSize.Height - 1}
    Write-Host ">> " -NoNewline
    Write-Host ($script:Query.PadRight($Host.UI.RawUI.WindowSize.Width - 3))
    $Host.UI.RawUI.CursorPosition = @{X=(3 + $script:CursorPosition); Y=$Host.UI.RawUI.WindowSize.Height - 1}
}

function Check-WindowResize {
    param (
        [int]$CurrentHeight,
        [int]$LastHeight
    )
    
    if ($CurrentHeight -ne $LastHeight) {
        $script:WindowHeight = $CurrentHeight
        return $true
    }
    return $false
}