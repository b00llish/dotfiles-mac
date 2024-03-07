1. Install 1password & sign in
- consider just using browser access

2. Create new SSH key & save it to github

``` zsh
curl https://raw.githubusercontent.com/b00llish/dotfiles-mac/HEAD/ssh.sh | sh -s "b00llish@pm.me"
```
 
 3. Clone this repo to ~/.dotfiles with:
 ```zsh 
 git clone --recursive git@github.com:b00llish/dotfiles-mac.git ~/.dotfiles
 ```

 4. Run the installation with:
 ```zsh
 cd ~/.dotfiles && ./fresh.sh
 ```

 - command will halt after installing oh-my-zsh; re-run the same command to continue with remaining tasks