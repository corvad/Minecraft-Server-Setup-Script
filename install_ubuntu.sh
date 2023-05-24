#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2365412586"
MD5="7530596998bb2ca99b69c1b05d520571"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="Next Generation Minecraft Installer (Ubuntu Server)"
script="./install_server"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="."
filesizes="5323"
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
	echo Date of packaging: Wed May 24 14:14:28 UTC 2023
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
‹     í=ùWÛHÒùYE#˜	ÙÁ26>vØÇäs°“xlm&›7“—'¤6Ö Ã£ÃÄ“/ÿûVõ¡ÃL€Q'/DjuuUuwu]İhåg÷^v¡4›MüYiÖwÓ?eyV©Õööj•z£R{¶[©4Õg¤şìJ„ºOÈ3Ã3i0ÕzÅw×Õ?Ñ¢•º‡Ş°£9æ}£Ñ¸jü«»dü«Í
Œÿ^µ±÷Œìãïå¸;"G–Aİ€*Ê¡7ûÖù$$ÛÆRİ­î‘¶>³Lrèù3ıÜ¶tE9¡¾cå¹Ä
È„úôlNÎ}İ©¹CÆ>¥Äc¢ûçt‡„Ñİ9™R?€ŞY¨[®åĞ—_† xãğR÷)|l=<ÃÒ1=#r¨ê!ö7¶lípB‰:-Ô¬“ê¶b¹ëd¹´Â‰…Ä§Aè[ÂØ!–kØ‘‰8ÈjÛr,Ñ6g @â¹CÏ´Æø“2²¦Ñ™m“bZú,
áe€/'w²ç“€Ú¶,À›Ñš`Ç¾AÔ§ÈĞP°(À7—ÏÉRbÊ8ò]è’²6¦,c=şAßàçcÏ¶½K$Íğ\ÓBŠ‚}EA•~æÍ(£…¯ë…€*G`šŒª¨
&ºm“3*ı{õ9>v‹Ç-İ&SÏgı-’©Aÿo;dØ=z×tHwHNı_»íN›¨­!<«;ä]wô¶:"ğÅ Õ½'ı×¤Õ{OşÓíµwHç¿'ƒÎpHú¥{|rÔíÀ»nïğè´İí½!¯ ]¯“¸S€ú; º!;îßÂcëU÷¨;z¿£¼îzóu@Zä¤5uOZrr:8é;Ğ}Àöº½×è¥sÜé4èŞ‘Î¯ğ@†o[GGØ•Ò:ìˆ9ìŸ¼tß¼‘·ı£v^¾ê f­WGŞuxÔêïvë¸õ¦ÃZõÊ@ÁÏ8väİÛ¾ÂşZğ÷pÔí÷ŒÃ~o4€Ç r0Š›¾ë;;¤5è‘!¯ıãÙ	-ú´ëu8d5ÉŒ|‚Ï§ÃN´;­#€5ÄÆH¢üXSå;ÛÿêÏ¨ÿñL7.¢iù¾öÿf½~#ıïÿµze·Ğÿcü§68ñl“ú¥ÿÁäXÿF³Ò(ô¿‡(#Üıá/îÙ|
 Ôø Uxş4
