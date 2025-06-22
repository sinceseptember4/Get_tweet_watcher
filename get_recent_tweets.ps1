[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Load Bearer Token
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
Write-Host "Bearer token loaded."

# Load User list from CSV
$csvPath = "$PSScriptRoot\userId_result.csv"
if (!(Test-Path $csvPath)) {
    Write-Host "❌ Error: userId_result.csv not found at $csvPath"
    exit
}

$userList = Import-Csv -Path $csvPath

# Function to get recent tweets
function Get-RecentTweets {
    param ($username, $userId)

    $url = "https://api.twitter.com/2/users/$userId/tweets?max_results=10&tweet.fields=created_at"
    $headers = @{ Authorization = "Bearer $bearerToken" }

    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -ErrorAction Stop
    } catch {
        Write-Host "$username → API Error: $($_.Exception.Message)"
        return @()
    }

    $threeDaysAgo = (Get-Date).AddDays(-3)
    $recentTweets = @()

    foreach ($tweet in $response.data) {
        $createdAt = [datetime]$tweet.created_at
        if ($createdAt -ge $threeDaysAgo) {
            $recentTweets += [PSCustomObject]@{
                Username   = $username
                CreatedAt  = $createdAt.ToString("yyyy/MM/dd HH:mm:ss")
                TweetUrl   = "https://twitter.com/$username/status/$($tweet.id)"
            }
        } else {
            break
        }
    }

    return $recentTweets
}

# Collect tweets
$tweetList = @()

foreach ($user in $userList) {
    if ([string]::IsNullOrWhiteSpace($user.UserId) -or [string]::IsNullOrWhiteSpace($user.Username)) {
        Write-Host "⚠️ Skipping user with missing data: $($user | Out-String)"
        continue
    }

    Write-Host "Getting tweets for: $($user.Username)..."
    $tweets = Get-RecentTweets -username $user.Username -userId $user.UserId
    $tweetList += $tweets
    Start-Sleep -Seconds 6
}

# Export result
$csvOutputPath = "$PSScriptRoot\tweet_result.csv"
$tweetList | Export-Csv -Path $csvOutputPath -NoTypeInformation -Encoding UTF8
Write-Host "✅ Tweet export complete → $csvOutputPath"
