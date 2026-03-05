autoload -Uz colors && colors
autoload -Uz vcs_info

# vcs
autoload -Uz vcs_info
autoload -Uz add-zsh-hook

# git 정보 포맷
zstyle ':vcs_info:git:*' formats 'git:%b'
zstyle ':vcs_info:git:*' actionformats 'git:%b*'

# ---- vcs_info 최적화 ----

# 첫 프롬프트에서는 skip (터미널 체감 속도 개선)
typeset -g _VCS_SKIP_ONCE=1

_vcs_precmd() {
  if (( _VCS_SKIP_ONCE )); then
    _VCS_SKIP_ONCE=0
    return
  fi
  vcs_info
}

# 디렉토리 변경 시에도 갱신
_vcs_chpwd() {
  vcs_info
}

add-zsh-hook precmd _vcs_precmd
add-zsh-hook chpwd _vcs_chpwd

# 현재 디렉토리가 git repo면 한 번만 미리 실행
vcs_info

# PROMPT에서 ${...} 변수 확장 허용
setopt PROMPT_SUBST

# ---- prompt ----

# root면 red, 아니면 yellow
if [[ $UID -eq 0 ]]; then
  NCOLOR="red"
else
  NCOLOR="yellow"
fi

# 프롬프트
PROMPT='%F{'$NCOLOR'}%c ➤ %f'
RPROMPT='%F{'$NCOLOR'}${vcs_info_msg_0_}%f'

# ls colors
export LSCOLORS="exfxcxdxbxbxbxbxbxbxbx"
export LS_COLORS="di=34;40:ln=35;40:so=32;40:pi=33;40:ex=31;40:bd=31;40:cd=31;40:su=31;40:sg=31;40:tw=31;40:ow=31;40:"
