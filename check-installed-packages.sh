# Check if we have initial status file
if [ -f /var/log/installer/initial-status.gz ]; then
    echo "User-installed packages (name - version):"
    echo "-----------------------------------------"
    comm -23 <(apt-mark showmanual | sort -u) \
            <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort -u) | \
    while read pkg; do
        version=$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || echo "N/A")
        echo "$pkg - $version"
    done | sort
else
    echo "User-installed packages (name - version):"
    echo "-----------------------------------------"
    apt-mark showmanual | \
    grep -v -E 'ubuntu-|gnome-|libreoffice|thunderbird|rhythmbox|shotwell|transmission|gedit|eog|evince|totem|baobab|seahorse|simple-scan|cheese|deja-dup' | \
    while read pkg; do
        version=$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || echo "N/A")
        echo "$pkg - $version"
    done | sort
fi