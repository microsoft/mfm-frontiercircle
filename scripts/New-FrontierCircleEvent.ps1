#requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$InputPath,

    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$laneMap = @{
    lab = @{
        Emoji = '🧪'
        Label = 'Lab'
        Name  = 'Build & Skill Labs'
    }
    briefing = @{
        Emoji = '💡'
        Label = 'Briefing'
        Name  = 'Transformation Briefings'
    }
    exchange = @{
        Emoji = '🤝'
        Label = 'Exchange'
        Name  = 'Frontier Exchange'
    }
}

function Get-RequiredText {
    param(
        [object]$InputObject,
        [string]$PropertyName
    )

    $property = $InputObject.PSObject.Properties[$PropertyName]
    if ($null -eq $property) {
        throw "Missing required property '$PropertyName'."
    }

    $value = if ($property.Value -is [DateTime]) {
        $property.Value.ToString('o')
    }
    elseif ($property.Value -is [DateTimeOffset]) {
        $property.Value.ToString('o')
    }
    else {
        [string]$property.Value
    }

    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "Missing required property '$PropertyName'."
    }

    return $value.Trim()
}

function ConvertFrom-OffsetDate {
    param(
        [string]$Value,
        [string]$PropertyName
    )

    if ($Value -notmatch '(?:Z|[+-]\d{2}:\d{2})$') {
        throw "'$PropertyName' must include Z or an explicit UTC offset."
    }

    $parsed = [DateTimeOffset]::MinValue
    if (-not [DateTimeOffset]::TryParse(
        $Value,
        [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::AllowWhiteSpaces,
        [ref]$parsed
    )) {
        throw "'$PropertyName' is not a valid ISO 8601 date and time."
    }

    return $parsed
}

function ConvertTo-IcsText {
    param([string]$Value)

    $escaped = $Value.Replace('\', '\\')
    $escaped = $escaped.Replace(';', '\;')
    $escaped = $escaped.Replace(',', '\,')
    $escaped = $escaped -replace "`r`n|`r|`n", '\n'
    return $escaped
}

function ConvertTo-HtmlText {
    param([string]$Value)

    return [Net.WebUtility]::HtmlEncode($Value)
}

function ConvertTo-IcsLine {
    param([string]$Line)

    $physicalLines = [Collections.Generic.List[string]]::new()
    $current = ''
    $enumerator = [Globalization.StringInfo]::GetTextElementEnumerator($Line)

    while ($enumerator.MoveNext()) {
        $element = $enumerator.GetTextElement()
        $candidate = $current + $element

        if (
            [Text.Encoding]::UTF8.GetByteCount($candidate) -gt 75 -and
            $current.Length -gt 0
        ) {
            $physicalLines.Add($current)
            $current = ' ' + $element
        }
        else {
            $current = $candidate
        }
    }

    if ($current.Length -gt 0) {
        $physicalLines.Add($current)
    }

    return $physicalLines
}

$resolvedInput = (Resolve-Path -LiteralPath $InputPath).Path
$json = Get-Content -LiteralPath $resolvedInput -Raw
$convertFromJsonParameters = @{}
if ((Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) {
    $convertFromJsonParameters.DateKind = 'String'
}
$event = $json | ConvertFrom-Json @convertFromJsonParameters

$id = Get-RequiredText $event 'id'
$laneKey = (Get-RequiredText $event 'lane').ToLowerInvariant()
$title = Get-RequiredText $event 'title'
$timeZoneLabel = Get-RequiredText $event 'timeZoneLabel'
$location = Get-RequiredText $event 'location'
$description = Get-RequiredText $event 'description'
$registrationUrl = Get-RequiredText $event 'registrationUrl'
$start = ConvertFrom-OffsetDate (Get-RequiredText $event 'start') 'start'
$end = ConvertFrom-OffsetDate (Get-RequiredText $event 'end') 'end'
$now = [DateTimeOffset]::UtcNow

if (-not $laneMap.ContainsKey($laneKey)) {
    throw "Unknown lane '$laneKey'. Use lab, briefing, or exchange."
}

if ($id -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
    throw "'id' may contain only letters, numbers, periods, underscores, and hyphens."
}

if ($timeZoneLabel -notmatch '^[A-Za-z0-9 +:/_-]{1,20}$') {
    throw "'timeZoneLabel' contains unsupported characters or is too long."
}

if ($end -le $start) {
    throw "'end' must be later than 'start'."
}

$statusProperty = $event.PSObject.Properties['status']
$status = if (
    $null -ne $statusProperty -and
    -not [string]::IsNullOrWhiteSpace([string]$statusProperty.Value)
) {
    ([string]$statusProperty.Value).Trim()
}
else {
    'Scheduled'
}

if ($status -notin @('Scheduled', 'Completed', 'Cancelled')) {
    throw "'status' must be Scheduled, Completed, or Cancelled."
}

$createdProperty = $event.PSObject.Properties['created']
$created = if (
    $null -ne $createdProperty -and
    -not [string]::IsNullOrWhiteSpace([string]$createdProperty.Value)
) {
    ConvertFrom-OffsetDate (Get-RequiredText $event 'created') 'created'
}
else {
    $now
}

$lastModifiedProperty = $event.PSObject.Properties['lastModified']
$lastModified = if (
    $null -ne $lastModifiedProperty -and
    -not [string]::IsNullOrWhiteSpace([string]$lastModifiedProperty.Value)
) {
    ConvertFrom-OffsetDate (
        Get-RequiredText $event 'lastModified'
    ) 'lastModified'
}
else {
    $created
}

$sequence = 0
$sequenceProperty = $event.PSObject.Properties['sequence']
if ($null -ne $sequenceProperty) {
    if (
        -not [int]::TryParse(
            [string]$sequenceProperty.Value,
            [ref]$sequence
        ) -or
        $sequence -lt 0
    ) {
        throw "'sequence' must be a non-negative integer."
    }
}

$registrationUri = [Uri]$registrationUrl
if (-not $registrationUri.IsAbsoluteUri -or $registrationUri.Scheme -ne 'https') {
    throw "'registrationUrl' must be an absolute HTTPS URL."
}

$publicInput = $event | ConvertTo-Json -Depth 10
$prohibitedPatterns = @(
    'safelinks\.protection\.outlook\.com',
    'Event Request ID',
    'Event management Url',
    'eventsprogramadmin@microsoft\.com',
    'AzureTechEventsRequest',
    'Internal Instructions for Registration Management'
)

foreach ($pattern in $prohibitedPatterns) {
    if ($publicInput -match $pattern) {
        throw "Input contains internal-only content matching '$pattern'."
    }
}

$lane = $laneMap[$laneKey]
$summary = "$($lane.Emoji) $($lane.Label) | $title"
$descriptionParts = [Collections.Generic.List[string]]::new()
$descriptionParts.Add($description)

$topics = @()
$topicsProperty = $event.PSObject.Properties['topics']
if ($null -ne $topicsProperty -and $null -ne $topicsProperty.Value) {
    $topics = @($topicsProperty.Value | ForEach-Object {
        ([string]$_).Trim()
    } | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    })

    if ($topics.Count -gt 0) {
        $descriptionParts.Add(
            "Topics:`n" + (($topics | ForEach-Object { "- $_" }) -join "`n")
        )
    }
}

$audienceProperty = $event.PSObject.Properties['audience']
if (
    $null -ne $audienceProperty -and
    -not [string]::IsNullOrWhiteSpace([string]$audienceProperty.Value)
) {
    $descriptionParts.Add("Audience: $(([string]$audienceProperty.Value).Trim())")
}

$descriptionParts.Add('Registration is required and subject to approval.')
$calendarNotice = 'This series calendar is for discovery, not registration. Entries are marked Free. Register separately for the sessions you want to attend.'
$descriptionParts.Add($calendarNotice)

$deadlineText = $null
$deadlineProperty = $event.PSObject.Properties['registrationDeadline']
if (
    $null -ne $deadlineProperty -and
    -not [string]::IsNullOrWhiteSpace([string]$deadlineProperty.Value)
) {
    $deadline = ConvertFrom-OffsetDate (
        Get-RequiredText $event 'registrationDeadline'
    ) 'registrationDeadline'
    $deadlineText = $deadline.ToString(
        "dddd, MMMM d, yyyy 'at' h:mm tt",
        [Globalization.CultureInfo]::GetCultureInfo('en-US')
    )
    $descriptionParts.Add("Registration closes $deadlineText $timeZoneLabel.")
}

$descriptionParts.Add("Register: $registrationUrl")
$publicDescription = $descriptionParts -join "`n`n"

$culture = [Globalization.CultureInfo]::GetCultureInfo('en-US')
if ($start.Date -eq $end.Date) {
    $eventDateText = $start.ToString('dddd, MMMM d, yyyy', $culture)
    $eventTimeText = (
        $start.ToString('h:mm tt', $culture) +
        '–' +
        $end.ToString('h:mm tt', $culture) +
        " $timeZoneLabel"
    )
}
else {
    $eventDateText = (
        $start.ToString('dddd, MMMM d, yyyy', $culture) +
        '–' +
        $end.ToString('dddd, MMMM d, yyyy', $culture)
    )
    $eventTimeText = (
        $start.ToString('h:mm tt', $culture) +
        '–' +
        $end.ToString('h:mm tt', $culture) +
        " $timeZoneLabel"
    )
}

$encodedLaneName = ConvertTo-HtmlText $lane.Name
$encodedTitle = ConvertTo-HtmlText $title
$encodedDescription = ConvertTo-HtmlText $description
$encodedDescription += '<br><br>' + (ConvertTo-HtmlText $calendarNotice)
$encodedDate = ConvertTo-HtmlText $eventDateText
$encodedTime = ConvertTo-HtmlText $eventTimeText
$encodedLocation = ConvertTo-HtmlText $location
$encodedRegistrationUrl = ConvertTo-HtmlText $registrationUrl

$topicsHtml = ''
if ($topics.Count -gt 0) {
    $topicItems = ($topics | ForEach-Object {
        '<li style="margin:0 0 7px 0;">' +
        (ConvertTo-HtmlText $_) +
        '</li>'
    }) -join ''
    $topicsHtml = @"
<tr><td style="padding:0 28px 22px 28px;"><div style="font-size:16px;font-weight:700;color:#182230;margin:0 0 10px 0;">What participants will do</div><ul style="margin:0;padding:0 0 0 20px;color:#526575;font-size:15px;line-height:1.55;">$topicItems</ul></td></tr>
"@
}

$audienceHtml = ''
if (
    $null -ne $audienceProperty -and
    -not [string]::IsNullOrWhiteSpace([string]$audienceProperty.Value)
) {
    $encodedAudience = ConvertTo-HtmlText (
        ([string]$audienceProperty.Value).Trim()
    )
    $audienceHtml = @"
<tr><td style="padding:0 28px 22px 28px;"><div style="font-size:16px;font-weight:700;color:#182230;margin:0 0 8px 0;">Audience</div><div style="font-size:15px;line-height:1.55;color:#526575;">$encodedAudience</div></td></tr>
"@
}

$deadlineHtml = ''
if (-not [string]::IsNullOrWhiteSpace($deadlineText)) {
    $encodedDeadline = ConvertTo-HtmlText (
        "Registration closes $deadlineText $timeZoneLabel."
    )
    $deadlineHtml = @"
<tr><td style="padding:0 28px 22px 28px;"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="width:100%;background-color:#f7f2fb;border-left:4px solid #d83b7d;"><tr><td style="padding:14px 16px;color:#4a265f;font-size:14px;line-height:1.5;"><strong>Registration is required and subject to approval.</strong><br>$encodedDeadline</td></tr></table></td></tr>
"@
}

$htmlDescription = @"
<!doctype html><html><body style="margin:0;padding:0;background-color:#eef3f5;font-family:'Segoe UI',Arial,sans-serif;color:#182230;"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="width:100%;background-color:#eef3f5;"><tr><td align="center" style="padding:18px 10px;"><table role="presentation" width="680" cellpadding="0" cellspacing="0" border="0" style="width:100%;max-width:680px;background-color:#ffffff;border:1px solid #c8d8de;"><tr><td bgcolor="#5b2c83" style="background-color:#5b2c83;border-left:6px solid #d83b7d;padding:18px 24px;color:#ffffff;"><div style="font-size:13px;font-weight:700;letter-spacing:1px;text-transform:uppercase;">$($lane.Emoji) $encodedLaneName</div><div style="font-size:14px;margin-top:5px;color:#f4eefa;">Manufacturing &amp; Mobility Frontier Circle</div></td></tr><tr><td style="padding:26px 28px 16px 28px;"><div style="font-size:27px;line-height:1.16;font-weight:700;color:#182230;">$encodedTitle</div><div style="margin-top:14px;font-size:16px;line-height:1.6;color:#526575;">$encodedDescription</div></td></tr><tr><td style="padding:0 28px 24px 28px;"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="width:100%;border-top:1px solid #c8d8de;border-bottom:1px solid #c8d8de;"><tr><td width="42%" valign="top" style="padding:14px 12px 14px 0;"><div style="font-size:11px;font-weight:700;letter-spacing:0.8px;color:#5b2c83;">DATE</div><div style="margin-top:5px;font-size:14px;font-weight:600;color:#182230;">$encodedDate</div></td><td width="30%" valign="top" style="padding:14px 12px;border-left:1px solid #c8d8de;"><div style="font-size:11px;font-weight:700;letter-spacing:0.8px;color:#5b2c83;">TIME</div><div style="margin-top:5px;font-size:14px;font-weight:600;color:#182230;">$encodedTime</div></td><td width="28%" valign="top" style="padding:14px 0 14px 12px;border-left:1px solid #c8d8de;"><div style="font-size:11px;font-weight:700;letter-spacing:0.8px;color:#5b2c83;">LOCATION</div><div style="margin-top:5px;font-size:14px;font-weight:600;color:#182230;">$encodedLocation</div></td></tr></table></td></tr>$topicsHtml$audienceHtml$deadlineHtml<tr><td style="padding:0 28px 30px 28px;"><table role="presentation" cellpadding="0" cellspacing="0" border="0"><tr><td bgcolor="#5b2c83" style="background-color:#5b2c83;padding:12px 18px;"><a href="$encodedRegistrationUrl" style="color:#ffffff;text-decoration:none;font-size:15px;font-weight:700;">Register for this event</a></td></tr></table><div style="margin-top:12px;font-size:12px;line-height:1.45;color:#667684;">If the button does not open, use: <a href="$encodedRegistrationUrl" style="color:#5b2c83;">$encodedRegistrationUrl</a></div></td></tr></table></td></tr></table></body></html>
"@
$htmlDescription = (
    ($htmlDescription -replace "`r`n|`r|`n", '') -replace '>\s+<', '><'
).Trim()

$icsStatus = if ($status -eq 'Cancelled') { 'CANCELLED' } else { 'CONFIRMED' }
$transparency = 'TRANSPARENT'
$busyStatus = 'FREE'

$logicalLines = @(
    'BEGIN:VCALENDAR'
    'VERSION:2.0'
    'PRODID:-//Microsoft//Manufacturing and Mobility Frontier Circle//EN'
    'CALSCALE:GREGORIAN'
    'METHOD:PUBLISH'
    'X-WR-CALNAME:Manufacturing & Mobility Frontier Circle'
    'BEGIN:VEVENT'
    "UID:$id@mfm-frontiercircle.microsoft.com"
    "DTSTAMP:$($lastModified.UtcDateTime.ToString("yyyyMMdd'T'HHmmss'Z'"))"
    "CREATED:$($created.UtcDateTime.ToString("yyyyMMdd'T'HHmmss'Z'"))"
    "LAST-MODIFIED:$($lastModified.UtcDateTime.ToString("yyyyMMdd'T'HHmmss'Z'"))"
    "DTSTART:$($start.UtcDateTime.ToString("yyyyMMdd'T'HHmmss'Z'"))"
    "DTEND:$($end.UtcDateTime.ToString("yyyyMMdd'T'HHmmss'Z'"))"
    "SUMMARY:$(ConvertTo-IcsText $summary)"
    "LOCATION:$(ConvertTo-IcsText $location)"
    "DESCRIPTION:$(ConvertTo-IcsText $publicDescription)"
    "X-ALT-DESC;FMTTYPE=text/html:$(ConvertTo-IcsText $htmlDescription)"
    "URL:$registrationUrl"
    "CATEGORIES:$($lane.Name),Frontier Circle"
    'CLASS:PUBLIC'
    "STATUS:$icsStatus"
    "TRANSP:$transparency"
    "SEQUENCE:$sequence"
    "X-MICROSOFT-CDO-BUSYSTATUS:$busyStatus"
    'END:VEVENT'
    'END:VCALENDAR'
)

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $slug = $title.ToLowerInvariant() -replace '[^a-z0-9]+', '-'
    $slug = $slug.Trim('-')
    $fileName = '{0}-{1}-{2}.ics' -f $start.ToString('yyyy-MM-dd'), $laneKey, $slug
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $OutputPath = Join-Path (Join-Path $repoRoot 'calendar-drafts') $fileName
}

$physicalLines = [Collections.Generic.List[string]]::new()
foreach ($line in $logicalLines) {
    foreach ($physicalLine in (ConvertTo-IcsLine $line)) {
        $physicalLines.Add($physicalLine)
    }
}

$content = ($physicalLines -join "`r`n") + "`r`n"
$resolvedOutput = [IO.Path]::GetFullPath($OutputPath)
$outputDirectory = Split-Path -Parent $resolvedOutput
if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

[IO.File]::WriteAllText(
    $resolvedOutput,
    $content,
    [Text.UTF8Encoding]::new($false)
)

$writtenLines = [IO.File]::ReadAllLines($resolvedOutput)
$overlongLines = @($writtenLines | Where-Object {
    [Text.Encoding]::UTF8.GetByteCount($_) -gt 75
})

if ($overlongLines.Count -gt 0) {
    throw "Generated file contains $($overlongLines.Count) line(s) over 75 bytes."
}

[pscustomobject]@{
    Path          = $resolvedOutput
    Lane          = $lane.Name
    Summary       = $summary
    Status        = $status
    Sequence      = $sequence
    Start         = $start
    End           = $end
    DurationHours = ($end - $start).TotalHours
    Registration  = $registrationUrl
}
