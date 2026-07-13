# WAYK Backend - Full API Test Script

$base = "http://localhost:8080/api"

Write-Host "`n===== LOGIN =====" -ForegroundColor Cyan
$loginBody = @{ email = "gujaratharva021@gmail.com"; password = "123456" } | ConvertTo-Json
try {
    $auth = Invoke-RestMethod -Uri "$base/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    $token = $auth.token
    Write-Host "Login OK. User: $($auth.user.name)" -ForegroundColor Green
} catch {
    Write-Host "LOGIN FAILED: $_" -ForegroundColor Red
    exit
}
$headers = @{ Authorization = "Bearer $token" }

function Test-Endpoint($name, $method, $url, $body = $null) {
    Write-Host "`n----- $name -----" -ForegroundColor Yellow
    try {
        if ($body) {
            $jsonBody = $body | ConvertTo-Json
            $result = Invoke-RestMethod -Uri $url -Method $method -Body $jsonBody -ContentType "application/json" -Headers $headers
        } else {
            $result = Invoke-RestMethod -Uri $url -Method $method -Headers $headers
        }
        Write-Host "OK" -ForegroundColor Green
        $result | ConvertTo-Json -Depth 4 -Compress | Write-Host
    } catch {
        Write-Host "FAILED: $_" -ForegroundColor Red
    }
}

Test-Endpoint "Dashboard" "GET" "$base/health/dashboard"
Test-Endpoint "Rewards Status" "GET" "$base/rewards/status"
Test-Endpoint "Water Today" "GET" "$base/water/today"
Test-Endpoint "Log Water" "POST" "$base/water/log" @{ amount_ml = 250 }

Test-Endpoint "List Alarms" "GET" "$base/alarm/list"
Test-Endpoint "Today Triggers" "GET" "$base/alarm/triggers/today"

Test-Endpoint "BP Logs" "GET" "$base/health/bp/logs"
Test-Endpoint "Sugar Logs" "GET" "$base/health/sugar/logs"

Test-Endpoint "Medicines" "GET" "$base/medicine/list"
Test-Endpoint "Medicine Logs Today" "GET" "$base/medicine/logs/today"

Test-Endpoint "Meal Plan" "GET" "$base/meal/plan"
Test-Endpoint "Exercise Plan" "GET" "$base/exercise/plan"
Test-Endpoint "Grocery List" "GET" "$base/grocery/list"

Test-Endpoint "BMI Calc" "POST" "$base/calc/bmi" @{ height_cm = 175; weight_kg = 70 }
Test-Endpoint "Calorie Calc" "POST" "$base/calc/calories" @{ age = 25; gender = "male"; height_cm = 175; weight_kg = 70; activity_level = "moderate" }

Test-Endpoint "Recipes" "GET" "$base/recipes/suggest"

Test-Endpoint "Analytics Summary" "GET" "$base/analytics/summary?days=30"
Test-Endpoint "BP Trend" "GET" "$base/analytics/bp/trend?days=30"
Test-Endpoint "Sugar Trend" "GET" "$base/analytics/sugar/trend?days=30"

Test-Endpoint "AI Chat" "POST" "$base/ai/chat" @{ message = "Give me one quick health tip" }

Test-Endpoint "Leaderboard" "GET" "$base/community/leaderboard"

Test-Endpoint "SOS Contacts" "GET" "$base/sos/contacts"

Test-Endpoint "Wearable Today" "GET" "$base/wearable/today"
Test-Endpoint "Wearable Sync" "POST" "$base/wearable/sync" @{ source = "manual"; steps = 5000; heart_rate_bpm = 72; calories_burned = 200 }

Write-Host "`n===== DONE =====" -ForegroundColor Cyan
