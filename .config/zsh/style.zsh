autoload -Uz colors && colors
autoload -Uz vcs_info

# PROMPT에서 ${...} 변수 확장 허용
setopt PROMPT_SUBST

# root면 red, 아니면 yellow
if [[ $UID -eq 0 ]]; then
  NCOLOR="red"
else
  NCOLOR="yellow"
fi

# git 정보 포맷
zstyle ':vcs_info:git:*' formats 'git:%b'
zstyle ':vcs_info:git:*' actionformats 'git:%b*'

# 매 프롬프트 직전에 vcs_info 갱신
precmd() { vcs_info }

# 프롬프트
PROMPT='%F{'$NCOLOR'}%c ➤ %f'
RPROMPT='%F{'$NCOLOR'}${vcs_info_msg_0_}%f'

# ls colors
export LSCOLORS="exfxcxdxbxbxbxbxbxbxbx"
export LS_COLORS="di=34;40:ln=35;40:so=32;40:pi=33;40:ex=31;40:bd=31;40:cd=31;40:su=31;40:sg=31;40:tw=31;40:ow=31;40:"
