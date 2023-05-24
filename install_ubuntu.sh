#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1712970126"
MD5="bd19705297954278a3c2462095c492ce"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="Next Generation Minecraft Installer (Ubuntu Server)"
script="./install_server"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="."
filesizes="5394"
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
	echo Date of packaging: Wed May 24 13:25:57 UTC 2023
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
‹     í=ûsÚHÒùYÅXön’[#6pë+o>bHÂ.À›Kí¦RBŒÖz°zà°ùò¿_÷<ô m;qV“Ti4=İ=3=ıš±V~rïeJ£ÑÀŸ•Fm/ıS–'•ƒƒııƒ
ÔÔŸìU*õZå	©=y€¡îòÄğLLuƒ®øîºúGZ´òIç¸İ´5Ç¼Ïñ¯×ë«Æ¿ºW—ãÓæÂ^e¿Z‡ñß+ÆÿŞËigHN,ƒºU”co:÷­‹IHÏIu¯ºOZúÌ2É±çÏôÛÒåŒú–ç+ êÓÑœ\øºRs—Œ}J‰7&ÆD÷/è.	=¢»s2¥~ ¼Q¨[®å^Ğ—_† xãğJ÷)|l=<ÃÒ1=#r¨ê!ö7¶lgá„u Z¨ÏY'&ÕmÅr	ÖÉ*re…/
‰OƒĞ·„±K,×°#qÕ¶åX¢lÎ( 4
€Äs—8iñ'edM£‘m“]bZz…ğ2À—Œ“»HGÙóI@m[àÍhM°cß êSdh(Xà›«‰çd)±eù.tIYÓ–±ÿ Fˆoğó±gÛŞ’fx®i!EÁ¡¢¡Jy3Êháãëz! ÊQÀ˜&£*ª‚‰nÛdDÃ _`¯"ÇÇîañ¸¡¥Ûdêù¬¿E25èÿM›z¯†o›ı6éÈY¿÷k§Õnµ9€gu—¼íßôÎ‡¾è7»Ãw¤÷Š4»ïÈ:İÖ.iÿ÷¬ßH¯¯tNÏN:mx×éŸœ·:İ×ä%´ëö`w`*Ğa`‡T§=@`§íşñxl¾ìœt†ïv•Waa¾êõI“œ5ûÃÎñùI³OÎÎûg½AºoØn§ûª½´OÛİ¡½Â;ÒşÈàMóä»Ršç€}ñ#Ç½³wıÎë7Cò¦wÒjÃË—mÀ¬ùò¤Í»¢OšÓ]Òj6_·Y«@é+øÇ¼}ÓÆWØ_ş;½.’qÜëûğ¸Tö‡qÓ·A{—4û2äU¿wº« ;¡Evİ6‡‚¬&™Oğù|Ğ’V»y°ØI”kÊ“¢|gû@ıõ?Œtã2š–ïkÿoÔj7ĞÿäşPÛ«úß×ÿ©$N<Û¤şCé09Ç¿Ş¨úßC”!îşğ÷l>Pj|Ğ*<…ÏjN-—¾>	Ÿ-Å>ğı¬Ë…`ÛøÈ>¼ı_Ù;€½!kÿÔöŠõÿe{«<²ÜòH&ŠaSİW¨1ñˆú–Ú†çPiZtéÇ¼¦.õ¹¡”„Ÿ>ÔßRkL¶ÈúL'¥Ì%fNü?‡tJ*RúSP®Bï¢İï÷ú[ğ)9Ö]°:À¾sd¦Û`p2 bf²5r
#…öˆ\ihä0(qôK0X"4”Bf¢!55zó!µHÉ§ŸÅ—¼^\ˆêG+TÆ'8â ÉTš‘Ğ‰>’!e“ÎÊnvÑicM³´}=:ŒÈ·7¤ƒ5ıfèğ=7ÔG›’"Z+ÔDã«)Á–_‹ŠíE2Æ H\Á§%Ã1³ôl3‚¶oBQÈ­IÛ^¤m{qÛùÔmò¶>Ÿê@Ö„ãDÉ•Ù&™{±­K&(]&ógñş,× ‡D…WÌ½‚Cı)ıEÔñF%ïåğŞm8ÙElÎN›Ô™†s6Ör¸DÿG;ÏXS‰HìĞ„áOI}.¿úéR;ıf·Õ;U˜"…sÂèÚ\tú!D}ŠâÍ}qáWĞ:FÄ$¼ñ®ˆâPÕßå!RØ~(DâòìõËçH´b„e.Ùùåòo{¥Ÿß—?“÷÷CŞ)GTw¼ÈSD¢WÒ½H6M7rF ¶§©ŞÎ’nZSŸ9D_RØÀ‘jS·ì¹4^ ÉØ‚­{I4¾ÈP¯ô;/ÃÒ[ˆìÍ	O/dT¹æğ'1Ÿ?à+sï‘ŠÏ8İAyZÊÆïÁÑSõ÷T£ßU•Hó¹¾5ƒ2$ÑÌÀL SşV cËerA¥9P|sˆÛ	H ’ÁÂŸÈü& îÂ—/À™ûàÍáÎ]øcx.hÔáØ³ a#$¸ôÁ§7Â!à.(@ûhz8€MP …#?„–C7é?Õz“Î=_3ì†S>Àˆ­‹MÈ²	2Ñ„ktWdr l‚L Ïè–GºùFİ‡º—å™ßt„€?8øßÚoF€7½şŞ6€«‰RÛ
îÂÃ%Š3“J…T_“WR­XÚæ•<Ã0ğÑ¥¢¥ôwéÿë·›­ÓûLÿ¸Îÿ¿ß¨Uó?à±ğÿ=ˆÿ/åÊà–ÉrNuW¿ÀD‚[dÁÂS”¦\`mÃ°	ÀäCë;@Ëlñ9š4$úRÈ€ h4—,—8–…4ĞHºr°«$WcF‰nLhÎÔ‡¦(ƒhŠûˆŞàP)‘s¶· æl—Hm|äzø¨(Çj\2Ë¥O™«  èå‘Q[,0=„»X^Å•k{`SjXcËşÏŞ€YD˜‹!¬YM™„á48,—/ õh¤:˜?ÓÍrL{‰#Vbœ-qf–EAYQ¶ı±ó;˜À.•ø/È¿ÑZiì2_Û.óò¼¡åhd¬¢/úgdùÓe‚]‘H€ÁšÅZ4¼)êÄº­‘Î˜€M,˜‡.#Í%İ<ñ!ı'ŠÒé"WÂ±Áçƒç‚ğ±2L‡öº,	h­`^ğ=(äQ&éÏ,ÈÔÖ]–#dÂDğ Í‘Ï¸Ï!³Œ6J¾thŒgıÈ=ÄŸ‰ç:†L0/%yÍõ xY0zøç)ã™¤æüsY&ç?K ÂI!ÒX®ô¹Æ2hšb®J' ËNBŒŒU|g—@X{v…™S)W‚öH!+xÎîÀ;„'gs% ö˜scBf	òåˆß”J0æÔ™,sI½CŸ<Ë€~®æ˜åÛ™Á_ß{<7ì=9¯se³5²l3^Ğ¦5[İØ%âšì#é—4&º{sq‰ŸÈJµ‘Nr†kU „ğ3DS“e¬éÈ Zè(¡á…™³¬ 3hËJ:.	&¦¾7³0çŠ!#3Ô¤0›~™é,‘Ë”MnF£Kyâú¿L+ä(¨ô6…F^ôd ädà˜±‹¼äºTŸ†À^2t¿*m –p,ã&`4.˜ÆÄöÆ&‘ª'¹˜,ŒÑœŠ}6ŒÛºÁò 5¤Õ¤c=²™§·rÀ<PÀ7”ã(D9*}lıZ<‰Í§3+àT_yş%ÛnrYğ§Å­à*ğDiu,«İ?„!3=.^¯\”>tC>õ‘Q¬?Ç
PfÃèğ0`ÂX2†„¾nRG÷/POÈtl”Ô P:µ@ôcº$ß§½?t—Ï&A0¥Ã©F”,d'.‰•ûXÇ¾ïüïåÿT@Q¬2ı¯vPäÿ<dşOv³yèø#°ö*µÆ~‘ÿıUãÿ|Ïç† Ó)…) ŠúnoØ>$Ã”N(wBÔ¸<‡-pì‹TæE]T±©oX›'ÂÄ8À|›§qå*Ğd÷gXê#x×›ò4gYñÛŞ{Ğ˜'…/'#nö[å= #e©¢ŠŞtéı>¼ÇùÙ+;Í@¶¬àòùÒwïqá ±l¢ñÀt›çßjïÉ+¡ü¢­Â‡µÛ¢º˜¯ØlÏ¨oyf)ùTŒ“s%_4ŞCóØœiÅŠÑ¿õÒÿŒÁˆ8R“…S’~êA0#["•"§¬>wƒÕõÀlA‰À²ë]i©ˆaw'¨³)ËÍçQRñ ğáNü‚”èŸd/‰j«ß"Î£ÀPä@¨äAÈøÖÖ·¯æ·O|cë›ïç6O¹&×7?Èk¾ä[£–ÀØÖÖyŒÓ}äøpe/ÛùİÔI:ö÷ÅB„¬6"»üC2$ã¥„¬aÈPx-óo·_
‚ŠUåÇò! LÚí0®28	x*«ÇGF¤×æ5À`¸ô*Öªã#;Ùn\¼HÇøùP-EùÅåĞÊ”A
‡¾` 2s)‘ÇİÇCc s&bÂ—7ÈrÆ6lMßÊÀ2h¤':AS1Î9ô¦ ßQ¤êéìY˜İs¦zèı x>8a3Z¤‰œ±*\—”yÎ`eÁ¦QFóªy”šFë<ç_°íf­—Äò­g‰›µåÀÛµM9ûo×0W~Ş@v¸UËìîu»¦Ş†s#gÓ‰—eV'!çÂ5‚JºñÈ;/l•!3V©<Ø&4\QÒ§:ËÖòbad§õDuÓ=½‘#
‡)\¸0A5ô;$‹#Œ&çıâ@í‡È·á#–æ¹#IÉK©åqB6l	v¡Ì5™Ö,re/]àbª§¤sHã+3ôéË=2å\c,•~XîÑ‹?nšûœ1ÿÌ™1_ y,£Ü,¦­Ù77È[½£
núºSv2po2ùo:WuáğüQŠ1ÏX0Â¬1ïuüœL‚TÀ-î@k’|›faÿ[¡’'¿–¤Ğ‚ ÚE!’Ç`…¸ ÓuŒaáŠ s›s©…’Ë sv.Ø
 õİr¿	éví 4'£²ãò´ãØ,İJ'M~·ç?c^}eÿoeŸÿ¬ï7
