Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

# ============================================================
# Humanize function — returns [PSCustomObject]@{ Text; Summary }
# ============================================================
function Convert-AIText {
    param(
        [string]$Text,
        [bool]$RemoveMarkdown,
        [bool]$RemoveEmoji
    )

    $t = $Text
    $counts = @{}

    # --- Zero-width / invisible characters ---
    $invisCount = ([regex]::Matches($t, '[\u200B\u200C\u200D\uFEFF\u2060\u00AD\u200E\u200F]')).Count
    $t = $t -replace '[\u200B\u200C\u200D\uFEFF\u2060\u00AD\u200E\u200F]', ''
    if ($invisCount -gt 0) { $counts['Invisible chars removed'] = $invisCount }

    # --- Fancy spaces → regular space ---
    $spacesCount = ([regex]::Matches($t, '[\u00A0\u2009\u200A\u2007\u202F\u205F\u3000\u2002\u2003]')).Count
    $t = $t -replace '[\u00A0\u2009\u200A\u2007\u202F\u205F\u3000\u2002\u2003]', ' '
    if ($spacesCount -gt 0) { $counts['Fancy spaces replaced'] = $spacesCount }

    # --- Dashes ---
    $emDashCount = ([regex]::Matches($t, '\u2014|\u2015')).Count
    $enDashCount = ([regex]::Matches($t, '\u2013|\u2012|\u2212')).Count
    $t = $t -replace '\u2014', '-'
    $t = $t -replace '\u2015', '-'
    $t = $t -replace '\u2013', '-'
    $t = $t -replace '\u2012', '-'
    $t = $t -replace '\u2212', '-'
    if ($emDashCount -gt 0) { $counts['Em dashes (-)']  = $emDashCount }
    if ($enDashCount -gt 0) { $counts['En dashes (-)']  = $enDashCount }

    # --- Quotes ---
    $dqCount = ([regex]::Matches($t, '\u201C|\u201D|\u201E|\u201F|\u00AB|\u00BB')).Count
    $sqCount = ([regex]::Matches($t, '\u2018|\u2019|\u201A|\u201B|\u2039|\u203A')).Count
    $t = $t -replace '[\u201C\u201D\u201E\u201F\u00AB\u00BB]', '"'
    $t = $t -replace '[\u2018\u2019\u201A\u201B\u2039\u203A]', "'"
    if ($dqCount -gt 0) { $counts['Curly double quotes'] = $dqCount }
    if ($sqCount -gt 0) { $counts['Curly single quotes'] = $sqCount }

    # --- Ellipsis ---
    $ellCount    = ([regex]::Matches($t, '\u2026')).Count
    $t = $t -replace '\u2026', '...'
    if ($ellCount    -gt 0) { $counts['Ellipsis (...)']    = $ellCount }

    # --- Bullets ---
    $bulletCount = ([regex]::Matches($t, '[\u2022\u2023\u25E6\u2043\u2219]')).Count
    $t = $t -replace '[\u2022\u2023\u25E6\u2043\u2219]', '-'
    if ($bulletCount -gt 0) { $counts['Bullet chars']      = $bulletCount }

    # --- Arrows used as bullets ---
    $arrowCount  = ([regex]::Matches($t, '[\u2192\u2794\u27A4\u25B8\u25B9\u25BA]')).Count
    $t = $t -replace '[\u2192\u2794\u27A4]', '->'
    $t = $t -replace '[\u25B8\u25B9\u25BA]', '-'
    if ($arrowCount  -gt 0) { $counts['Decorative arrows'] = $arrowCount }

    # --- Markdown removal ---
    if ($RemoveMarkdown) {
        $lenBefore = $t.Length
        $t = $t -replace '(?m)^```[^\r\n]*\r?\n', ''
        $t = $t -replace '(?m)^```\s*$', ''
        $t = $t -replace '`([^`]+)`', '$1'
        $t = $t -replace '!\[([^\]]*)\]\([^\)]+\)', '$1'
        $t = $t -replace '\[([^\]]+)\]\(([^\)]+)\)', '$1 ($2)'
        $t = $t -replace '\*{3}(.+?)\*{3}', '$1'
        $t = $t -replace '_{3}(.+?)_{3}', '$1'
        $t = $t -replace '\*{2}(.+?)\*{2}', '$1'
        $t = $t -replace '_{2}(.+?)_{2}', '$1'
        $t = $t -replace '(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)', '$1'
        $t = $t -replace '(?<=\s|^)_(.+?)_(?=\s|$|[.,;:!?])', '$1'
        $t = $t -replace '~~(.+?)~~', '$1'
        $t = $t -replace '(?m)^#{1,6}\s+', ''
        $t = $t -replace '(?m)^>\s?', ''
        $t = $t -replace '(?m)^[-*_]{3,}\s*$', ''
        $mdRemoved = $lenBefore - $t.Length
        if ($mdRemoved -gt 0) { $counts['Markdown syntax removed'] = $mdRemoved }
    }

    # --- Emoji removal ---
    if ($RemoveEmoji) {
        $lenBefore = $t.Length
        $bmpPattern = '[\u2600-\u27BF\uFE00-\uFE0F\u231A\u231B\u23E9-\u23F3\u23F8-\u23FA' +
            '\u25AA\u25AB\u25FB-\u25FE\u2614\u2615\u2648-\u2653\u2702-\u27B0' +
            '\u2934\u2935\u3030\u303D\u3297\u3299\u200D\u20E3]'
        $t = [regex]::Replace($t, $bmpPattern, '')
        $t = [regex]::Replace($t, '[\uD83C-\uD83F][\uDC00-\uDFFF]', '')
        $t = [regex]::Replace($t, '\uDB40[\uDC20-\uDC7F]+', '')
        $t = [regex]::Replace($t, '\uFE0F', '')
        $emojiRemoved = $lenBefore - $t.Length
        if ($emojiRemoved -gt 0) { $counts['Emoji removed'] = $emojiRemoved }
    }

    # --- Clean up extra whitespace ---
    $t = $t -replace '  +', ' '
    $t = $t -replace '(\r?\n){3,}', "`r`n`r`n"

    # Build summary string
    $relevant = $counts.GetEnumerator() | Where-Object { $_.Value -gt 0 } |
        Sort-Object Name |
        ForEach-Object { "$($_.Key): $($_.Value)" }

    $summary = if ($relevant) {
        "Changes -- " + ($relevant -join "  |  ")
    } else {
        "No AI-specific characters found."
    }

    return [PSCustomObject]@{ Text = $t; Summary = $summary }
}

