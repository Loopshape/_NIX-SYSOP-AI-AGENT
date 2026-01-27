# Convert all symlinks to real files
find . -type l | while read link; do
  target=$(readlink "$link")
  if [ -f "$target" ]; then
    rm "$link"
    cp "$target" "$link"
    git add "$link"
    echo "Converted symlink $link -> $target"
  else
    echo "Warning: $link points to missing target $target, skipping"
  fi
done