ÿïWÿD~ ÿ/öİ_ÿzã ğÿ~%ÿop¤Š<¨©ÃÀª2;R…†•}Ïè+œ6dˆÁ:F²à.Ëş6.ùœDÂ„• •3YÉö.¶Ç$*8h”ê“'¼b_ÃÙºŞ¹ñşæM©WkáÇ0Õ»ºë±-…ş=ŞRĞU#’Fè<jâ]Â±\‹İ†!Sø9IWsŒşNæ=‘@%M2)B:Ó˜ˆ—«yÈÄª¯8¸Ä4©ù&cââŞ¼›e‡l
ø›×"Òû£Ä NxÄ0°}9åÈ]m>€b¤iÊ:‚ü¯ó±úš”ĞÆJyı]ï"²6JrìøÓÒ¤Sö¶µ<k\Ëóa.ªjİŠÃwzşwMéÉø»ÿ×Ø¯Ô
ùÿ8ä?k*ü“}ËáÈ¥¬fÃŠ"·ÉÁNÏNô $«•BhDª¿$‡¹‘ô‚laÀè_Ònf-Ñ“S©`#5>ÜÒh'–=jl ìÌHwj&UCf‘Èˆ#^åÄmŸXF‹ÊX:§¢,%*6÷8|Ÿn€öGÆbIjÚ(ˆçğH@$ùôcã‰ãÒpyŒSÂÅ£PÅóûVŸ“x ı¯¶tÿKÍ€Bş?"ı_
Gô%ñT‰–î‹~œ8å ”Â0ãÈaÔ5K—tˆnTœü%TÃÇH‚JKÂôz´>U4­Rû¬˜^Ş® ÏPŞ2aØÅ®À‡.Ur>ÄÍã›]ÿËZò½ë•êÂú¯îÕöÅú„ë?ÉoâVäb
ù&î€Sä|&Á«išä€²#{Ìäxõ©ƒ÷]²oX
šüê¦ÙG×$Å@XÏºï0/xµV«×X8×Š‚ÈôØ¯æ$;ŸğıçX~Äìbp€,2»6séöİ› 
ÿ7À‚óãq{y¡Q=rıo!éã!ô¿Æ~}QÿkÔûÿ‘ÈÿôujêaÍ.!³B7ÑµìAf¦jÔva¦•á/¿ïA`ñ™”ø’Ÿ* åÍ§”€è¤©÷Œ”|òé3ùı_
&š©;Ïğ'ùIıÁ,ıà”~x§Âåë®y¤òŸüñ¿ø
çÒ´üÜÎñ ~Şù„m>+^rBşq£oó8vì9SäñfÇœì &û³ç6¼k®‘xû¯^]²ÿê•Bÿ{TúŸÌ¹—VÎ7mü-†™Rî;–{LG»C=ğD\'ö!CÁÁ#^A@‡ı“Ÿ^òK+y±6}Q¬‡¡nL8±ÊWßÿ3‘‡ñÿï/ış‡ÆA­Z¬ÿGµşE òÁßxétNÏzıa³;ÜÚÚÊ1:=å£ødÑâÙjtB…–mı%NœŸ½mÅ|ùQIçâöqäräJ”ÍfÇ¸e’{*©#òßù»ü¸Ït<¥ëÇçÉYva
‰<.’´!gœäÈ•Å¢p¡ u×'\`Î¦#.<ÏÔH«Ç~Bÿ¼›sğjéˆíú„*P.Ùä]ş€§¸ÅÀíĞıûƒ·¥ [ü‘h‹&ƒJ~I7å1Uàÿ|:ò@(gšçEŒl:\MÆy%ªI%ht‹(gæ¥¦áëäÿrèüŞå„ı‚ÿ
ùÿ=øÿ²—8ü-İ™lK%üU;º‹â½TúËséûeB<é¦YÂ†GÂAWéİDæ* >ÅÜª‡uFŞ˜Ÿáİù‘gC–|ÑõW8>Lüw¿¶äÿ;(îÿœú§Ífúÿ
ÕSQË;AÙTÓŠåmô?†—Zè{×®ÿ”wõKõqmşß~m)ÿ£VÜÿ÷¸ô¿äòŒoÜù—="ÅÏ æœ|JÙ¼oé,dçÊ=âx®J¡#Lzæ‰@Wƒj‡Ê	æ™‹Û¢X(lpnÒóƒO©lAñû5Yçfäóë°ĞÒ©v½Oq1³å).ë§,ŸeÙç¸”¢"è(Äåß8şûw€kã?õÆ²şW/äÿÍÿæ]h½şzAàG€ïş½¿õ¿x±Ãı¯ÿêAµ²èÿ«îş¿ÇèÿKî@{àe×â0òÙıA1¿"¯óª«Â/iës<äçå}³ÿ´x"øŒ9'Ó~÷d¾/l k‚„dr›«˜È’›ã*ø;ÇAóì¥"®IÎØÄMœaÉÀÆxO·{'âµ(Ç·Å93L·Ez<^‰u5ÏõÉ‡“Ïr•LW’¤&$á×;SW½Y0·*h[ë	cNÜåFêõ·Óİ‰4îs½uÌ³*é[Xë)>Ù¼†EkQŠR”¢¥(E)JQŠR”¢¥(E)JQŠR”¢¥(E)JQşvåcŸÛe    