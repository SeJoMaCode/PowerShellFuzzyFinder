function Handle-KeyPress {
    param (
        [System.Management.Automation.Host.KeyInfo]$Key,
        [string]$Query,
        [int]$CursorPosition,
        [int]$SelectedIndex,
        [int]$ScrollOffset,
        [array]$FilteredItems
    )

    $result = @{
        Query = $Query
        CursorPosition = $CursorPosition
        SelectedIndex = $SelectedIndex
        ScrollOffset = $ScrollOffset
        UpdateRequired = $false
        Exit = $false
        ReturnValue = $null
    }

    switch ($Key.VirtualKeyCode) {
        27 { # Esc key
            $result.Exit = $true
            $result.ReturnValue = $null
        }
        13 { # Enter key
            $result.Exit = $true
            $result.ReturnValue = if ($FilteredItems.Count -gt 0) { $FilteredItems[$SelectedIndex]["Item"] } else { $null }
        }
        9 { # Tab key
            if ($FilteredItems.Count -gt 0) {
                $result.SelectedIndex = Get-NextIndex -CurrentIndex $SelectedIndex -TotalCount $FilteredItems.Count -Direction 1
                $result.ScrollOffset = Update-ScrollOffset -SelectedIndex $result.SelectedIndex -ScrollOffset $ScrollOffset -WindowHeight $Host.UI.RawUI.WindowSize.Height
                $result.UpdateRequired = $true
            }
        }
        38 { # Up arrow
            if ($FilteredItems.Count -gt 0) {
                $result.SelectedIndex = Get-NextIndex -CurrentIndex $SelectedIndex -TotalCount $FilteredItems.Count -Direction -1
                $result.ScrollOffset = Update-ScrollOffset -SelectedIndex $result.SelectedIndex -ScrollOffset $ScrollOffset -WindowHeight $Host.UI.RawUI.WindowSize.Height
                $result.UpdateRequired = $true
            }
        }
        40 { # Down arrow
            if ($FilteredItems.Count -gt 0) {
                $result.SelectedIndex = Get-NextIndex -CurrentIndex $SelectedIndex -TotalCount $FilteredItems.Count -Direction 1
                $result.ScrollOffset = Update-ScrollOffset -SelectedIndex $result.SelectedIndex -ScrollOffset $ScrollOffset -WindowHeight $Host.UI.RawUI.WindowSize.Height
                $result.UpdateRequired = $true
            }
        }
        37 { # Left arrow
            if ($CursorPosition -gt 0) {
                $result.CursorPosition--
                $Host.UI.RawUI.CursorPosition = @{X=(3 + $result.CursorPosition); Y=($Host.UI.RawUI.WindowSize.Height - 1)}
            }
        }
        39 { # Right arrow
            if ($CursorPosition -lt $Query.Length) {
                $result.CursorPosition++
                $Host.UI.RawUI.CursorPosition = @{X=(3 + $result.CursorPosition); Y=($Host.UI.RawUI.WindowSize.Height - 1)}
            }
        }
        8 { # Backspace key
            if ($CursorPosition -gt 0) {
                $result.Query = $Query.Remove($CursorPosition - 1, 1)
                $result.CursorPosition--
                $result.SelectedIndex = 0
                $result.ScrollOffset = 0
                $result.UpdateRequired = $true
            }
        }
        46 { # Delete key
            if ($CursorPosition -lt $Query.Length) {
                $result.Query = $Query.Remove($CursorPosition, 1)
                $result.SelectedIndex = 0
                $result.ScrollOffset = 0
                $result.UpdateRequired = $true
            }
        }
        default {
            if ($null -ne $Key.Character -and 0 -ne $Key.Character) {
                $result.Query = $Query.Insert($CursorPosition, $Key.Character)
                $result.CursorPosition++
                $result.UpdateRequired = $true
            }
        }
    }

    return $result
}

function Get-KeyPress {
    if ([Console]::KeyAvailable) {
        $key = $null
        $continueReading = $true
        while ($continueReading -and [Console]::KeyAvailable) {
            $key = $Host.UI.RawUI.ReadKey("IncludeKeyDown,NoEcho")
            if (-not [Console]::KeyAvailable) {
                $continueReading = $false
            }
        }
        return $key
    }
    return $null
}