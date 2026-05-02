# Up arrow: search backward using current prefix
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# Some terminals send different sequences
bind '"\eOA": history-search-backward'
bind '"\eOB": history-search-forward'