ŸÕ[.5|}>[Š}àûYÿ–+À¶?ò‘}xû¿²[ƒ½!kÿ×õJ±ş¢ln”Ï,·|¦Å°©î+Ô˜xD}GmÃs¨4-zôSHŞP—úÜPJB—Oêo¨Š5&ä}¦“R	æ3'şŒC:%•&)ı© (W!„wÑúƒø”ê.X`ß92Óm0813Y9†‘B{D®45r”8ú,J!
3Ñšš
½ùZ¤äÓÏbÏK^/.Dõ“*c‹“qĞd*ÍHèDŸÈ¿²Ige7»èÆ´±¦YÚ#òí5é`M¿:|Ïõ³uI­¿j¢ñåš”`ËÇ¢bs‘Œ1(—ğiÉpÌ,=›Œ Í›P”rkÒ6iÛ¼‚¸Í|ê6y›@ŸOu k
Âq¢‡äÒ‹l“Ì½ˆØÖ”®“ù³x–kĞ}¢Â+æ^Á¡ş”ş"ê–x£’rxï6
œì!6g'ˆMêLÃ9k9\¢ÿƒ­mÖTâ;ôaøSR_È¯~:€§ÔÃÖ Õk÷Õ¦Háœ0ºö#~ÈQŸâ‚xs_\øU ´Š1	o½KâDÆ„8ÔAõwyˆ¶
Ñ…ø’l¿yõ‰ƒVŒ0 Ì%[Ÿá±\şm·ôó‡òòá~È;æˆê¹aŠHôJºçÉ¦éFÎ¨íiª7³d£›ÖÔçAÑ6p¤ÚÔ-{.Í„—H2¶`ë^/2TÇ+ıÎËpô6"{sÂÓYU.„9üYÌç/øÊœã{¤âNw`E—ƒƒ²ñ{pğ\ı=ÕèwU%Ò|.†oMÃ ÌI´c 30 Ä”¿ ÄØr™ÜCPéGßÜâfˆd°ğ§ 2¿	ˆ»ğå+pæ>xóU¸sşuxö,@X	®}ôi@ÃµpÈ ¸
Ğ>šŞ`@áÂ¡åĞuúOµ^§sÏ×Áûˆá”0¢cë|$r ¬ƒLtÂ5º+29PÖA&ĞgôË#İ|­îCİ¿ËòÌo:BÀüïí×#À›Ş	ïNÀåÄ
©mwááÅ™I¥Bª¯É+©V,móJ†a˜	ø¿èRÑÒú»ôÿ:­öñ}¦\çÿß«W›‹ù•Z³ğÿ=ˆÿ/åÊâ–ÉruW?ÇD‚![dÁÂS”–\`mÃ°	ÀäCë;@Ëlñ9šç4$úRÈ€ h4—,—8–…4ĞHºr°«$WcF‰nLhÎÔ‡¦(ÃhŠûˆşp_)‘S¶· æl—HŸm|äzø¤(‡j\0Ëe@™«  èå‘Q[,0=„»X^Å¥k{`SjXcËşÏşYD˜‹!¬YM™„á4Ø/—ÏõèL3<t0¦›å˜öG¬Ä8[âÌ,‹ş‚²¢lûcçv0]*ñ_£´ÒÜa¾¶æ9äy#BËÑÈXE9^ôÏÈò)¦Ë;"‘ ƒ5‹µhySÔ‰u[#İ1›X0]FšKºx<ãCúO†ƒÈİÇŸ‰Èä;ºL0$yÍµx9'zøgÃPB„Q†Î#ËäÔ²t‘4r©Ï5–¯â"ßÅÌ&7âšåaF
€ñ¡ŠÏªì„KÂXÛ—˜§”2Üµ?`Í[ÁnâŞ>Èù| œL@í19ä-Æ„Ì„Ûç“¿)•€ÃÔ™,sI½ûœlg@¿PsŒàÍÌü^İ{<7ì=9¯ses#²l3^>¦5[İØë#¢ˆì#é4&º{ëî,ó?‘•0jg^8É^¬M6ŞXì8Âª¦&ËÓXq("Ğ-AÃK
3gYİdĞ–UbX|½M}ofa†C&&FæƒIÑ1ü2ÓY"Ë±ã“›ÑèR¦…Ş&Ó
ùŠE„½M¡‘$=(§Ør;dì"¯¸æ2 !°‡ûJ€%ËåŒÆC”ØÁØ$ã$“…q6ç„B–ã¶îŸ³¬;i5éXlæW­Ô˜¿øæ‚€G!J-éñcë×â)c>Y§úÒó/˜pÏdÁ7„vW'J»;dISÁ>™éqavé¢ô¡3ò©Œbı9Vt!hßÓ &Œ%cHèë&utÿ"Àõ„ÅFI
¥c-&'ò]ÑûCwùlSºœjDÉrCêã’xBáñXÇ¾ïüïæÿ4j»LÿÃüß"ÿçÇ?³4:şß\ÿz³V-ôÿÇŒÿs-„L§¦€*ê{ıQgŸ°ì!!ÆåŞŒúßa`Sû"•yQ;åpê[ hçÉvÀ|—§«qu/Ğd÷'Xêgğ®?åiÎ²â·İ ¯1O(nœŒ¸Ùo•dˆ”¥Š*VxÓ¥÷{ğu„í×vº€l[ÁÅ‹¥ïj qá€ÂDãi[	Î¿Õ?×"˜‰¶V».ÖnŠê`~ÅöB}Ë3HÉ§bœD˜+ù¢ùšÇæL;VÕş­§şgFÄ‘Z,œ’|ğ3PÊ‰Ù©9`õ©\]Ì”,{Ş¥–Švp¿„:›²Ü|%
nÅ/H‰şIv“(¡v•ã[ÄyŠ•<ßÚêöÕüö‰oluó½Üæ)×äêæµ¼æK^±Õ0ê	ŒMm•Ç8İGWö²™ßMƒ¤c_-ÔHÈÊ`#!²Ë¯0”!CB0^JÈÊà†…×2?ğ¶vû¥ ¨XU~,Ê¤İã*ÓÑ“€§rõøÈˆôÊ¼—^Æz~|d'›âÀÍ—é?ª¥(¿¢¼º2eAÂÆ!…/˜¤Ì€KEäq÷ñĞ<Iãœ‰ØƒğåÀ$ó€œ±[“Æ·2°Í)SÎ€ÎB0ÄTŒsN ½)Èw©z:{f÷œÁ¦:À;÷À	ÛÀ˜%Hä„Uáj¸ Ìs+6…ˆ2š¯šG©i´ÊsşÛ®×zI,ßªq&¸^[¼]Û”³ÿvsåçm d7[µÌî^·kê­97r6xYfur*œ5( 0¼ùÂVY2ó™ÊƒmBcÁ%½< ³l,/FvZOT×İÓ›9¢p”Â…TC¿3A²8bÀhr:8B!Ô~Œ|>bi[â™”¼”Z'$aÃ¶`ºå\“iÍ"·PöÒ.¦zJ0‡4¾2@Ÿ¾ìb$SÎ5ÆRéæ>Æøá8ºÏóÏœó’Ç2ÊÍbúØŠ}s,°«wTÁM_wÊNîM&ÿMgâ‚gU8<”bÌ3Œ0kÌ{?'“ 0F`‹;ĞJƒ$ß¦YØÿVB¨äÉ¯%)´ €vPˆdÆ1˜D!.Àô@£¯_'cX¸"hÇù\ªE¡ç€ä2Àœ¶Hı\·ÜoBº];¨ÍÉ¨ìº<í86K7ÒI“ßíùÏ˜Wíÿmìòó?µÂÿû(ãŸhÀäÿÅÓ¾{ãßhÖ‹óŸäÿT‘õ1uXUfªĞ°²ï¹ }Ó†Œ0|ÈÓHÜÅ`ÙïÃÆ%Ÿ“Øœ° r&+ÙŞÅö˜DrA}ò„×AìkXC#[—áD7Şß¼)uãj-üÆÉ®îzl‹cÉ†“)h*‰É#ôÇñ.áX®ÅnÃà`Äãí±G´5F'óH ’&yÈE:Ó˜ˆà«yÈÄª¯8¸Ä4©ù&cââŞ¼“e‡l
ø›×"Òû£Ä ±NxÄ0°}9åÈ½Ú| ÅHÓ”U&?.ø_çSõ)¡•òú»Şyd)l”äØñ§¥!H§ìmjyÖ¸–çÃ\TÕ8ºW(ßéùßy¦$ÿáïBş_s¯Räÿ=ùÆš
ÿdßÂòE8r)«Ù°¢ˆÁ­³E°Ó³=(Éãj¥‘ê/ÉáBn$½$0ú—´›YKôä”@jØH…·4…ÚŠe[3’ÆšIÕˆY$2âˆW9qÛ'–Ñ¢2–Î©†hK‰ŠMã=ß§ ı‘±X„Z6
â9<R'iGƒØxâ¸\ã”pñ(TqÂßº¬:'ñ@úÿn}éş—fe¯ÈÿxRú¿èKâ©,İı8qÊA(…aÆ‘Ã:
¨k–.è<İ¨8ùK¨†‘•–…éõh-|®hZ¥şE1½¼]AŸ¡¼eÂ:°1Š]]ªä|ˆ›Ç7»ş—µä{×ÿ*Õ…õ_İ­WŠû_âúOò›¸¹˜Ô¾;à9ŸIğj™&9ñ|¦oÉ39^êà}—ì–‚&¿ºiöÑ5ÉG1ÖÃvÏóæ¯Öë:çàúAQ™;`¡ãÕœdë3¾ÿË˜]ÅBf×f.İ¾{@¡óÿXpŞq<nï!/4ª'®ÿ-$}<„ı_­Öõ¿f£ÿODş§¯[PS+v	™úô4Äçh˜?gz!«×ÃP7&¼rYÕUUáa­®°{4­ùµ‚Y_H‰Ÿ½ù©Rhó)% áé'jàu(%Ÿ|şB~ÿ—‚ù0êÖ6ş$?©?˜¥œÒïUØX}İ5Tş“_Ö#şßÔã\˜–ŸÛ9>Ä/[Ÿ±ÍÅÀ»XğË}7´‡3Å'Ş•™×„(eß©+]­…X~<ùŸMÛ{û¿Q]²ÿÕBş?)ı_¹¢ï›í‹aÆ”û–åÓ³ˆİ¡x"®—
û‘‘Çàà¡Ã  ‡£ÁÑO¯x„­‰	†¼\™¾²¼‡<şúOÄ&ş³·ôû?š5Ìÿ(ÖÿZÿ"}‡à¼tºÇ'ıÁ¨Õmlld˜ŸGòˆY|²lñ´¿Fº!‰BË¶ş¢<åìä];>rÎïb8ßÅãi‘Ël+1P~Y »X@rHe£uÅùş.A#ÿLø¶çÆıø†–]C˜¦'ïDIz/ˆ3NräN†âQ¸P€:Çë3Î1gSKçgj¤İg¿cpÚË9x·tè{uBL((Ùä–]ğï·B÷ìŞ–ƒlıñG¢-šŒ*ù%İ”+zÀÿùôÌ¡œi§2ÙtÈšŒóKT“JP•QÎÌKM-Â]×ÉÿåÔ‰{—ÿõzuÑÿ[«Õùÿ=ø³×Šü-İ¿™ŒK%üUKº‹â½TúËséûeR<é¦YÂ†ÂA[éİDæU@|Š¹uëŒ¾1>Ã»ó#Îš,ù=ã«¯ğ|˜øÿ^½±¤ÿ÷?<Mı€Óf=ıÿ
ÕSRË[AÙTÓŠåmô?†—Zè{×®ÿÔÉ¬¯ÕÇµùŸ{KñŸJ‘ÿÿÄô¿äò”oÜù—="ÇÏ çœ|KÙ¼é,d÷
xÄñ\+”B	F˜ôÌ®Õ”<g î/c1°Á¹IÏ¾¥²EÅïWe›‘Ï/hCOHH§Úõ>Å¯·*Äãß7şÿw€kã?æ²ÿw·ÿEü?gŸÈ?C¾`¼èúMBëÿ wŒªßßú_¼Øãş×µV­,úÿª»…ÿï)úÿ’;ğBxÙµ8Š|vTLGÆ¯ÈkÇã¼êªğKÚúyzyßì} mˆ)>cÎÉô‡_Å=™¯Æèãš !™Üö*f„²äöø€şÎyĞ<ûi†ˆëCd’;6qgX2°1ŞÓîŞÄ‰x-ÊãñmqÎÓm‘¯ÄºšçúäÃÉg¹J¦W’¤&$é0[¶¦®z3²`n!UĞ ;·VÆœ¸ËÔëo'¼iÜçzê˜gUÒ·°(VS(|²y‹æ¢¥(E)JQŠR”¢¥(E)JQŠR”¢¥(E)JQŠò·,ÿUŞA    