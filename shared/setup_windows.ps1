$dropboxPath = Read-Host "Enter your Dropbox path for this project (e.g. C:\Users\YourName\Dropbox\project)"

if (-not $dropboxPath) {
    Write-Host "No path entered, aborting."
    exit 1
}

"DROPBOX_PATH=$dropboxPath" | Set-Content "dropbox_path.txt" -Encoding utf8

$repoPath = (Get-Location).Path

"#! C:/Program\ Files/Git/usr/bin/sh.exe
robocopy `"$repoPath`" `"$dropboxPath`" /MIR /XD .git" | Set-Content .git/hooks/post-commit -Encoding utf8

& "C:\Program Files\Git\bin\bash.exe" -c "chmod +x .git/hooks/post-commit"

Write-Host "All done! Commits will now sync to $dropboxPath"
