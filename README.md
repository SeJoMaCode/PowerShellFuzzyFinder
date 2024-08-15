# FuzzyFinder

FuzzyFinder is a PowerShell-based tool that provides fast and intuitive file searching capabilities within a specified directory structure. It offers a user-friendly interface for quickly locating files using fuzzy matching algorithms.

## Features

- Fast fuzzy search for files and directories
- Real-time results as you type
- Customizable search depth and excluded directories
- File preview functionality (optional)
- Background indexing for improved performance

## Prerequisites

- PowerShell 5.1 or higher

## Installation

### Quick Start (Local Use)

1. Clone this repository or download the source files:
   ```
   git clone https://github.com/SeJoMaCode/PowerShellFuzzyFinder.git
   ```
2. Navigate to the project directory:
   ```
   cd FuzzyFinder
   ```

### Persistent Installation (Recommended)

To make FuzzyFinder available across all PowerShell sessions:

1. Determine your PowerShell module path:
   ```powershell
   $moduleDir = ($env:PSModulePath -split ';')[0]
   ```

2. Create a new directory for FuzzyFinder in your module path:
   ```powershell
   New-Item -Path "$moduleDir\FuzzyFinder" -ItemType Directory -Force
   ```

3. Copy all the script files to the new module directory:
   ```powershell
   Copy-Item -Path "path\to\FuzzyFinder\*.ps1" -Destination "$moduleDir\FuzzyFinder"
   ```

4. Create a module manifest file:
   ```powershell
   New-ModuleManifest -Path "$moduleDir\FuzzyFinder\FuzzyFinder.psd1" -RootModule "Invoke-FuzzyFinder.ps1" -FunctionsToExport "Invoke-FuzzyFinder"
   ```

5. Import the module to test the installation:
   ```powershell
   Import-Module FuzzyFinder
   ```

Now you can use `Invoke-FuzzyFinder` from any location in PowerShell. To make it automatically available in all new PowerShell sessions, add the following line to your PowerShell profile:

```powershell
Import-Module FuzzyFinder
```

To edit your PowerShell profile:
```powershell
notepad $PROFILE
```

## Usage

After installation, you can use FuzzyFinder by running:

```powershell
Invoke-FuzzyFinder
```

### Parameters

- `-MaxDepth`: Set the maximum depth for directory traversal (default: 5)
- `-ExcludedDirectories`: Specify directories to exclude from the search (default: '.git', 'node_modules', 'bin', 'obj')
- `-EnablePreview`: Enable file preview functionality (default: false)

Example:
```powershell
Invoke-FuzzyFinder -MaxDepth 3 -ExcludedDirectories @('.git', 'node_modules', 'dist') -EnablePreview
```

## Project Structure

- `Invoke-FuzzyFinder.ps1`: Main script file
- `Indexing.ps1`: File indexing functionality
- `Display.ps1`: User interface and display functions
- `Filtering.ps1`: Search and filtering logic
- `KeyHandling.ps1`: Keyboard input handling

## How It Works

1. The tool starts by indexing files in the background within the specified directory structure.
2. As you type, it filters the indexed files using fuzzy matching algorithms.
3. Results are displayed in real-time, allowing for quick navigation and selection.
4. Use arrow keys to navigate, Enter to select a file, and Esc to exit.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
