function fish_prompt
    set -l exit_code $status
    echo -s -n  (__prompt_user_host) (__prompt_python_venv) (__prompt_cwd) " " (__prompt_git_info) (__prompt_status $exit_code) "➜ "
end

function __prompt_status --argument-names exit_code
    if test $exit_code -ne 0
        echo -s -n (set_color red) "⍉ "
    end
end

function __prompt_user_host
    if string match "\([-a-zA-Z0-9\.]+\)" (who am i)
        set me "$USER@"(prompt_hostname)
    else if test $USER != (logname)
        set me "$USER"
    end
    if test -n "$me"
        echo -s -n (set_color cyan) $me (set_color normal) ":"
    end
end

function __prompt_python_venv
    if test -n "$VIRTUAL_ENV"
        set -l venv (basename $VIRTUAL_ENV)
        echo -s -n (set_color blue) "($venv)" (set_color normal) " "
    end
end

function __prompt_cwd
    set -l basename (basename $PWD)
    set -l realhome ~

    switch "$PWD"
        case "$realhome"
            echo -s -n (set_color cyan) "~"
        case "/"
            echo -s -n (set_color cyan) "/"
        case "*"
            echo -s -n (set_color cyan) $basename
    end
end

function __prompt_git_info
    set -l is_git_repository (command git rev-parse --is-inside-work-tree 2>/dev/null)
    if test -n "$is_git_repository"
        echo -s -n $FISH_THEME_GIT_PROMPT_PREFIX (__prompt_git_branch) (__prompt_git_dirty) $FISH_THEME_GIT_PROMPT_SUFFIX (set_color normal) (__prompt_git_time_since_commit) (__prompt_git_status)
    end
end

function __prompt_git_branch
    set -l git_branch (command git symbolic-ref --short HEAD 2> /dev/null)
    if [ $status -gt 0 ]
        set git_branch (command git show-ref --head -s --abbrev HEAD 2> /dev/null)[1]
    end
    echo -s -n "$git_branch"
end

function __prompt_git_dirty
    set -l git_dirty (command git status --porcelain --ignore-submodules 2>/dev/null)
    if [ -n "$git_dirty" ]
        echo -s -n "$FISH_THEME_GIT_PROMPT_DIRTY"
    else
        echo -s -n "$FISH_THEME_GIT_PROMPT_CLEAN"
    end
end

function __prompt_git_status
    set -l index
    begin; set -l IFS; set index (command git status --porcelain -b 2> /dev/null); end

    set -l git_status
    if echo "$index" | grep -E '^\?\? ' > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_UNTRACKED"
    end
    if echo "$index" | grep '^A  ' > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_ADDED"
    else if echo "$index" | grep '^M  ' > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_ADDED"
    end
    if echo "$index" | grep '^ M ' > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_MODIFIED"
    else if echo "$index" | grep '^AM ' > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_MODIFIED"
    else if echo "$index" | grep '^ T ' > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_MODIFIED"
    end
    if echo "$index" | grep '^R  ' > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_RENAMED"
    end
    if echo "$index" | grep '^ D ' > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_DELETED"
    else if echo "$index" | grep '^D  ' > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_DELETED"
    else if echo "$index" | grep '^AD ' > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_DELETED"
    end
    if command git rev-parse --verify refs/stash >/dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_STASHED"
    end
    if echo "$index" | grep '^UU ' > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_UNMERGED"
    end
    if echo "$index" | grep '^## .*ahead' > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_AHEAD"
    end
    if echo "$index" | grep '^## .*behind' > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_BEHIND"
    end
    if echo "$index" | grep '^## .*diverged' > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_DIVERGED"
    end
    if [ -n "$git_status" ]
        echo "$git_status "
    end
end

function __prompt_git_time_since_commit
    if git log -1 > /dev/null 2>&1
        set -l last_commit (git log --pretty=format:'%at' -1 2> /dev/null)
        set -l now (date +%s)
        set -l seconds_since_last_commit (math $now - $last_commit)

        # Totals
        set -l minutes (math -s0 $seconds_since_last_commit / 60)
        set -l hours (math -s0 $seconds_since_last_commit / 3600)

        # Sub-hours and sub-minutes
        set -l days (math -s0 $seconds_since_last_commit / 86400)
        set -l sub_hours (math -s0 $hours % 24)
        set -l sub_minutes (math -s0 $minutes % 60)

        set -l commit_age
        if [ $hours -ge 24 ]
            set commit_age $days"d"
        else if [ $minutes -gt 60 ]
            set commit_age $sub_hours"h"$sub_minutes"m"
        else
            set commit_age $minutes"m"
        end

        set -l color
        set -l git_status (git status -s 2> /dev/null)
        if [ -n "$git_status" ]
            if [ "$hours" -gt 4 ]
                set color "$FISH_THEME_GIT_TIME_SINCE_COMMIT_LONG"
            else if [ "$minutes" -gt 30 ]
                set color "$FISH_THEME_GIT_TIME_SHORT_COMMIT_MEDIUM"
            else
                set color "$FISH_THEME_GIT_TIME_SINCE_COMMIT_SHORT"
            end
        else
            set color "$FISH_THEME_GIT_TIME_SINCE_COMMIT_NEUTRAL"
        end

        echo -s -n $color $commit_age (set_color normal)
    end
end
