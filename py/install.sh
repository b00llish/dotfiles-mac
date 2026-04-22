# Add Pyenv to the PATH:
# echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
# echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
# echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init --path)"\nfi' >> ~/.zshrc

# Reload the shell:
# source ~/.zshrc

# Install Python:
pyenv install 3.12.8
pyenv global 3.12.8

# Add Poetry completions:
mkdir $ZSH_CUSTOM/plugins/poetry
poetry completions zsh > $ZSH_CUSTOM/plugins/poetry/_poetry

# Update Poetry settings:
poetry config virtualenvs.create false --local
