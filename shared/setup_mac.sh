#!/bin/sh
printf "Enter your Dropbox path for this project (e.g. /Users/YourName/Dropbox/project): "
read dropbox_path

if [ -z "$dropbox_path" ]; then
    echo "No path entered, aborting."
    exit 1
fi

# Save config — navigate up from shared/ to repo root first
cd "$(dirname "$0")/.."

echo "DROPBOX_PATH=$dropbox_path" > dropbox_path.txt

repo_path=$(pwd)

cat > .git/hooks/post-commit << EOF
#!/bin/sh
rsync -av --exclude='.git' "$repo_path/" "$dropbox_path/"
EOF

chmod +x .git/hooks/post-commit

echo "All done! Commits will now sync to $dropbox_path"
