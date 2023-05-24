#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2379507590"
MD5="2239e885a5931e5cc4b367e65ddaa138"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="Next Generation Minecraft Installer (Oracle Linux)"
script="./install_server"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="."
filesizes="5385"
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
	echo Date of packaging: Wed May 24 13:22:40 UTC 2023
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--notemp\" \\
    \".\" \\
    \"install_oracle.sh\" \\
    \"Next Generation Minecraft Installer (Oracle Linux)\" \\
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
‹     í=ûWÛÆÒùYÅDĞ6¹Å666¾åšÏ'ñ½`slÓÜœ6'GHk¬¢‡«„æËÿ~gö¡‡-˜@JªMNˆ¤İÙ™ÙİÙyíR­=¹÷²‰¥İnÓÏz»µ™ı©Ê“z³¹µÕÜl7›Í'›õúövó	´<@‰ÃÈ ˜¾ÅÂ™a²+ê]÷ı‘–jí ·×íºU×ºÏñßŞŞ¾jü›Ûéøom7pü·Û­'°Yÿ½—ÃŞl“y!Ó´=vØ§Ó™Ï¡±ÙØ‚}ãÜ¶`ÏÎSÇ64íˆ®†¶ïÂ”ìäNÃ‹˜µ“€1ğ'`Nà”m@äƒá]ÂŒ!6ğO"Ãölï0±/kFSú“èÂV¶ÀCß´„–oÆ.ó"#¢ş&¶ÃBxMè#ÙBÎ;±˜áh¶ôM}‚;šúq£À6	ÆØéÄá >;¶kË¨9g@¨!Ğ8D
Ïp}ËĞOÆÉšÅ'N7À²	ôIáË^rNn5?€9†lÄ›ÓšbÇëê3bh$YÒ›‹©ïæ)±CmvÉxËG–ñgfDo¨úÄwÿ‚H3}Ï²‰¢pGÓÆøÉ8ñÏ§EŒ¯çGˆª@`–ªüNÇ&†ı"{9u‹Ç‹lÃ™ğşæÉ¬bÿoº0¼¿í»ĞÁÑpğKo¿»zg„Ïú¼íßÇ€5†şø^A§ÿşÓëïo@÷¿GÃîhƒ¡Ö;<:èuñ]¯¿wp¼ßë¿†—Ø®?ÀIÜÃ©Œ@Ç %¨^wDÀ»Ã½7øØyÙ;èßmh¯zã>Á|5B:Ãqoïø 3„£ãáÑ`ÔÅî÷l¿×5Ä^º‡İş¸Š½â;èş‚0zÓ98 ®´Î1b?$ü`opônØ{ıfoû]|ù²‹˜u^tEWHÔŞA§w¸ûÃÎë.o5@(Cª	ìàí›.½¢ş:øwoÜô‰Œ½A<ÄÇ¤r8Nš¾íºĞöFÄWÃÁá†FìÄÛõ»
±r#‚UèùxÔM Â~·s€°FÔ˜HT•«Ú“²|cûÈ‚s|81Ì³xV»¯ı¿İjİHÿû³Uo”úß×ÿ™ƒ$N}ÇbÁCé89æÇ»İØ,õ¿‡(cÚıñ/íÙb
„¨Ô¨UøÁ%jÿrh{ÌŒIb¶”ûÀ·³şmW€ã|#ûğö}³ÙjÎËÿíV½\ÿQÖÖNl¯vb„SÍt˜hÌœú ¿eé»L™}ö1‚×Ìc0”RĞÓ‡OuÍÀSøİ87 RÁ¹ÄÍ‰ÿGãÍ Ş†Ê‚ò4 ÑEw8ŸbUØ3<´:Ğ¾CsäÜpĞàä@äÌä=VáGŠì¸Ş®Âb2p34Xb2”"f²!³ª:ö¸RjA%˜dŸå—¾_„êG;Ò&¶ 9â’ÉT9‡È?Â÷?CÍbç5/F»èÆ´ñ¦yÚ¾f8+ÒÁ›şeè|/2NV%E¶şZÔ¬Í“O.ò¤¬qZÖnBµ½5!kó”¬]AÊZ1-k’˜µ‚±™ >qu+¦k­8@9_k”f =3S#‚?v,¸ôcpì3.(=ƒ&÷g‰¾8$Ïd; ã+î^!æü
•?A_—otx¯øp7,ç˜Ø'lLÁI›ÌE—œŠÙÿîú3ŞTáƒ;
aüSÑŸ«Z?îâSæa}Øéïõ9¦(áœ2»bœ~Äù=Ãùæ¾¸ğ‹Dh#ŞøàÆæ\æ’ú»8ÄH
ß%‚äB|Ï^¿|NÄa+NRæÁú'|¬Õ~İ¬üô¾öŞßy‡QÃõc/ÊI^Iï4İ4½Ø=Aµ=KõZlrÓZÆeX@ôÃœ¨¶Û¹TfÂ"™Zpé¥ˆ¦9ªÁugñ2Gú>!{sÂ³JCU.Â9üIÎçÏ¬e]Ò{¢â3Mwd?ÔÂİšù[¸ûƒş[¦ÑoºÊ|®…f`Ï¢°& )´ çà\SşV cÛã"@ePzsˆk)H$’Ã¢ŸÈåM@Ü…/_€3÷Á›/Â»ğÇô=Ô¨£;°gÂJH5èCÀB­„CÀ]PÀöñì.( « €ºF}ˆl—­Ò¦õ*ûfØ
§|ÀØ§« Q edâ®ñ]‘)€²
2¡qÎî°<²ÍWê>2‚»,Ïâö¨#ú!`àÿnĞ~5üÙğ÷ï´\Líˆ9vx.ÀĞÜs¥T(õ5}¥ÔŠ…m^+Ò0L+ÿ—]jÕÌ‚ş6ıÃngÿğ>Ó?®óÿoµ[õùüz«ôÿ?Œÿ/ãÊÑ–ÉsÏ8¥D‚_0ŠqáiZG-4´ñÚhò‘á’Ñfø%™§,c!d šÌ%Û×öâˆ…Uè`W.u•æjLÑ(1Ì)³™Òâ¨jÚ(Ñ>‚¢c0ÚÑ*pÌ÷Äœ¯á
øÆØÃGMÛ›2óŒ[.CÆ½!—GE5± ôáAàyã£YÎ˜iOlSù?#nQ.†´f«Ú4ŠfáN­vŠ¨Ç'UÓwQÎ«–Ğ^ˆU8g+‚™5Ù_XÓ´5dâ· ¦¸K¥®ø7¹AëíîkÛàC‘7"µœ*Œ‘ULàÅşˆí€QºL¸!i0Z³ô•Ì#F:±áT¡7´‰%óÈ_ä’¹d8¡/2>”ëDÓ†2]äB:6Ä|ğ=´C1aéØŞ0ã'M±Î±ç#…"Ê¤\9ˆÌÃã9BNÑ<	8÷dqÂG)Pƒ*çÙ0övèg*Ä…Q§”—’¾z¾¦,#úæ)ç™¢çşsÛ–à?O ¢I!ÓX.ŒË*Ï áhÊ¹ªœ âQn <;‰0F0~ó<¿ÒÀÚ³ÊœÊ¸ª¿£²ÃçÂèıÜyrğ‘p>WBæL`O8×8rK`G,GªS©à˜3wUXä’~‡><Ë~®˜åk¹Á_Ş{27ì=¹¨smŒ³5¶+YĞ–=™ [½Ä%ãš¼’rHšSÃ;Å¹xËOUÔGµ?š/}MUDºÒÏÏ,±f˜(Hh‘£„EgÎ¢Ì¡-*é´$¸˜ş¹M9W™„•¡¦„ÙñËMg…¬\¦|rs=&ÇÈÿeÙ‘x AMğ°·6òÃ´'“$' {œ]ğRèRC!{iÈÈı²£uXÊ±œ›€Ó8gƒã›œM2UOq1]'—b€HìóAàÜ6‚SX%Z-61b‡;yëMîB¾‘¤˜ÄÉQåƒäë×Il;·CAõ…œñí¦`%ßDZÜ\Ehû½OãêwpÈ,_ˆ×¤;Ç!ŸÄ(ŞŸk‡$óat¬‡LC˜8–œ!Q`XÌ5‚³Ô—2¥_H(Ú(ú)]RìÓşï†'f“¤™ÒTJ¶‡²“–Ä•ûDÇ¾ïüïæÿ4[m®ÿµËüŸÍÿÉo6ÿßÓÿ[íæV©ÿÍø¿Øó…!ÀuJi
èò{0îîÀ8£ª´#!Ïqœ2•y^BUlØ(Ö.Sába¾-ÒŒ„rVU÷G>Zê'øn0iÎêÃ¯›ïQ;âP¾‚Œ¤Ù¯õ÷0"GÊÂ‡}ğgï·ğ=íÈÏ^91j.rßÏ/Ôk¾GÄ¥wÅ²EÆ×mRœm½‡WRù%[+Â=¾®ÉÏÛˆù›ílßJ!¥Uå8É0WZ£ı›'æÌ~¢ıÛÈ ıÏŒŒ#ux8%­ğRª€;
©9udõ±^ı™-)‘Xöı‹j&bØ¥İ	¿9Œçæ‹(©|ĞDˆp=yöl¦QÂêUoçÑp(
 Ô‹ ä|kËÛ7ŠÛ§¾±åÍ·
›g\“Ë›7‹š/xÅ–ÃhÁ(p¬U—ùpU/kÅİlC6ö÷ÅB Kƒ ªË/0T!C Š—,QÈPz-‹o+·_‚ÊU$ò!d\Ú­s®r8xjWŠH/ÍkÀÁğØE¢U'Gvò)Â¸x‘ñ‹¡ZˆòË!*¡+S$)|2ø¢ÈÍ¥LDvŸŒ,Î¹ˆ=
_Ñ É™8¸5UÅV†–ÉÂ0c8™ØY„Ê¸œŠIº	¢7CùN"ÕÈfÏâì¾äªwHŞ„wp€S¾q£E9àˆ¢ÕpÆ¸çWn
1ã4_52Óh™çü¶]­õ‚X¾Uã\ qµ¶"x»¶™èİí
ĞÛ Èo·j™ß½n×Ô_qnl:É²Ìë$p,]#$ ”Ş¡|á«,Œ¸±ÊÔÁ6©±ĞŠR>ÔY..NvVOÔWİÓÛ¢pœÁERC¿1A2?bÈh8Gj?Äƒ•xšçº|†ŠŸQË“„$j¸/ÙEN0ÏâZ³Ì½S½ô‘‹™ÒÜ!M¯¬Òg,:ô`&¸ÆYªü°Â£—T‘nšûœ1ÿ,˜1_ y,§ÜÌ§-Ù7WÈ»zG•Ü·ææàŞdòßt&^!x–…Ã‹G)Á<gÁH³Æº×IğS:	2c6¿-5HŠmš¹ıo)„z‘üZBshƒ„HnÃiÑÌ4yÖ˜àÂ•A;î6R-|%—‰æì¥d+‚4NÛûKH·k5d•=Od'féÓLÒä·{ş3áÕWöÿ¶ê›üüO³]ú¿ÊøßCºË5÷¿Ô›­ÆÂùÏVyÿÇWòÿ†»ºÌƒú9¬kç»ºÔ°òï… }EÓÆ¬i$sîb´ìwpãRÏi$LZ	øñ\}ä{ßcR5Ê9õÉ—^¹¯Ñ;†
ŞyÉşæÏ˜—|®F£$TïÏ·8ú÷)xËPsÔ!A¤ŒÔDÔ4¢»08<‚c{6¿C¥<ˆ#*Š®Î„üÜ{¢€*šTR„r¦0/×‹IT_yp‰kJóMÇÄ£½y#ÏÕñ·b¡Ed÷G…A&>œ&ğÈaàûrÆ‘{µù€ŠQµª-3!ÄqÁÿº¯¡B6VÆëïù§±­ñQRc'† Ÿ²W`Œ¯U‹|˜óªš@·XqøVÏÿ.É3} ùçä{«Qÿ}$òŸŒ5ÿÉ¿ÅåKpÔRÖóaEƒ[e‹à§g§FXQÇÕ*6‚ÆÏé©Ba$½€§»0ú—²›yKòäTPj…ÔHO„°4¥ZOdëçÅYé§1·HTÄ‘®r¶O"£åÇD:g’¬$*5Mö8zŸm@öGÎbIê8$ˆ/ñ‘¹¡Lò&Æ“Àe(áŠ§‚KG¡Ê+şæ÷?\}NâôÿÍÖÂı/íúV³”ÿIÿWÂ‘|I"Uâ¥û¼'I9ˆ”0Ì:rDG!ó¬Ê»e7:Mş
©á"A‡½Š«q½¬…OõjµŞú¬Y~Ñ®`œ“¼åÂ:t(Š]ÇŠÓ
*Òæñ—]ÿ‹Zò½ëõÆÜúol¶êeş×c\ÿi~“°"çSÈWqçs	^Ë‚#: €Êê1—ã5d.İwÉëğ4Uë¦ÙG×$%@xÏú~àr/x£ÕÚnñp­±åó]Í	ëŸèıçD~$ìâp,2»6séöİ[Šœÿ7ÀBğNàQzÈÿvúß\ÒÇCè(ôçõ¿v»´ÿ‰üÏ^· g–ì*+t±š?ÈÌU­fKãwU«5ü+î{X|†Š8Bòc½‰ZŞåŒŠNö‘™tÏH%€OŸá·i”h²«¯?£Ÿğ£şUùÎ­|÷NÇ+0<kW?Å-8òÉ8î™e…Ó#Bü¼ş‰Ú|ÖLºäşq£ºEÛóİ	òd³ãÎ~P“×ì¹ïšk$ÄşÛn,ØÛRÿ{TúŸÊ¹WVÎ_Úø›3eÜw<÷˜ÄüõĞ—qLØÆ>‡CG¼ÂöÆÃƒ_ŠË~6&"òbiú§Øˆ"Ãœ
bµ¯¾ÿç"ãÿßZøım:T®ÿÇ´şe òÁßdéôÃq§?~úôiîˆÑáñh¬%'‹æÏVW¡AÙı§<q~ôv?9à+JR8—°ObOX(W âh6?Æ­’Ü3ÙH=™ÿ.Ş¥hŸÀ}fĞ)İ 9OÎ³+€+$êºLÒzRÎ¸é‘+Š%áÂê%]ŸpJ9S”ZˆŒ8õ}«
ûş†Çı‚ƒWGl—'T©€rÅŸytùâ–·‰B÷üİ–Blış{¨Î›:üœm*bªÀÿìÄG¡œk^yä0òép	4çU¨¦Q£›G97/«zî¸Nş/ÆÎï]ş·æó›MÊÿ*åÿã÷ÿå/qø[ºÿrw×V*ô«vÄ{¥ò§ï±]şË„L|2,«Bw¥ƒ®™³»‰­«€Œr«Öyc:>†wçGœYò-zF—_áø0ñß­…óÿü× –òÿêÿCš6«éÿW¨òpˆ^[k–U,o£ÿq¼ôRß»vıg¼«_ªkóÿ¶ZùÛåıKÿK/Ïø‹;ÿòG¤ÄÔ‚“O©£ Ÿ÷­œ…ü\¹®ïÙ‘ò*0Ò¤çr¸¤v¨œP¹¼-Š‡"Ğ&½8ø”É”¿_“wnÅ¸‹<!›U¯÷)Îg¶ü@ËúÏ²ès\HQ‘t”âòoÿı‚;ÀµñŸíö¢ÿ·QÊÿ2ş[ÿ-ºĞz>üõ‚À7 ß%ü{ëşb‡û_ÿf£>ïÿkl–ş¿ÇèÿKï@{àE×â8øıA	9¿¢ø:™}nH¿¤c\Ò!?¿¨ÎÖ{Ø‰x²wNf+~÷d±˜,l¤Oh‚ ¹Üæeòäæä€
ıÎqÔ<Y†Èë#T’35ñRgX:¨1İÓíİÄ‰x-Ê“ÉmqÎÓm‘L®ÄºQäúÃ)f¹³+IÒS’èÎëõ™§ßŒ,œ[D6ÈÏ­å„q'îb#ıúÛéîDšğ¹Ş‚:îYUôÍ-ŠåJŸlQÃ2µ,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,»ò?•]
9    