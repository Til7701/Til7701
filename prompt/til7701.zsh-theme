# til7701.zsh-theme
# based on af-magic.zsh-theme

setopt prompt_subst

function default_color() {
    echo "${FG[039]}"
}

function accent_color() {
    echo "${FG[005]}"
}

function error_code() {
    echo "%(?.. %F{009}%?)"
}

function execution_time() {
    if [[ -n "${T_LAST_CMD_TIME_MS}" ]]; then
        echo " $(accent_color)${T_LAST_CMD_TIME_MS}ms$(default_color)"
    fi
}

function git_prompt() {
    if [ -d .git ] || git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
	    echo " git$(accent_color): $(git_commits_ahead)$(git_commits_behind)$(default_color)$(git_repo_name) $(accent_color)🖈 $(git_prompt_remote)$(git_current_branch)$(default_color)$(parse_git_dirty)$(git_prompt_short_sha)$(git_prompt_tags)"
    fi
}

function git_prompt_tags() {
    # Check if the repository has any commits
    if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
        return
    fi

    local tags="$(git tag --list --omit-empty --points-at HEAD)"
    if [[ -n "$tags" ]]; then
        tags=$(printf "%s\n" "$tags" | paste -sd "$ZSH_THEME_GIT_TAGS_SEPARATOR" -)
        echo " ${ZSH_THEME_GIT_TAGS_PREFIX}${tags}${ZSH_THEME_GIT_TAGS_SUFFIX}"
    fi
}

function preexec() {
    T_TIMER_START=$EPOCHREALTIME
}

# https://anishathalye.com/an-asynchronous-shell-prompt/
ASYNC_PROC=0
function precmd() {
    if [[ -n "$T_TIMER_START" ]]; then
        local elapsed_ms=$(awk -v now="$EPOCHREALTIME" -v start="$T_TIMER_START" 'BEGIN { printf "%.0f", (now - start) * 1000 }')
        export T_LAST_CMD_TIME_MS=$elapsed_ms
    else
        export T_LAST_CMD_TIME_MS=""
    fi

    function async() {
        # save to temp file
        printf "%s" "$(git_prompt)" > "${HOME}/.zsh_tmp_prompt"

        # signal parent
        kill -s USR1 $$
    }

    # do not clear T_GIT_PROMPT, let it persist

    # kill child if necessary
    if [[ "${ASYNC_PROC}" != 0 ]]; then
        kill -s HUP $ASYNC_PROC >/dev/null 2>&1 || :
    fi

    # start background computation
    async &!
    ASYNC_PROC=$!
}

function TRAPUSR1() {
    # read from temp file
    T_GIT_PROMPT="$(cat ${HOME}/.zsh_tmp_prompt)"

    # reset proc number
    ASYNC_PROC=0

    # redisplay
    zle && zle reset-prompt
}

# primary prompt
PS1="$(default_color)%n$(accent_color)@$(default_color)%M\$(execution_time)\$(error_code)$(default_color)\${T_GIT_PROMPT}
$(default_color)%~$(accent_color)%(!.#.»)%{$reset_color%} "
PS2="%{$fg[red]%}\ %{$reset_color%}"

T_GIT_PROMPT=""

# git settings
ZSH_THEME_GIT_COMMITS_AHEAD_PREFIX="${FG[010]}"
ZSH_THEME_GIT_COMMITS_AHEAD_SUFFIX="↑ "
ZSH_THEME_GIT_COMMITS_BEHIND_PREFIX="${FG[012]}"
ZSH_THEME_GIT_COMMITS_BEHIND_SUFFIX="↓ "
ZSH_THEME_GIT_PROMPT_CLEAN=" $(default_color)(${FG[010]}clean$(default_color))"
ZSH_THEME_GIT_PROMPT_DIRTY=" $(default_color)(${FG[011]}dirty$(default_color))"
ZSH_THEME_GIT_PROMPT_DELETED=" deleted"
ZSH_THEME_GIT_PROMPT_DIVERGED=" ${FG[009]}diverged"
ZSH_THEME_GIT_PROMPT_DIVERGED_REMOTE=" ${FG[009]}diverged remote"
ZSH_THEME_GIT_PROMPT_EQUAL_REMOTE=" equal remote"
ZSH_THEME_GIT_PROMPT_MODIFIED=" ${FG[011]}modified"
ZSH_THEME_GIT_PROMPT_PREFIX=""
ZSH_THEME_GIT_PROMPT_REMOTE_EXISTS="${FG[010]}"
ZSH_THEME_GIT_PROMPT_REMOTE_MISSING="${FG[009]}"
ZSH_THEME_GIT_PROMPT_SHA_AFTER=""
ZSH_THEME_GIT_PROMPT_SHA_BEFORE=" $(accent_color)#$(default_color)"
ZSH_THEME_GIT_PROMPT_SUFFIX=""
ZSH_THEME_GIT_TAGS_PREFIX="$(accent_color)🏷 $(default_color)"
ZSH_THEME_GIT_TAGS_SEPARATOR=" "
ZSH_THEME_GIT_TAGS_SUFFIX=""

