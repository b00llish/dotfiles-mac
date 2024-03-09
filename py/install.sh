# Add Pyenv to the PATH:
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init --path)"\nfi' >> ~/.zshrc

# Reload the shell:
source ~/.zshrc

# Install Python:
pyenv install 3.11.5
pyenv global 3.11.5

# Update Poetry settings:

