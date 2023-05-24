#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1516248927"
MD5="e0c63e9ed9972223af1f3cf23f7f9d94"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="Next Generation Minecraft Installer (Ubuntu Server)"
script="./install_server"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="."
filesizes="5324"
keep="y"
nooverwrite="n"
quiet="n"
accept="n"
nodiskspace="n"
export_conf="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

if test -d /usr/xpg4/bin; then
    PATH=/usr/xpg4/bin:$PATH
    export PATH
fi

if test -d /usr/sfw/bin; then
    PATH=$PATH:/usr/sfw/bin
    export PATH
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt" | more
    if test x"$accept" != xy; then
      while true
      do
        MS_Printf "Please type y to accept, n otherwise: "
        read yn
        if test x"$yn" = xn; then
          keep=n
          eval $finish; exit 1
          break;
        elif test x"$yn" = xy; then
          break;
        fi
      done
    fi
  fi
}

MS_diskspace()
{
	(
	df -kP "$1" | tail -1 | awk '{ if ($4 ~ /%/) {print $3} else {print $4} }'
	)
}

MS_dd()
{
    blocks=`expr $3 / 1024`
    bytes=`expr $3 % 1024`
    dd if="$1" ibs=$2 skip=1 obs=1024 conv=sync 2> /dev/null | \
    { test $blocks -gt 0 && dd ibs=1024 obs=1024 count=$blocks ; \
      test $bytes  -gt 0 && dd ibs=1 obs=1024 count=$bytes ; } 2> /dev/null
}

MS_dd_Progress()
{
    if test x"$noprogress" = xy; then
        MS_dd $@
        return $?
    fi
    file="$1"
    offset=$2
    length=$3
    pos=0
    bsize=4194304
    while test $bsize -gt $length; do
        bsize=`expr $bsize / 4`
    done
    blocks=`expr $length / $bsize`
    bytes=`expr $length % $bsize`
    (
        dd ibs=$offset skip=1 2>/dev/null
        pos=`expr $pos \+ $bsize`
        MS_Printf "     0%% " 1>&2
        if test $blocks -gt 0; then
            while test $pos -le $length; do
                dd bs=$bsize count=1 2>/dev/null
                pcent=`expr $length / 100`
                pcent=`expr $pos / $pcent`
                if test $pcent -lt 100; then
                    MS_Printf "\b\b\b\b\b\b\b" 1>&2
                    if test $pcent -lt 10; then
                        MS_Printf "    $pcent%% " 1>&2
                    else
                        MS_Printf "   $pcent%% " 1>&2
                    fi
                fi
                pos=`expr $pos \+ $bsize`
            done
        fi
        if test $bytes -gt 0; then
            dd bs=$bytes count=1 2>/dev/null
        fi
        MS_Printf "\b\b\b\b\b\b\b" 1>&2
        MS_Printf " 100%%  " 1>&2
    ) < "$file"
}

MS_Help()
{
    cat << EOH >&2
${helpheader}Makeself version 2.4.0
 1) Getting help or info about $0 :
  $0 --help   Print this message
  $0 --info   Print embedded info : title, default target directory, embedded script ...
  $0 --lsm    Print embedded lsm entry (or no LSM)
  $0 --list   Print the list of files in the archive
  $0 --check  Checks integrity of the archive

 2) Running $0 :
  $0 [options] [--] [additional arguments to embedded script]
  with following options (in that order)
  --confirm             Ask before running embedded script
  --quiet		Do not print anything except error messages
  --accept              Accept the license
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --nodiskspace         Do not check for available disk space
  --target dir          Extract directly to a target directory (absolute or relative)
                        This directory may undergo recursive chown (see --nochown).
  --tar arg1 [arg2 ...] Access the contents of the archive through the tar command
  --                    Following arguments will be passed to the embedded script
EOH
}

MS_Check()
{
    OLD_PATH="$PATH"
    PATH=${GUESS_MD5_PATH:-"$OLD_PATH:/bin:/usr/bin:/sbin:/usr/local/ssl/bin:/usr/local/bin:/opt/openssl/bin"}
	MD5_ARG=""
    MD5_PATH=`exec <&- 2>&-; which md5sum || command -v md5sum || type md5sum`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which md5 || command -v md5 || type md5`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which digest || command -v digest || type digest`
    PATH="$OLD_PATH"

    SHA_PATH=`exec <&- 2>&-; which shasum || command -v shasum || type shasum`
    test -x "$SHA_PATH" || SHA_PATH=`exec <&- 2>&-; which sha256sum || command -v sha256sum || type sha256sum`

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 588 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
		if test -x "$SHA_PATH"; then
			if test x"`basename $SHA_PATH`" = xshasum; then
				SHA_ARG="-a 256"
			fi
			sha=`echo $SHA | cut -d" " -f$i`
			if test x"$sha" = x0000000000000000000000000000000000000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded SHA256 checksum." >&2
			else
				shasum=`MS_dd_Progress "$1" $offset $s | eval "$SHA_PATH $SHA_ARG" | cut -b-64`;
				if test x"$shasum" != x"$sha"; then
					echo "Error in SHA256 checksums: $shasum is different from $sha" >&2
					exit 2
				else
					test x"$verb" = xy && MS_Printf " SHA256 checksums are OK." >&2
				fi
				crc="0000000000";
			fi
		fi
		if test -x "$MD5_PATH"; then
			if test x"`basename $MD5_PATH`" = xdigest; then
				MD5_ARG="-a md5"
			fi
			md5=`echo $MD5 | cut -d" " -f$i`
			if test x"$md5" = x00000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded MD5 checksum." >&2
			else
				md5sum=`MS_dd_Progress "$1" $offset $s | eval "$MD5_PATH $MD5_ARG" | cut -b-32`;
				if test x"$md5sum" != x"$md5"; then
					echo "Error in MD5 checksums: $md5sum is different from $md5" >&2
					exit 2
				else
					test x"$verb" = xy && MS_Printf " MD5 checksums are OK." >&2
				fi
				crc="0000000000"; verb=n
			fi
		fi
		if test x"$crc" = x0000000000; then
			test x"$verb" = xy && echo " $1 does not contain a CRC checksum." >&2
		else
			sum1=`MS_dd_Progress "$1" $offset $s | CMD_ENV=xpg4 cksum | awk '{print $1}'`
			if test x"$sum1" = x"$crc"; then
				test x"$verb" = xy && MS_Printf " CRC checksums are OK." >&2
			else
				echo "Error in checksums: $sum1 is different from $crc" >&2
				exit 2;
			fi
		fi
		i=`expr $i + 1`
		offset=`expr $offset + $s`
    done
    if test x"$quiet" = xn; then
		echo " All good."
    fi
}

UnTAR()
{
    if test x"$quiet" = xn; then
		tar $1vf -  2>&1 || { echo " ... Extraction failed." > /dev/tty; kill -15 $$; }
    else
		tar $1f -  2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    fi
}

finish=true
xterm_loop=
noprogress=n
nox11=n
copy=none
ownership=y
verbose=n

initargs="$@"

while true
do
    case "$1" in
    -h | --help)
	MS_Help
	exit 0
	;;
    -q | --quiet)
	quiet=y
	noprogress=y
	shift
	;;
	--accept)
	accept=y
	shift
	;;
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 92 KB
	echo Compression: gzip
	echo Date of packaging: Wed May 24 13:51:20 UTC 2023
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--notemp\" \\
    \".\" \\
    \"install_ubuntu.sh\" \\
    \"Next Generation Minecraft Installer (Ubuntu Server)\" \\
    \"./install_server\""
	if test x"$script" != x; then
	    echo Script run after extraction:
	    echo "    " $script $scriptargs
	fi
	if test x"" = xcopy; then
		echo "Archive will copy itself to a temporary location"
	fi
	if test x"n" = xy; then
		echo "Root permissions required for extraction"
	fi
	if test x"y" = xy; then
	    echo "directory $targetdir is permanent"
	else
	    echo "$targetdir will be removed after extraction"
	fi
	exit 0
	;;
    --dumpconf)
	echo LABEL=\"$label\"
	echo SCRIPT=\"$script\"
	echo SCRIPTARGS=\"$scriptargs\"
	echo archdirname=\".\"
	echo KEEP=y
	echo NOOVERWRITE=n
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=92
	echo OLDSKIP=589
	exit 0
	;;
    --lsm)
cat << EOLSM
No LSM.
EOLSM
	exit 0
	;;
    --list)
	echo Target directory: $targetdir
	offset=`head -n 588 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 588 "$0" | wc -c | tr -d " "`
	arg1="$2"
    if ! shift 2; then MS_Help; exit 1; fi
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
    --check)
	MS_Check "$0" y
	exit 0
	;;
    --confirm)
	verbose=y
	shift
	;;
	--noexec)
	script=""
	shift
	;;
    --keep)
	keep=y
	shift
	;;
    --target)
	keep=y
	targetdir="${2:-.}"
    if ! shift 2; then MS_Help; exit 1; fi
	;;
    --noprogress)
	noprogress=y
	shift
	;;
    --nox11)
	nox11=y
	shift
	;;
    --nochown)
	ownership=n
	shift
	;;
    --nodiskspace)
	nodiskspace=y
	shift
	;;
    --xwin)
	if test "n" = n; then
		finish="echo Press Return to close this window...; read junk"
	fi
	xterm_loop=1
	shift
	;;
    --phase2)
	copy=phase2
	shift
	;;
    --)
	shift
	break ;;
    -*)
	echo Unrecognized flag : "$1" >&2
	MS_Help
	exit 1
	;;
    *)
	break ;;
    esac
done

if test x"$quiet" = xy -a x"$verbose" = xy; then
	echo Cannot be verbose and quiet at the same time. >&2
	exit 1
fi

if test x"n" = xy -a `id -u` -ne 0; then
	echo "Administrative privileges required for this archive (use su or sudo)" >&2
	exit 1	
fi

if test x"$copy" \!= xphase2; then
    MS_PrintLicense
fi

case "$copy" in
copy)
    tmpdir="$TMPROOT"/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
    mkdir "$tmpdir" || {
	echo "Could not create temporary directory $tmpdir" >&2
	exit 1
    }
    SCRIPT_COPY="$tmpdir/makeself"
    echo "Copying to a temporary location..." >&2
    cp "$0" "$SCRIPT_COPY"
    chmod +x "$SCRIPT_COPY"
    cd "$TMPROOT"
    exec "$SCRIPT_COPY" --phase2 -- $initargs
    ;;
phase2)
    finish="$finish ; rm -rf `dirname $0`"
    ;;
esac

if test x"$nox11" = xn; then
    if tty -s; then                 # Do we have a terminal?
	:
    else
        if test x"$DISPLAY" != x -a x"$xterm_loop" = x; then  # No, but do we have X?
            if xset q > /dev/null 2>&1; then # Check for valid DISPLAY variable
                GUESS_XTERMS="xterm gnome-terminal rxvt dtterm eterm Eterm xfce4-terminal lxterminal kvt konsole aterm terminology"
                for a in $GUESS_XTERMS; do
                    if type $a >/dev/null 2>&1; then
                        XTERM=$a
                        break
                    fi
                done
                chmod a+x $0 || echo Please add execution rights on $0
                if test `echo "$0" | cut -c1` = "/"; then # Spawn a terminal!
                    exec $XTERM -title "$label" -e "$0" --xwin "$initargs"
                else
                    exec $XTERM -title "$label" -e "./$0" --xwin "$initargs"
                fi
            fi
        fi
    fi
fi

if test x"$targetdir" = x.; then
    tmpdir="."
else
    if test x"$keep" = xy; then
	if test x"$nooverwrite" = xy && test -d "$targetdir"; then
            echo "Target directory $targetdir already exists, aborting." >&2
            exit 1
	fi
	if test x"$quiet" = xn; then
	    echo "Creating directory $targetdir" >&2
	fi
	tmpdir="$targetdir"
	dashp="-p"
    else
	tmpdir="$TMPROOT/selfgz$$$RANDOM"
	dashp=""
    fi
    mkdir $dashp "$tmpdir" || {
	echo 'Cannot create target directory' $tmpdir >&2
	echo 'You should try option --target dir' >&2
	eval $finish
	exit 1
    }
fi

location="`pwd`"
if test x"$SETUP_NOCHECK" != x1; then
    MS_Check "$0"
