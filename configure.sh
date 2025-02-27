#configure.sh VNC_USER_PASSWORD VNC_PASSWORD TAILSCALE_AUTH_KEY NGROK_AUTH_TOKEN

#disable spotlight indexing
sudo mdutil -i off -a

#Create new account
sudo dscl . -create /Users/vncuser
sudo dscl . -create /Users/vncuser UserShell /bin/bash
sudo dscl . -create /Users/vncuser RealName "VNC User"
sudo dscl . -create /Users/vncuser UniqueID 1001
sudo dscl . -create /Users/vncuser PrimaryGroupID 80
sudo dscl . -create /Users/vncuser NFSHomeDirectory /Users/vncuser
sudo dscl . -passwd /Users/vncuser $1
sudo dscl . -passwd /Users/vncuser $1
sudo createhomedir -c -u vncuser > /dev/null

#Enable VNC
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -allowAccessFor -allUsers -privs -all
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -clientopts -setvnclegacy -vnclegacy yes 

#VNC password - http://hints.macworld.com/article.php?story=20071103011608872
echo $2 | perl -we 'BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA"}; $_ = <>; chomp; s/^(.{8}).*/$1/; @p = unpack "C*", $_; foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }; print "\n"' | sudo tee /Library/Preferences/com.apple.VNCSettings.txt

#Start VNC/reset changes
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -restart -agent -console
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate

# install go
brew unlink go@1.17
brew install go || brew link --overwrite go

#install tailscale
go install tailscale.com/cmd/tailscale{,d}@main

#add gopath to path
echo "export PATH=$(go env GOPATH)/bin:$PATH" >> "$HOME/.zshrc"

#install the tailscale daemon
sudo $HOME/go/bin/tailscaled install-system-daemon

#configure tailscale
sudo $HOME/go/bin/tailscale up --authkey $3

#install reattach-to-user-namespace
brew install reattach-to-user-namespace

#configure tmux
echo "set-option -g default-command 'reattach-to-user-namespace -l zsh'" >> "$HOME/.tmux.conf"

#install ngrok
brew install --cask ngrok

#configure ngrok and start it
ngrok authtoken $4
ngrok tcp 5900 &
