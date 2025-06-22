# Replace with your own Bearer Token
$envFilePath = "$PSScriptRoot\.env"

function Load-EnvFile {
    param ($filePath)
    $envVars = @{}
    Get-Content $filePath | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            $envVars[$key] = $value
        }
    }
    return $envVars
}

$env = Load-EnvFile -filePath $envFilePath
$bearerToken = $env["BEARER_TOKEN"].Trim()
Write-Host "BEARER_TOKEN='$bearerToken'"

# List of URLs to check (change as needed)
$urls = @(
    "https://twitter.com/elonmusk/status/1936663418456732069",
    "https://twitter.com/BarackObama/status/1936571693746753674",
    "https://twitter.com/nasa/status/1936548151370056073"
)

# Function to get UserId by username
function Get-UserId {
    param ($username)

    $url = "https://api.twitter.com/2/users/by/username/$username"
    $headers = @{ Authorization = "Bearer $bearerToken" }

    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -ErrorAction Stop
        return $response.data.id
    } catch {
        Write-Host "Error: Failed to get ID for $username → $($_.Exception.Message)"
        return $null
    }
}

# Extract username from URL
function Extract-Username {
    param ($url)
    if ($url -match "twitter\.com/([^/]+)/status") {
        return $matches[1]
    }
    return $null
}

$csvPath = "$PSScriptRoot\userId_result.csv"
if (Test-Path $csvPath) { Remove-Item $csvPath }

# List to store UserId data
$userIdList = @()

# Main process
foreach ($url in $urls) {
    $username = Extract-Username -url $url
    if ($username) {
        $userId = Get-UserId -username $username
        Write-Host "User: $username, ID: $userId"

        $userIdList += [PSCustomObject]@{
            UserId = $userId
        }
    } else {
        Write-Host "Invalid URL format: $url"
    }
    Start-Sleep -Seconds 3  # To avoid hitting API limits
}

# Export UserId only to CSV
$userIdList | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
Write-Host "✅ CSV export done → $csvPath"
