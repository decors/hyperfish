function fish_prompt
    set -l exit_code $status
    echo -s -n  (__prompt_user_host) (__prompt_python_venv) (__prompt_cwd) ' ' (__prompt_git_info) (__prompt_status $exit_code) "➜ "
end

function __prompt_status --argument-names exit_code
    if test $exit_code -ne 0
        echo -s -n (set_color red) "⍉ " (set_color normal)
    end
end

function __prompt_user_host
    set -l me
    if test -n "$SSH_CONNECTION"
        set me "$USER@"(prompt_hostname)
    else if test "$USER" != "$LOGNAME"
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
            echo -s -n (set_color cyan) "~" (set_color normal)
        case "/"
            echo -s -n (set_color cyan) "/" (set_color normal)
        case "*"
            echo -s -n (set_color cyan) $basename (set_color normal)
    end
end

function __prompt_git_info
    set -l is_git_repository (command git rev-parse --is-inside-work-tree 2> /dev/null)
    if test -n "$is_git_repository"
        echo -s -n $FISH_THEME_GIT_PROMPT_PREFIX (__prompt_git_branch) (__prompt_git_dirty) $FISH_THEME_GIT_PROMPT_SUFFIX (__prompt_git_time_since_commit) (__prompt_git_status)
    end
end

function __prompt_git_branch
    set -l git_branch (command git symbolic-ref --short HEAD 2> /dev/null)
    if test $status -gt 0
        set git_branch (command git show-ref --head -s --abbrev HEAD 2> /dev/null)[1]
    end
    echo -s -n "$git_branch "
end

function __prompt_git_dirty
    set -l git_dirty (command git status --porcelain --ignore-submodules 2> /dev/null)
    if test -n "$git_dirty"
        echo -s -n "$FISH_THEME_GIT_PROMPT_DIRTY"
    else
        echo -s -n "$FISH_THEME_GIT_PROMPT_CLEAN"
    end
end

function __prompt_git_status
    set -l index
    set index (command git status --porcelain -b 2> /dev/null)

    set -l git_status
    if string match -qr '^\?\? ' $index > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_UNTRACKED"
    end
    if string match -qr '^A  ' $index > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_ADDED"
    else if string match -qr '^M  '  > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_ADDED"
    end
    if string match -qr '^ M ' $index > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_MODIFIED"
    else if string match -qr '^AM ' $index > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_MODIFIED"
    else if string match -qr '^ T ' $index > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_MODIFIED"
    end
    if string match -qr '^R  ' $index > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_RENAMED"
    end
    if string match -qr '^ D ' $index > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_DELETED"
    else if string match -qr '^D  ' $index > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_DELETED"
    else if string match -qr '^AD ' $index > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_DELETED"
    end
    if command git rev-parse --verify refs/stash > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_STASHED"
    end
    if string match -qr '^UU ' $index > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_UNMERGED"
    end
    if string match -qr '^## .*ahead' $index > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_AHEAD"
    end
    if string match -qr '^## .*behind' $index > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_BEHIND"
    end
    if string match -qr '^## .*diverged' $index > /dev/null 2>&1
        set -a git_status "$FISH_THEME_GIT_PROMPT_DIVERGED"
    end
    if test -n "$git_status"
        echo -s -n $git_status
        set_color normal
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
        if test $hours -ge 24
            set commit_age $days"d"
        else if test $minutes -gt 60
            set commit_age $sub_hours"h"$sub_minutes"m"
        else
            set commit_age $minutes"m"
        end

        set -l color
        set -l git_status (git status -s 2> /dev/null)
        if test -n "$git_status"
            if test "$hours" -gt 4
                set color "$FISH_THEME_GIT_TIME_SINCE_COMMIT_LONG"
            else if test "$minutes" -gt 30
                set color "$FISH_THEME_GIT_TIME_SHORT_COMMIT_MEDIUM"
            else
                set color "$FISH_THEME_GIT_TIME_SINCE_COMMIT_SHORT"
            end
        else
            set color "$FISH_THEME_GIT_TIME_SINCE_COMMIT_NEUTRAL"
        end

        echo -s -n "$color$commit_age " (set_color normal)
    end
end
