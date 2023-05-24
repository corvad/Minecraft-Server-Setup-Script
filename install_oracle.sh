#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3120434329"
MD5="010950ca7814fd74cdaff16af41e6259"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="Next Generation Minecraft Installer (Oracle Linux)"
script="./install_server"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="."
filesizes="5398"
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
	echo Uncompressed size: 96 KB
	echo Compression: gzip
	echo Date of packaging: Wed May 24 12:36:35 UTC 2023
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
	echo OLDUSIZE=96
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
	MS_Printf "About to extract 96 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 96; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (96 KB)" >&2
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
‹     í=ûWÛÆÒùYÅDĞ6¹Å666ÜË=´ŸNâûÍ±MssÚœ!­±Š®7_ş÷ofzØÂ€	$$ÚrJ$íÎÎÌîÎÎk—jíÉ½—M,;;;ô»¾ÓÚÌşVåI½ÙÜÚjn6¶êõ'›õú6~†Ö“(qÀÓ·X85LvE½ë¾?ÒR­v÷;½a§êZ÷9şÛÛÛWcs;ÿúÿV£µı6Ëñ¿÷rÔÁ¡m2/dš¶ïOg}6‰à™ù¸áÀ¸°-Ø÷ƒãÌ±M;fk‡¡í{`‡0a;ÁY`x³6`0şÌ‰œ±ˆ|0¼LYbÿ42lÏöÎÀ ûÒ°f4A0¡?.€aeŒ0ôMÛ@x`ùfì2/2"êol;,„gÑ„>”-ôç¼‹f{@ßÔ'¸´£‰G°0
l“`l€í™Nlê³c»¶ìšs„C¤€ğÜ ×·ì1ıfœ¬i|êØád,›@ŸÆ¾é%çäÑQó™ãhÁF¼9­)v¼¡>%†F’E!½¹œøn;ÔÆqàa—Œ·±|dïñOfFô†ª}Çñ/‰4Ó÷,›(
w5m„ŸŒSÿ‚qZÄøz~„¨
h ¦é¨ÊOáÄp8e’aØ/²×ÈP÷¸x¼È6˜úïoÌ*öÿºÃşËÑ›ö İ!ú¿u: ·‡ø¬oÀ›îèuÿdXcĞîŞBÿ%´{oá»½ƒèü÷xĞ¡?ĞºGÇ‡İ¾ëööOº½WğÛõú8‰»8•è¨Ô¡Õí	ØQg°ÿÛ/º‡İÑÛíewÔ#˜/ûhÃq{0êîŸ¶p|28î;Øı‚íu{/ØKç¨ÓU±W|ßğ†¯Û‡‡Ô•Ö>Aì„ì÷ßº¯^àuÿğ ƒ/_t³ö‹Ãè
‰Ú?lw6à }Ô~Õá­úe Q5¼yİ¡WÔ_öGİ~ÈØï÷F|Ü@*£¤é›î°³íAwHy9èmhÄNlÑç@°]¯# «!7"X…O† tÚ‡kH‰DU¹ª=)Ë7¶ÿ‡,¸`ÁûSÃ<§µûÚÿwZ­ébÿo¶6·JıïKŒÿf½‚?’ÚÿV«Qêÿ_zü§R;ñ‹÷ªÿoÖ7wæÆg§±SêÿQF¤ıá™áæš6ªqF„J²Ğ-æ0ÒÈIiÊ¦„ˆYSªxıÛ® Çy/äÀÃûêhîoÏïÿÛ[åú²ö´vj{µS#œh¦ÃŒ@cæÄısLßeÊ´ì±¼b„¡|d{ÌŒq]1}XğT×ì1<…?*œKÜœü?8Øê;PùKCP ºèıÁS¬
û†‡V'Š4G/Ç¶93yU8ŠIŞ0P€ë;U8FŒC®qkL†rDÂL6dVUÇŞÄÜ†J0Î>Ë=/}=¿Õv¤mArÄ%“¹r‘€šÅ.j^ŒvñiãMó´}9:Ì8pV¤ƒ7ıRt¬Í/ót¬qBÖnB	µ½5!kó”¬]AÊZ1-k’˜µ‚QÁÍ•]bİŠéZ+NÄ—¥€HÏÅ	×%üØ±`æÇàØç\´x‰î}qHÉvAÇWÜ!EÌù*ƒ¾.ßèğNñánXÎ1±GØ˜‚“(h˜;fœŠÙÿŞú3ŞTáƒ2.
aü¯¢?Wµ~ŞÃ§ÌÃú İ;èésLQâ,evÄ¹I‰ò{†òÍ}qá7‰Ğ2F$$¼ö/ÁÍ	¸ÌõƒYÁ#)|‘’şø+<{õâ9‡­8aH™ëñ±Vû}³ò¯wµOğî~È;ˆ®{Q†Hòãzgé6ãÅî)rT¯åÉ&Ç¶eÌÂ¢ÏnyDµeØÎLjÉá¯D2µàÒKM/rT'‚ëÎâeôBöæ„g”†ÊO„sø£œÏŸ$XËšÑ{¢âMwd?ÕÂ½šùG¸÷“şG¦ÑºÊà¬…f`O£°& )´ àBSşV cÛã"@ePzsˆk)H$’Ã¢ßÈì& îÂ—ÏÀ™ûàÍgáÎ]øcúê ÑØ3a%$ß‹ŒÓ÷Y´9 wAÛÇÓ»   ¬‚÷¼l—­Ò¦õ*û†Ë{
@½ÇÛg« Q edâS®ñ]‘)€²
2¡qÁî°<²ÍWêë»,Ïâö¨#ú%`à¿nĞ~5üéğ÷ï´\Nìˆ9vx.ÀĞÜ¥T(õ5}¥ÔŠ…m^+Ò0L+ÿ–]jÕÌ‚.ık_¿ÿoĞiİgúÏuşÿ­­æ|şO½Ù(ıâÿË¸ò†¤ ğœ#Ã3Î(‘dÈ5c#šÖV‹Bz!"äFÉ…ÀŒpFÆÏ‹ÀÈ€•âA“ñg{àÚ^±°
mìÊ¥®Ò\	šX†9aa6SGÚOUMÆSÚQö‡»ZNøN‰˜s‰T>ßÆá{ø iûfs;lÀ¸Ï#Tt`ìü¥c ”$ü!<¯æÒs|4òÂ)3í±m*ÿgÈí;ÊÅ‘¶yU›DÑ4Ü­ÕÎõø´jú.j”Á…aÕÚ+±
çlE0³&ûkš¶†ìO¼0ÔÁ÷ÜÔÿ!7h}gƒûÚdÆ¨Â9Ä:ì¯ØeI…2
á¡IN_ÉÆó§¤ØNºc@Ã^òŒœ^.Ù|†ú"ÑGù4m ³„.¥wFLßCc6Cæxí3yî×[átŠªx÷G!jòxj˜…ãï#š§gº€ÌøàÊûQå¬ÄŞ.ıNw"¡(UÃ	¥#¥¯…2‡¯)ùÉˆ~¢éÉy¦ha­³Ø¶ÛyŞÍ™½tiÌª<qŠ£)§¨òdˆG¹ŠPbŒ`ü$¦w~æ[Hº‘×áÙ%%Ìeü!Õ?QøØásá9ı]Ü>sğ‘p>EBæŒa_x9r3W¬BªS©à˜3w
UXä’~?><Ë~®øÖrƒ¿¼÷d0nØ{rQçÚgkl;V²-{<F¶z‰3MÌ8QIyUÍ‰áá\<åŒ§*ê#Ú©/›ùá¥¯©>“È?W:Kâ©Å—>É*òö°è’áÌYÔâ9´EKƒ–_øÓÀ¿°)Õ#“£•›"~¹é¬•Ë”OnN£ÇD¾ 9ñ,;$Ÿ	ö6ÅF~˜öd’Àä`Ÿ³^…pÀ"d/ùvµK9–óupçì{p|“³Ifh*.¦ãt&ˆ¤½ğ›ÍÂ=Th/ŒÀ6NI®ÅÆFìpgu½Éë ëHXŒãˆ$¨ò¥ò%,×»°CAø¥œ§ìü8KÖ‰„ÈTNˆ×Èí ;ä™{Á.—åÑzé‘äa8ÜÓ€˜Ä;ríd!J§8ÖC†aW8œQ`XÌ5‚ó¨ó¥<§FéHG6Zè”!+¶fÿOÃ3I’‚Üè
r	%ÛC¹IËáfAùÄb¸Gãöù?[uÊÿ.ó.ÿ'¿ë<lü¿Ùšÿ·È$(õÿ/ÿ›¿0¸r)M]~ïõG]e”Cµ%’š$;î…ã@¦²Ï+E¨“MeÜ,İP˜#Ì7E*’Ğ²ÂªêşØC÷èOEš»úğûæ;T“¸_—$± #iö{ıÉ-´ğ¡AüéÂû-|O[ó³—NŒ*‚<°ÃóçõšïqékAm‘ñÀ•œçß[ïà¥Ô‚ÉÖŠp³£¯kòó6b~Å®{ÌÛ·RHiU9N2h—ÖØy‡Ísæ ÑşcdşgFFÅÚ<8”VøR:;
©9udõ‰^ı™-)‘XöüËj&şÙ¡­
¿9ŒŸÍ1_ù ‰€çzò*ì/ØLcÕ«Üø2j¥áP@¨AÈy
—·o·O=}Ë›o6Ï8Z—7o5_ğñ-‡Ñ*‚QàşX«.óH«^ÖŠ»Ù†l$ó³N–†NT—Ÿ#ü©  ıXê¢ ¨ôÁ‡Wn¿Ò•«*HäCÈ¸´[ç\åzq¾Õ®__š¥ƒá±ËD·Nlå6„•ñk6cAÕBÎ‚¢¢º2C’ÂÇ!ƒ/Z‚ÜnÊäĞîã“IÅ9—€ÂW4BKÈGrÆnMU±•¡Id²0ÌXP&v¡f®2]Uò¢7EùN"Õ3VÎî×ÃCrƒ ¼³€œğŒ›.ÊÇü­†sÆ=g¸²pSˆ§ùªy”™FËâ Ÿ±íj­Äò­çÂ¢«µñÌÛµÍÄ"o×°P€Ş@~¸UËüîu»¦şŠs£`ÓI–e^'é#!¥üyğå_eaÄ-W¦6J…V”r® Îòtq±p²³z¢¾ê¾S 
G\„0!5ô$ó#†Œ†“Á!	q¤ö}8X‰§y®Ëg¨øµ<I¯¢†’]äó,®5ËLBÕK¹˜é)mÀ=ÓôÊJağ3	=˜
®q–*‡¬pí%U¤Ïæ>gÌ?fÌgH…Ë)7óÉpKöÍrÚ®ŞQ%7Ã­¹9¸7™ü7‰WeÁıâQJ0ÏY0Ò¬±îuü+™ğ7›ß–$Å6ÍÜş·B½H~-H¡9´AB$7á$hfš\ìŒqáÊ ÷Ÿ©G¾‹’ËDsv&ÙŠ 3Ãö¾
éví †¬ ?´ë‰üéÄ,}šIıvÏÿ&¼ú:Îÿn7[¥ÿ÷‹Œÿ=$ï\sÿO½ÙjÌÿöN³¼ÿåùÃ=]fu½Ï	Õµ‹=]jXù÷B€¾äÇAG#i$sîb´ìwqãRÏiXLZ	øñB}ä{ßcR5Ê9õÉ—^¹¯Ñ;†
áyÉşæO™—|®F¢$fïÏ·8àS—¡æ¨C‚H©7ˆğiDw¡pxÇöl~ŠÊ}n]í1ù;¹÷DU4©ìåL'`2p®!“¨¾BO ®i(Í7öæ<;TSÄßŠ…‘İ™@qšÀ#‡ïËGîÕæ*FÕª¶Ì„Çÿë~h¼‚
ÙX¯¿çŸÅ¶ÆGIxZ‚|b1¾V-òaÎ«jİbÅá[Íÿ[’5û@òæÏÿoÕËü¿G"ÿÉXÓñù·¸|	ZÊz>¬(cp«lüôìÄ+êğ]%ÂFĞø%=#)Œ¤_áéŒş­ìfŞ’<9”Z!5Òá#,M)ÖÙ£'ÂúdqgVúiÄ-q¤«¼„í“Èhù1‘Î™†d+‰JM“=Şgı‘³XR„Ú	â>27”Ù>ƒÄx¸$\ãTpé`W™ıç_}êãôÿÍÖÎ¼ı·So´Jùÿ˜ô%É—$R%XºÏûq’”ƒH	Ã¬#Gt2Ïªœ³Y(»ÑiòWH	:ìW\ëõd-|¬W«õÖ'Íò‹vã‚ä-Ö¡CQì:Vô˜VP‘6¯vı/jÉ÷®ÿÕsë¿±ÙÚ,ó¿ãúOó›„9ŸK¾Š;àˆ8ŸKğj[ÓITvT¹¯sé¾S^‡§ ©Z7Í>º&ù(Â{xÖó—{Á­Öv‹‡shı(ˆ-ŸŸ´0èjVXÿHï?%ò#a‡ƒdñÙµ™K·ï^\ßu#,ï¥‡ü»Óÿæ’>Bÿ£ØÀüıÛ[¥üò?{y„y˜«ÅtÔ›sû…Ê]EW¬æhs¥«ÙÒøHÕjÄ=ŸOPqùŸe²*}³)”¤ì3é•J ?ÁÿÖ(ïdO_F¿ágı«òƒ[ùá­X`xÖ.~‹+~ä¿’û}ÜsË
1 G„øiı#µù¤™tƒüãFu‹Ø¶ï»S’ëÉŞÇ}üÜ&¯'x´ÔŸwÍ¥bÿm7ì¿íz©ÿ=*ıOåÜ++ç«6şæÃL÷Ï=f§1¿C?ôe\'ö‘ÏáĞy¯0„ıÑàğç"Âr‰H†üº4}SlD‘aN±Úßÿs‘‡ñÿo-üıf³¼ÿóq­ˆ¼Cğ7Y:İ£ãş`Ôî>}š;btt2©#FÉÉ¢ùCÖUèFG¶cÿ-¿9HNúŠs“Î¥³ìãØÊ•¨8£ÍÏs«$÷L6RWæ¿‹w)ÅGqŸt\7H–‹[“¹¢˜Ê$­ç åŒ›¹R¡X.¡Îèú„3Ê™¢ÔBdÄ™ï[U8èó¿€18é¼Z8k»<¡J”+üÂ£Ëïé8·¸MºÿàÿÑİ/ÄÖ„ê¼É Ã/Ù¦"¦* üOÀN}Ê¹æE‘G#Ÿ—@Sq^…júU¸y”só²ª—áëäÿbìüŞåk>ÿ§±Ùln–òÿ[ğÿåosø.İ¹›x+úSK†Gâ½RùÛ÷ØÿcR&>–U¡†{ÒAW‹ÌéİÄÖU@F¹UëŒ¼1Ã»ó£ÎŠ,ù=£Ë/¤|˜øïÖÂùÿæVÿ}”úÿ€¦Íjúÿª§<¢×ÖÃš¥gËÛè/½Ô÷®]ÿŸêçêãÚü¿­ÿ½U/×ÿ£ÒÿÒË3¾rç_şˆ”8ƒZpò)uäó¾•³Ÿ+÷Áõ=;RBFšôÜA®—Ô•Ê3—WGñØÚàÂ¤Ÿ2Ù‚òï«òÎ­8÷b‘'$bÓêõ>ÅùÌ–ŸhYÿÄóY})*’R\~ÇñßÏ¸\ÿ­7õ¿2şSÆ¯ÿ]Ô=ş~‚ÀŸeıÏ_ìpÿë¿ÑlÔçıÍÒÿ÷ıéh!¼èZÅ¿?(¡#çW_Çã¢Ïé—tŒòó‹êl½ƒ‘ˆ'«qçd¶âgqOk€ÉÂFú„&ËmnPF OnN¨ĞßœGÍ³Ÿeˆ¼>B%9S/u†¥€Ó=İŞMœˆ×¢<ßçÜ0İéñøJ¬E®O1œb–ë0½’$=%‰.¿^ŸzúÍÈÂ¹ETaƒüÜZNwâ.6Ò¯¿îN¤	Ÿë-¨ãUEßÜ¢XN¡ôÉ5,XËR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)ËwYşÌOM    