# ============================================================
# AI Detection function
# ============================================================
function Test-AIText {
    param([string]$Text)

    $score  = 0
    $finds  = [System.Collections.Generic.List[string]]::new()

    # --- Unicode telltales ---
    $emDash  = ([regex]::Matches($Text, '\u2014|\u2015')).Count
    $enDash  = ([regex]::Matches($Text, '\u2013')).Count
    $curly   = ([regex]::Matches($Text, '[\u2018\u2019\u201C\u201D]')).Count
    $ellip   = ([regex]::Matches($Text, '\u2026')).Count
    $zwsp    = ([regex]::Matches($Text, '[\u200B\u200C\u200D\uFEFF\u2060]')).Count
    $nbsp    = ([regex]::Matches($Text, '\u00A0')).Count

    if ($emDash -gt 0) { $score += [Math]::Min(30, $emDash * 10)
                         $finds.Add("em dash x$emDash") }
    if ($enDash -gt 0) { $score += [Math]::Min(15, $enDash * 5)
                         $finds.Add("en dash x$enDash") }
    if ($curly  -gt 0) { $score += [Math]::Min(20, $curly * 4)
                         $finds.Add("curly quotes x$curly") }
    if ($ellip  -gt 0) { $score += [Math]::Min(15, $ellip * 5)
                         $finds.Add("ellipsis char x$ellip") }
    if ($zwsp   -gt 0) { $score += 25; $finds.Add("zero-width chars x$zwsp") }
    if ($nbsp   -gt 0) { $score += 10; $finds.Add("non-breaking spaces x$nbsp") }

    # --- Markdown in plain text ---
    if ($Text -match '(?m)^#{1,6}\s') {
        $score += 20; $finds.Add('Markdown headers')
    }
    if ($Text -match '\*\*.+?\*\*|__.+?__') {
        $score += 15; $finds.Add('Markdown bold')
    }

    # --- Common AI phrase patterns (case-insensitive) ---
    $aiPhrases = [ordered]@{
        'delve'                     = 15
        'it(?:''s| is) worth noting'= 20
        'it(?:''s| is) important to note' = 20
        'in conclusion'             = 12
        'in summary'                = 10
        'to summarize'              = 10
        '\bfurthermore\b'           = 8
        '\bmoreover\b'              = 8
        '\badditionally\b'          = 6
        '\bnevertheless\b'          = 6
        'as an ai'                  = 40
        'i cannot'                  = 15
        'i''m unable to'            = 15
        'please note that'          = 12
        'feel free to'              = 10
        '\bcertainly[!,]'           = 12
        '\babsolutely[!,]'          = 10
        'great question'            = 20
        'i(?:''d| would) be happy to' = 15
        '\bnuanced\b'               = 8
        '\bcomprehensive\b'         = 6
        '\brobust\b'                = 5
        '\bseamlessly\b'            = 8
        '\bpivotal\b'               = 8
        '\bcrucial\b'               = 6
        '\bleverag(?:e|ing)\b'      = 6
        '\bmultifaceted\b'          = 12
        '\bparadigm\b'              = 8
        '\btapestry\b'              = 15
        '\blandscape\b'             = 5
        '\bunderscores? the\b'      = 8
        'at the end of the day'     = 8
        'the fact of the matter'    = 8
    }

    $phraseHits = @()
    foreach ($kv in $aiPhrases.GetEnumerator()) {
        if ([regex]::IsMatch($Text, $kv.Key, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            $displayPhrase = $kv.Key -replace '\\b|[?:''\\(|)]', '' -replace '\s+', ' '
            $phraseHits += $displayPhrase.Trim()
            $score += $kv.Value
        }
    }
    if ($phraseHits.Count -gt 0) {
        $finds.Add('AI phrases: "' + ($phraseHits -join '", "') + '"')
    }

    # --- Structural signals ---
    $words = ($Text -split '\s+' | Where-Object { $_ }).Count
    if ($words -gt 10) {
        # Sentences starting with transitional words
        $transCount = ([regex]::Matches($Text,
            '(?i)(?<=[.!?]\s{1,3}|^\s*)(However|Furthermore|Moreover|Additionally|Nevertheless|Consequently|Therefore|Thus),\s'
        )).Count
        if ($transCount -ge 2) { $score += $transCount * 5
                                  $finds.Add("$transCount transition openers") }

        # Very uniform sentence length (low std-dev relative to mean) — AI tends to write evenly
        $sentences = [regex]::Split($Text.Trim(), '(?<=[.!?])\s+') |
            Where-Object { $_.Length -gt 10 }
        if ($sentences.Count -ge 4) {
            $lens   = $sentences | ForEach-Object { $_.Split(' ').Count }
            $mean   = ($lens | Measure-Object -Average).Average
            $sq     = ($lens | ForEach-Object { ($_ - $mean) * ($_ - $mean) })
            $stddev = [Math]::Sqrt(($sq | Measure-Object -Sum).Sum / $sq.Count)
            $cv     = if ($mean -gt 0) { $stddev / $mean } else { 1 }
            if ($cv -lt 0.25) { $score += 15; $finds.Add('very uniform sentence length') }
            elseif ($cv -lt 0.40) { $score += 8 }
        }
    }

    # --- Determine confidence label ---
    $score = [Math]::Min($score, 100)
    $label = switch ($true) {
        ($score -ge 60) { 'HIGH';   break }
        ($score -ge 30) { 'MEDIUM'; break }
        ($score -ge 10) { 'LOW';    break }
        default         { 'UNLIKELY' }
    }

    $detail = if ($finds.Count -gt 0) { $finds -join '  |  ' } else { 'no strong signals detected' }
    return "AI likelihood: $label (score $score/100) -- $detail"
}

# ============================================================
# Main Form
# ============================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "AI Text Humanizer"
$form.Size = New-Object System.Drawing.Size(800, 740)
$form.StartPosition = "CenterScreen"
$form.MinimumSize = New-Object System.Drawing.Size(620, 520)
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# --- Input Label ---
$lblInput = New-Object System.Windows.Forms.Label
$lblInput.Text = "Paste AI text here:"
$lblInput.AutoSize = $true
$form.Controls.Add($lblInput)

# --- Input TextBox ---
$txtInput = New-Object System.Windows.Forms.TextBox
$txtInput.Multiline = $true
$txtInput.ScrollBars = "Vertical"
$txtInput.AcceptsReturn = $true
$txtInput.AcceptsTab = $true
$txtInput.WordWrap = $true
$txtInput.Anchor = "Top,Left,Right"
$form.Controls.Add($txtInput)

# --- Options Panel (fixed height, manual layout inside) ---
$pnlOptions = New-Object System.Windows.Forms.Panel
$pnlOptions.Height = 36
$pnlOptions.Anchor = "Top,Left,Right"
$form.Controls.Add($pnlOptions)

$btnDetect = New-Object System.Windows.Forms.Button
$btnDetect.Text = "Detect AI"
$btnDetect.Size = New-Object System.Drawing.Size(100, 28)
$btnDetect.BackColor = [System.Drawing.Color]::FromArgb(107, 70, 193)
$btnDetect.ForeColor = [System.Drawing.Color]::White
$btnDetect.FlatStyle = "Flat"
$btnDetect.Location = New-Object System.Drawing.Point(0, 4)
$pnlOptions.Controls.Add($btnDetect)

$chkMarkdown = New-Object System.Windows.Forms.CheckBox
$chkMarkdown.Text = "Remove Markdown"
$chkMarkdown.AutoSize = $true
$chkMarkdown.Location = New-Object System.Drawing.Point(114, 8)
$pnlOptions.Controls.Add($chkMarkdown)

$chkEmoji = New-Object System.Windows.Forms.CheckBox
$chkEmoji.Text = "Remove Emoji"
$chkEmoji.AutoSize = $true
$chkEmoji.Location = New-Object System.Drawing.Point(272, 8)
$pnlOptions.Controls.Add($chkEmoji)

$btnHumanize = New-Object System.Windows.Forms.Button
$btnHumanize.Text = "Humanize"
$btnHumanize.Size = New-Object System.Drawing.Size(100, 28)
$btnHumanize.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
$btnHumanize.ForeColor = [System.Drawing.Color]::White
$btnHumanize.FlatStyle = "Flat"
$btnHumanize.Location = New-Object System.Drawing.Point(390, 4)
$pnlOptions.Controls.Add($btnHumanize)

$btnCopy = New-Object System.Windows.Forms.Button
$btnCopy.Text = "Copy Output"
$btnCopy.Size = New-Object System.Drawing.Size(100, 28)
$btnCopy.FlatStyle = "Flat"
$btnCopy.Location = New-Object System.Drawing.Point(500, 4)
$pnlOptions.Controls.Add($btnCopy)

$btnClear = New-Object System.Windows.Forms.Button
$btnClear.Text = "Clear All"
$btnClear.Size = New-Object System.Drawing.Size(80, 28)
$btnClear.FlatStyle = "Flat"
$btnClear.Location = New-Object System.Drawing.Point(610, 4)
$pnlOptions.Controls.Add($btnClear)

# --- Output Label ---
$lblOutput = New-Object System.Windows.Forms.Label
$lblOutput.Text = "Humanized output:"
$lblOutput.AutoSize = $true
$form.Controls.Add($lblOutput)

# --- Output TextBox ---
$txtOutput = New-Object System.Windows.Forms.TextBox
$txtOutput.Multiline = $true
$txtOutput.ScrollBars = "Vertical"
$txtOutput.ReadOnly = $true
$txtOutput.BackColor = [System.Drawing.Color]::White
$txtOutput.WordWrap = $true
$txtOutput.Anchor = "Top,Left,Right,Bottom"
$form.Controls.Add($txtOutput)

# --- Status Bar ---
$statusBar = New-Object System.Windows.Forms.StatusStrip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Ready"
$statusLabel.Spring = $true   # stretches to fill bar width
$statusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$statusBar.Items.Add($statusLabel) | Out-Null
$form.Controls.Add($statusBar)

# ============================================================
# Dynamic layout — all positions computed from client size
# ============================================================
$MARGIN   = 12
$PADV     = 6    # vertical gap between sections
$LBL_H    = 18
$OPT_H    = 36
$SB_H     = 24   # status bar height

$layoutControls = {
    $w = $form.ClientSize.Width
    $h = $form.ClientSize.Height

    # Divide vertical space: input gets ~45%, options fixed, output gets rest
    $inputH = [Math]::Max(100, [int](($h - $SB_H - $OPT_H - $LBL_H * 2 - $PADV * 4 - $MARGIN * 2) * 0.45))

    $y = $MARGIN
    $lblInput.Location = New-Object System.Drawing.Point($MARGIN, $y)
    $y += $LBL_H + 2

    $txtInput.Location = New-Object System.Drawing.Point($MARGIN, $y)
    $txtInput.Size = New-Object System.Drawing.Size(($w - $MARGIN * 2), $inputH)
    $y += $inputH + $PADV

    $pnlOptions.Location = New-Object System.Drawing.Point($MARGIN, $y)
    $pnlOptions.Width = $w - $MARGIN * 2
    $y += $OPT_H + $PADV

    $lblOutput.Location = New-Object System.Drawing.Point($MARGIN, $y)
    $y += $LBL_H + 2

    $outputH = $h - $y - $SB_H - $MARGIN
    $txtOutput.Location = New-Object System.Drawing.Point($MARGIN, $y)
    $txtOutput.Size = New-Object System.Drawing.Size(($w - $MARGIN * 2), [Math]::Max(60, $outputH))
}

$form.Add_Load($layoutControls)
$form.Add_Resize($layoutControls)

# ============================================================
# Event handlers
# ============================================================
$btnDetect.Add_Click({
    if ([string]::IsNullOrWhiteSpace($txtInput.Text)) {
        $statusLabel.Text = "Nothing to analyze - paste some text first."
        return
    }
    $statusLabel.Text = Test-AIText -Text $txtInput.Text
})

$btnHumanize.Add_Click({
    if ([string]::IsNullOrWhiteSpace($txtInput.Text)) {
        $statusLabel.Text = "Nothing to humanize - paste some text first."
        return
    }

    $result = Convert-AIText -Text $txtInput.Text `
        -RemoveMarkdown $chkMarkdown.Checked `
        -RemoveEmoji $chkEmoji.Checked

    $txtOutput.Text = $result.Text
    $statusLabel.Text = $result.Summary
})

$btnCopy.Add_Click({
    if ([string]::IsNullOrWhiteSpace($txtOutput.Text)) {
        $statusLabel.Text = "Nothing to copy."
        return
    }
    [System.Windows.Forms.Clipboard]::SetText($txtOutput.Text)
    $statusLabel.Text = "Output copied to clipboard."
})

$btnClear.Add_Click({
    $txtInput.Text  = ""
    $txtOutput.Text = ""
    $statusLabel.Text = "Ready"
})

# Ctrl+A in textboxes
$selectAll = {
    param($sender, $e)
    if ($e.Control -and $e.KeyCode -eq [System.Windows.Forms.Keys]::A) {
        $sender.SelectAll()
        $e.SuppressKeyPress = $true
    }
}
$txtInput.Add_KeyDown($selectAll)
$txtOutput.Add_KeyDown($selectAll)

# --- Show the form ---
[void]$form.ShowDialog()
