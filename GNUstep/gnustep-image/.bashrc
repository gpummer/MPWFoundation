#
# this file gets executed by every shell you start
#


	umask 022
	set history=50
	export RSYNC_RSH=ssh

	# aliases

	alias		pm="date;ping -i 5 mail.metaobject.de"
	alias		lg="ls -alg"
	alias		lA="ls -Al"
	alias		la="ls -AlLhF"
	alias		l="ls -F"
	alias		m=less
	alias		s=source 
	alias		cls=clear
	alias		pd=pushd
	alias		pop=popd
	alias 		grepm="find . -name '*.[mch]' -or -name '*.java' -or -name '*.rb' -or -name '*.wos' -or -name '*.cc' -or -name '*.cpp' | xargs agrep -n "
	alias 		grepml="find . -name '*.[mch]' -or -name '*.java' -or -name '*.wos' -or -name '*.cc' -or -name '*.cpp'  | xargs agrep -l "

	# environment
	
	export EXINIT="se sw=4|se ts=4|map g G" # useful inits for vi
	export PAGER="less -ms"		 # use decent pager for man
	export CLICOLOR=1

	# shell setup

	PS1="\u@\h[\W]"
	set autolist=beepnone		# tcsh lists filename-completions
	
	. /usr/share/GNUstep/Makefiles/GNUstep.sh

	function  trless {
		LANG=''  tr \\15 \\12 < "$1" | less 
	}
	function  cdf {
		cd `dirname $1`
	}
