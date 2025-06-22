[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

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

$csvPath = "$PSScriptRoot\userId_result.csv"
if (!(Test-Path $csvPath)) {
    Write-Host "Error: CSV file not found -> $csvPath"
    exit
}

$userList = Import-Csv -Path $csvPath

function Get-RecentTweets {
    param ($username, $userId)

    $url = "https://api.twitter.com/2/users/$userId/tweets?max_results=10&tweet.fields=created_at"
    $headers = @{ Authorization = "Bearer $bearerToken" }

    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -ErrorAction Stop
    } catch {
        Write-Host "$username → API failed: $($_.Exception.Message)"
        return @()
    }

    $threeDaysAgo = (Get-Date).AddDays(-3)
    $recentTweets = @()

    foreach ($tweet in $response.data) {
        $createdAt = [datetime]$tweet.created_at
        if ($createdAt -ge $threeDaysAgo) {
            $recentTweets += [PSCustomObject]@{
                Username = $username
                CreatedAt = $createdAt
                URL = "https://twitter.com/$username/status/$($tweet.id)"
            }
        } else {
            break
        }
    }

    return $recentTweets
}

$tweetList = @()

foreach ($user in $userList) {
    if ([string]::IsNullOrWhiteSpace($user.UserId)) {
        Write-Host "UserId is empty for: $($user.Username)"
        continue
    }
    Write-Host "Fetching tweets for $($user.Username)..."
    $tweets = Get-RecentTweets -username $user.Username -userId $user.UserId
    $tweetList += $tweets
    Start-Sleep -Seconds 6  # API rate limit protection
}

$csvOutputPath = "$PSScriptRoot\tweet_result.csv"
$tweetList | Export-Csv -Path $csvOutputPath -NoTypeInformation -Encoding UTF8
Write-Host "✅ Tweet CSV export completed → $csvOutputPath"