fi
offset=`head -n 588 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 92 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
	
    # Decrypting with openssl will ask for password,
    # the prompt needs to start on new line
	if test x"n" = xy; then
	    echo
	fi
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf "$tmpdir"; eval $finish; exit 15' 1 2 3 15
fi

if test x"$nodiskspace" = xn; then
    leftspace=`MS_diskspace "$tmpdir"`
    if test -n "$leftspace"; then
        if test "$leftspace" -lt 92; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (92 KB)" >&2
            echo "Use --nodiskspace option to skip this check and proceed anyway" >&2
            if test x"$keep" = xn; then
                echo "Consider setting TMPDIR to a directory with more free space."
            fi
            eval $finish; exit 1
        fi
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
		fi
    else
		echo >&2
		echo "Unable to decompress $0" >&2
		eval $finish; exit 1
    fi
    offset=`expr $offset + $s`
done
if test x"$quiet" = xn; then
	echo
fi

cd "$tmpdir"
res=0
if test x"$script" != x; then
    if test x"$export_conf" = x"y"; then
        MS_BUNDLE="$0"
        MS_LABEL="$label"
        MS_SCRIPT="$script"
        MS_SCRIPTARGS="$scriptargs"
        MS_ARCHDIRNAME="$archdirname"
        MS_KEEP="$KEEP"
        MS_NOOVERWRITE="$NOOVERWRITE"
        MS_COMPRESS="$COMPRESS"
        export MS_BUNDLE MS_LABEL MS_SCRIPT MS_SCRIPTARGS
        export MS_ARCHDIRNAME MS_KEEP MS_NOOVERWRITE MS_COMPRESS
    fi

    if test x"$verbose" = x"y"; then
		MS_Printf "OK to execute: $script $scriptargs $* ? [Y/n] "
		read yn
		if test x"$yn" = x -o x"$yn" = xy -o x"$yn" = xY; then
			eval "\"$script\" $scriptargs \"\$@\""; res=$?;
		fi
    else
		eval "\"$script\" $scriptargs \"\$@\""; res=$?
    fi
    if test "$res" -ne 0; then
		test x"$verbose" = xy && echo "The program '$script' returned an error code ($res)" >&2
    fi
fi
if test x"$keep" = xn; then
    cd "$TMPROOT"
    /bin/rm -rf "$tmpdir"
fi
eval $finish; exit $res
‹     í=ùWÛHÒùYE#˜	ÙÁ2¾ğû˜|vï‚Í³Ídófòò„ÔÆtxt˜xòåßª>tØÂ€92êä…H­®®ªî®®«­üìÁË.”f³‰?+ÍÆnú§,Ï*õz­V¯Ôv+µg»•Ê^£òŒ4=B‰‚P÷	yfx&¦ºA¯øîºú'Z´òQ÷°Óv4Ç|ÈñßÛÛ»jü«»{ñøWkÍ:Œ­ºWFv‹ñğrÜ‘#Ë n@åĞ›Î}ë|’mã©îVk¤­Ï,“zşL?·-]QN¨ïXA`y.±2¡>=›“s_wCjî±O)ñÆÄ˜èş9İ!¡GtwN¦Ô wê–k¹çD'ô¥À—áÀŞ8¼Ô}
›DÏ°t€GLÏˆê†zˆı-›d;œP¢EõëÄ¤º­X.Á:YE.­pâE!ñiú–0vˆåvd"²Ú¶Kô€Í€FP€xîÇ3­1ş¤Œ¬itf[Ád‡˜‚>‹BxàKÆÉ¤£ìù$ ¶­ ğf´&Ø±oõ)24,
ğÍåÄs²”X2|º¤¬éËXP#Ä7øùØ³mïI3<×´¢`_QFP¥Ÿy3Êháãëz! ÊQÀ˜&£*ª‚‰nÛäŒ
†A¿À^=EİÃâqCK·ÉÔóY‹djĞÿÛö_ŞµÒ’“Aÿ×n»Ó&jkÏêy×½íŸ|1hõFïIÿ5iõŞ“ÿt{íÒùïÉ 3’ş@éŸu;ğ®Û;<:mw{oÈ+h×ëÃ$îÂT £>Á¨ngˆÀ;ƒÃ·ğØzÕ=êŞï(¯»£Â|İ9iFİÃÓ£Ö€œœNúÃtß°½nïõ zéwz#z…w¤ó+<áÛÖÑv¥´NûâGû'ïİ7oGämÿ¨İ—¯:€YëÕQ‡wDµºÇ;¤İ:n½é°V}€2Pğ3y÷¶ƒ¯°¿ü=uû=$ã°ßàq¨Œâ¦ïºÃÎiºCdÈëAÿxGAvB‹>ízYM2#Ÿàóé°$íNë`±1’(?Ö”gEùÎöÿ€ú3ê<Ó‹hZ~¨ı¿ÙhÜDÿû½Q)ô¿¯2şSHœx¶IıÇÒÿ`r,ÿ^³Ò,ô¿Ç(#Üıá/îÙ|
 Ôø Uxş4
ŸÕ[.5|}>[Š}àûYÿ–+À¶?ò‘}|û¿²[‡½!kÿ×÷ê»ÅúŒ²¹Q>³Üò™LÃ¦º¯PcâõµÏ¡Ò´èÑO!yC]êsC)]>}¨¿¡*Ö˜l?ô™NJ%˜KÌœø0é”Tš¤ô§ \…ŞEg0è6àSr¨»`u€}æÈL·Áàd@ÄÌd=jäF
í	¸ÒÔÈ	`Pâè`°Dh(…(ÌDCjj*ôæ;Bj‘’?N?‹=/y½¸ÕOV¨Œ-NpÄA“©4#¡}"?şBÊ&•İì¢ÓÆšfiûzt‘o¯IkúÍĞá{n¨Ÿ­KŠhı­P/×¤[~-*6Éƒ"q	Ÿ–ÇÌÒ³ÉÚ¼	E ·&ms‘¶Í+ˆÛÌ§nS·	ôùT²¦ 'zH.½È6ÉÜ‹ˆm]0Aéê(0™?‹÷Ç`¹İ'*¼bîêßHé/¢n‰7*ù ‡÷n£°ÀÉbcpv‚Ø¤Î4œ³±–Ã%ú?ØÚfM%> ±C†?%õ…üê§xJ=lZ½vÿX]`ŠÎ	s k?rÑé‡\õ).ˆ7Å…_B«“ğÖ»$NdLˆCT—‡Haû¡@]ˆ/Éö›W/8hÅÊ\²õËåßvK?(!†¼c¨îx‘¦ˆD¯¤{lšnäœÚ¦z3K6ºiM}ä}AaGªMİ²çÒLx‰$c¶î%Ñø"Cu¼Òï¼Ho#²7'<½PåB˜ÃŸÅ|ş"0€¯Ì9¾G*¾àtYäy98(¿ÏÕßS~WU"Íçr`øÖ4ÊD;0C 3@Lù[@Œ-—É=•~ä@ñÍM n& H
 ó›€¸_î3Á›{áÎ]øcx.hÔáØ³ a-$¸ôÑ§×Â!à.(@ûhz8€uP …#?†–C×é?ÕzÎ=_3ì#†S>Âˆ­óuÈ²2Ñ×è®Èä@Y™@ŸÑ;,tóµºuÿ.Ë3¿=èpğ¿´_ oz'ü½;m —+¤¶Ü…‡K0g&•
©¾&¯¤Z±´Í+y†a& àÿ¢KEK/èïÒÿ7è´ÚÇ™şqÿ¿Ö¨6ó?*Âÿ÷8ş¿”+oˆ[&Ë	8Ö]ı	†laOQZrY€µ/À& “­ï -o°Åçh.œÓèK! Ñ\²\âXnÒ@#-èÊÁ®’\	%º1¡A:SCXš¢£)î# :úÃ}¥DNÙŞ˜³5\"}¶ñ‘#èá“¢N¨qÁ,—e®‚€ —GF5l°ÀôîF`y—®íYL©a-Cú?ûCfa.†°f5e†Ó`¿\>Ô£3ÍğĞÁü™n–cÚK±ãl‰3³,úÊŠ²	ìØÁv©ÄAşnĞJs‡ùÚv˜çç-G##`åxÑ?#Ë§˜.ìˆD Ö,Ö¢yäMQ'ÖmtÇlbÁ<t9h.évàñŒé?a"w&"“ïèZ0Á,ä5×:à5æœèásœC	Fş9,“SËÒmpDÒÈ¥>×X¾Š‹|3CšÜüQˆk–„) Æ‡*>«².	cm_bRÊp×ş€5o/¸‰xû ç3ğp62µÇä{´2nŸO~ü¦TSgJ4²Ì%õîs²ıBÍ1‚73ó{uïñ`Ü°÷4ä¼Î•ÌÈ²Íxù˜Öxluc¯ˆ"²¤Ğ˜èî9¬»³HÌ/üDVÂ¨yá$gx±6Ùxc±ã«>šš,?L7`Å¡ˆ@·/)Ìœeu“A[V‰ağõ6õ½™…N™˜™&EÇğËLg‰,ÇOnF£Kyšz›L+ä(ô6…F^ôd œbËí±‹¼âšË€†À^2tvì+ –p,c”3Qb{c“HŒ“\LÆÙœ
Y6ŒÛºÎ²î4¤Õ¤c=²™_µRgşà›~…(µ¤Ç­_‹§ŒùtfœêKÏ¿`Â=gßxÚ\(íî%Muû0d¦Ç…Ù¥‹Ò‡Î`È§>2ŠõçXAĞ… 5|L˜0–Œ!¡¯›ÔÑı‹ Ô%5(”-´˜œÈwEïİå³IPLérª%Ë©Kâ	…Çcû¡ó¿o–ÿSÛ­ïrı¯Väÿ<êøg–æcÇÿ›ãßhÖª…şÿ5ãÿ\á† Ó)…) Šú^ÔÙ',{Hˆq¹7£¾ÆwØ”Ç¾He^ÔÎ@9œúÚy²ÁÆ0ßåéj\İ4Ùı‰–ú¼ëOyš³¬øm÷èkÌŠÛ'#nö[å¢#e©¢ŠŞté}Ş£°ıÚ@—m+¸x±ô]ı .¼°Q˜h<0m+Áù·ÆòZ3ÑÖ
a×ÅÚMQ½˜_±ıŸPßòÌRò©'æJ¾h~€æ±9ÓUµë)¤ÿƒq¤§$üÔƒrbF¶D*ENX}êW×³%Ëw©¥"†Ü/¡Î¦,7ŸGIÅƒÂC„[ñR¢’İ$J¨]åøq†"B%BÆ·¶º}5¿}â[İ¼–Û<åš\İ¼×|É+¶F#±©­ò§ûÈñáÊ^6ó»Ù#éØß½…	Yl$DvyC2$ã¥„¬aÈPx-óok·_
‚ŠUåÇò! LÚm1®2=	x*WŒH¯Ìk€Ápée¬çÇGv²)ÜÜy™ñó¡ZŠò‹!Ê¡+S)lRø‚IÊ¸TDwÍ“4Î™ˆ=_ŞL2ÈÛ°5i|+ÛÌ A2åè,ó@LÅ8çĞ›‚|G‘ª§³gavÏ™1L`ª¼sŸœ°Œ™QÒDNX®†Ê<g°²`Sˆ(£ùªy”šF«<ç÷Øv½ÖKbùV3ÄõÚòàíÚ¦œı·k˜+?o »	Üªev÷º]SoÍ¹‘³éÄË2«“Sá¬A%€iä=È¶Ê‚™ÏTl®(éåecy±0²Óz¢ºîŞÌ…£.\˜ ú	’ÅF“ÓÁ
q öcäÛğKóÜÏ¤ä¥Ôò8!	¶»Ğ-çšLk¹…²—p1ÕSÒ€9¤ñ•™À úôe#™r®1–JÏ0÷1ÆŸÇÑCÎ˜æÌ˜{HË(7‹éc+öÍ5²À®ŞQ7}İ);¸7™ü7‰WUáğüQŠ1ÏX0Â¬1tüœL‚TÀ-î@+’|›faÿ[	¡’'¿–¤Ğ‚ ÚA!’Ç`…¸ Ó¾~ŒaáŠ säs©…’Ë sv.Ø
 õsİr¿	éví 4'£²ëò´ãØ,İH'M~·ç?c^}mÿ/~W©ïaü¿ğÿ~…ñO4àGòÿâißÚÂøï5…ÿ÷+ùƒUäA}LV•Ù*4¬ì{.@_ã´!#ò4’w1Xöû°qÉç$6'¬¨œÉJ¶w±=&QÁA£\PŸ<áuûÖĞÈÖe8Ñ÷7oJİ¸Z?…qò€«»ÛâX2‚‡ád
š£JbDòÀ½ÇqC¼ƒÁC8–k±Û0¸ñx{ìmÑßÉ¼'¨¤Ir‘Ît&"øj2±ê+.1MCj¾É˜¸¸7ïdÙ!›şfÄµˆôş(1HE¬“1l_N9r¯6@1Ò4e•	Áş×ùT}CJhc¥¼ş®wY
%9vüiiÒ){›Z5®åù0U5îŠÃwzşwEé#Éø»ÿ×¬U‹ü¿'"ÿÑXSáŸì[X¾G.e5V1¸u¶vzv¢%y\­B#Rı%9\È¤—dã Fÿ’v3k‰œH­ ©±ğá–¦@[±ìQcakFÒ¸S3©1‹DFñ*'nûÄ2ZTÆÒ9Õí`)Q±i¼Çáût´?2K‚PËFA<‡Gê"íhO—€Ëcœ.…*®@ø[—Uç$Iÿßm,İÿÒ¬Ôj…üJú¿èKâ©,İı8qÊA(…aÆ‘Ã:
¨k–.è<İ¨8ùK¨†‘•–…éõh-|®hZ¥ñE1½¼]AŸ¡¼eÂ:°1Š]]ªä|ˆ›Ç7»ş—µä×ÿ*Õ…õ_İmT
ûÿ)®ÿ$¿‰[‘‹Iíë¸‘ó™¯–i’Ïgú–ì1“ã5 ŞwÉ¾a)hò«›f]“|a=l÷<ßa^ğj£±×`á\?(
"Óc,t¼š“l}Æ÷_bù³‹Á²XÈìÚÌ¥Ûwo(tşß Î;Çí=ä…FõÄõ¿…¤Ç°ÿAÜ/êÍ½Âş"ò?}İ‚šzX±KÈ¬Ğ§§!>GÃü9ÓY½†º1á•Ëª¨ª
×ë…İk¤ieøË¯¥ÌúBJüìÍO•:@›O)	O?Q¯C)ùäóòû¿Ì‡9P·¶ñ'ùIıÁ,ıà”~x¯ÂÆêë®y òŸü²ñ¿ø¦çÂ´üÜÎñ ~ÙúŒm¾(ŞÅBşq£oóöĞs¦¸ßÄ{2ó™°ó¤ì;]¬÷ïg,Ê=ÈÿlÚŞ£Øÿ{Õ%û¯ZèÿOJÿ—g.¤èû¦Eûb˜1å¾e¹çô,bwèˆë¥Â~dä18xè0ÈáhpôÓ+ak§cb‚!/W¦¯,ï!_ı§bÿ©-ış&^	[¬ÿ§´şE úÁÿxétOúƒQ«7ÚØØÈ1;>ä³ødÙâitC…–mıEyÊÙÉ»v|äœŞÅp¾‹ÇÓ"—Ø Wb ü² v±€<äÊFëŠóü]‚Fş™ğmÏûñ,»†0MOŞ‰ ’ô^!gœäÈÅ£p¡ u×gœcÎ¦–#Î=ÏÔH»Ï~Æà´—sğnéĞ÷ê„:™PP²É/,»à#Ş+ n„î?Ø¼-ÙúãD[4UòKº)©s ÿçÓ3„r¦y^ä™ÁÈ¦CÆĞdœ_¢šT‚ª¼ˆrf^jjîºNş/§N<¸üo4ª‹şßz}¯ÿßƒÿ7{­ÈßÒı›¹À¸TÂ_µ¤»(ŞK¥¿<—°_&eÀ“nš%lx ´åĞ˜ŞHd^Ä§˜[÷¸ÎèÓá³1¼;?òà¬É’ïÑ3¾ú
ÏÇ‰ÿ×{Kú½ˆÿ?Iı€Óf=ıÿ
ÕSRË[AÙTÓŠåmô?†—Zè{×®ÿÔÉ¬ûêãÚüÏÚRü§Ò(~ÿÓÓÒÿ’ËS¾qç_öˆ?ƒœsò-qdóş¥³İ+àÇs­Pz%aÒ3Oº
T;tPNğœ¸¿ŒÅxÀç&=?ø–Ê¿_•unF>¿ =!!j×ûï'nUˆÇ¿oüÿw€kã?{Íeÿo¥ÿEü?gŸÈ?C¾`ÿzÑõ‡ÖïW¸õ¿x±ÇÃ¯ÿj½ZYôÿUwÿßSôÿ%wà=…ğ²kqùìş¨˜Œ_‘×ÇyÕUá—´õ9òôò¾©} mˆ)>cÎÉô‡÷âÌ× ã…ôqMLn{3BYr{|@	ç<hı4CÄõ!2É›¸‰3,™ ØïiwoâD¼åñø¶8g†é¶HÇWb]Ís}òáä³\%Ó+IR’t˜-[SW½Y0·*h[«	cNÜåFêõ·Ş‰4îs½uÌ³*é[X«)>Ù¼†EsQŠR”¢¥(E)JQŠR”¢¥(E)JQŠR”¢¥(Eù[–ÿÇÓİ›    