# Install Git
sudo apt install -y git

# Paste in SSH key
vi ~/.ssh/id_ed25519
vi ~/.ssh/id_ed25519.pub

# Add SSH key to agent
chmod 700 ~/.ssh/id_ed25519*
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Clone dotfiles
git clone git@github.com:pcewing/dotfiles.git dot

# Export NIX_HOST variable in .localrc file. Replace personal-desktop with the
# appropriate host type.
echo "export NIX_HOST=\"personal-desktop\"" >> ~/.localrc
