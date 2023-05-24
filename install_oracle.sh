#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2794888390"
MD5="469c29ffb6f759ab1ad7e163e2163e5d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="Next Generation Minecraft Installer (Oracle Linux)"
script="./install_server"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="."
filesizes="5313"
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
	echo Date of packaging: Wed May 24 14:12:05 UTC 2023
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
‹     í=ûWÛ¸ÒıÙÅ`Ø-½Kr—{Ø~)¤mî…„“„ííéöô[!^üÈúÍöëÿ~g$ù•˜ áUZ«=¥¶¬ÑÌHÍK¢\yvïeK³Ù¤ŸÕfc3ı3*ÏªõúÖV½Ú¨W·ŸmV«ÛÛµgĞxö %ôÍx¦»ó'šÎ.ùîªú'ZÊ•ƒÎ^»;h—mã>Ç{{û²ñ¯mn'ã_kVqü·jÛ[Ï`³ÿ{/‡!˜:s|¦({îdê™§ã ÖõPÛ¬mÁ¾vn°çzçÚ©ejŠrÄ<Ûô}ÓuÀôaÌ<v2…SOsflÀÈcÜècÍ;e¸ 9S˜0ÏÇîI ™éœ‚:ö¥à—ÁÁøî(¸Ğ<† ù¾«›ÂÃÕC›9P#Ób>¬cê@¶P_ğN¦YŠé ÕEUpac7Àc~à™:ÁØ ÓÑ­Ğ ¢jË´MÙ5çğúHá¹¶k˜#úÉ8Y“ğÄ2ıñ&>	|éÓKÎÉ¢£âzà3ËR‚‰xsZìø7„ú„HùôæbìÚYJL_…ƒ]2ŞÆp‘e¼Ç?™Ğú|äZ–{A¤é®c˜D‘¿£(C¬ÒNÜsÆiãë¸¢*P ˜$£*«ü±fYpÂ$Ã°_d¯–"Ç£îqñ8©Y0q=Şß,™eìÿm½×Ãw­~:8ê÷~ïì·÷AmğYİ€wáÛŞñğ‹~«;|½×Ğê¾‡ÿtºûĞşïQ¿=@¯¯t:m|×éîïwºoà¶ëöpwp*#Ğa¨C	ªÓ°Ãvï->¶^u:Ã÷ÊëÎ°K0_÷úĞ‚£VØÙ;>hõáè¸Ô´±û}Ûít_÷±—öa»;,c¯øÚ¿ãŞ¶¨+¥uŒØ÷	?Øë½ïwŞ¼ÂÛŞÁ~_¾j#f­WmÑµwĞênÀ~ë°õ¦Í[õJ_¡Ïvğîm›^Q-ü»7ìôºDÆ^¯;ìããRÙÆMßuíhõ;bÈë~ïpC!vb‹‚íºm…X™ÁOèùxĞÂ~»u€°Ô˜HŒ>.+ÏŠòíÿ>óÎ™÷éDÓÏÂIå¾öÿf£q-ıOìÿõFu³Ğÿcü'’8v-ƒy¥ÿáä˜ÿí&š…ş÷ eH»?ş¥=[L•µ
×›¢FáñšCÓaº§³¥Ø¾Ÿõo:¸,ë“Ù‡·ÿ«›õF}Vşo×›Åúˆ²ºR91Ê‰æİbš§0}ì‚úYºk³È´è²Ï¼aó„¡”„˜>Ì[Qs+ğ§v®A©„s‰›ÿÆ!›@µ	¥¿å( ¢‹v¿ßë¯à§°§9hu }‡æÈ¹f¡ÁÉÈ™É{,Ã!Ù#àj³Gˆ±ÏÀÖÎĞ`	ÉP
H˜É†Ì(«Ø›gK©%o”~–{^òzv1ªŸÍ@™‚4äˆM&Sé;ü?ÿƒWœí¢kÓÆ›fi{<:ôĞ³–¤ƒ7ıfèğ\'ĞN–%E¶~,jVgÉ	GYRV9-«×!†ÚŞ˜ÕYJV/!e5Ÿ–UIÌjÎØŒPŸ¸ÀoKºm,9@5JÓ	
Ç±À…ZLİ,óŒJG#ÉıY¢/ÉÑÙ¨øŠ»Wˆ9 ô7¨kò
#>ÜË&v	]pÅ&³'Á”ó""Gö¿»¶Î›Fø Ä<Dÿ”ÔÑW¿ìâSêa­ßêî÷Õ¦DÂ9aví…9ıˆ²>Åùæ¾¸ğ»Dh#bŞº`‡úlf“ú;?ÄH
ß%‚äB|	ëo^½ â°')s`í>V*6K¿~¬|…÷CŞ¡@T³İĞ	RD’WÒ9M6M'´OPmOS½š%›Ü´†6õsˆ>c¸Õ†fZÓÈLxI$S.½"¢éE†êXpİZ¼Ì¾OÈ^Ÿğ´€RP•p‘óù«Ä ¿2¦ô¨øJÓdÂóŠ¿[ÑÿğwŸ«¤ı¡ª™Ï_÷ÌIàW íÀ98— ä”¿ ÂØt¸È#PéG”Ş\âj‰ä°è§2½ˆÛğå8s¼¹îÜ†?ºë FÜ‚=3–BB¨AŸ<æ³`)2 nƒ¶'·AA XÔ5üàS`Úl™şS­—éÜõ44Ã>Q8åèÈ<]‰(Ë  po‹L”eñµsv‹å‘n¾T÷æİfyæ·G ĞÿwöËàNn…¿{«àblÌ2ıÛğp†bŸGJE¤¾&¯"µbn›Wò4İH@àÿe—J9µ ¿Oÿ_¿İÚ?¼Ïô«üÿ[Zs6ÿ£ZøÿÈÿ—råhËä9‡š£R"Á€/„¸ğ¥-4´ñÚhò‘áí“Ñfø”Ì…S€62 Mæ’é€m:aÀü2´°+›ºJr5Æh”hú˜ùéLiq”eNhAÑÑì(%8æ{bÎ×p	z|ãƒìá³¢ì™~Æ-—>ã^ÈËE5,± ôáAàyå¢YäO˜nL=òöÜ"¢\iÍ–•qLüJåQOÊºk£ækF%¦½$+qÎ–3+²?¿¢(«ÈşØoAŒq—J\ğorƒV›Ü×¶Á=‡"oDj9e"«˜À‹ıš£tC&Ò `´f©–Ì#wB:±f•¡3´‰%óÈ_d“¹¤Y¾+2>"×	Ç°:;ô3™bG/ûcÊI^­_SÎ‰<§YÁ1Œ â(ã?§¡ijyºL¹Ğ¦e¯âßåÌˆLnñ(Å5Ï¢Œãa•˜UÙ	—„±Ö/(O)e¸—ÿÄ5oú/„‰ë»;(ç3ğ‘p>2>³F°'\Yœ	™	·#&?}S*!‡™=2ÌsI½†ûÖ3 _¨9Fğjf~/î=Œkö†œ×¹2Ä¹š–/Ã­Nìõ‘QDşQäşÓÇšsŠëî$”ó‹>‰*qÔNÜ`œ3¼T›l¼±Ø±¥UN¦é¸âHD[‚gÎ¼ºÉ¡Í«Ä¸Äz›xî¹IN™˜˜(,Ä/3#dvbrs&Ò´ÈÛd˜x ±Hğ°·	6rı¤'ä_n{œ]ğJh.} {iÈÈÙ±£´XÂ±ŒQÎiœ1DÁruÎ&™q1Y'S1@$dù pnkŞ)Ïº+­i¡Å]ªÕ:÷÷ ßğ£0 ©yüøú5EÊ˜ÇÎM_P}ázg\¸ç²ä›HB»„«Èe¿3àISíş™á
aváôaç8äÅû³M?ôÙLĞ¿C¦!LKÎÀÓfkŞ™OêJ	J’J‡&
ZJN»¢û§æˆÙ$)B¦tÕ„’éÌ£%ñ„Âã±}ßùß×Ìÿ©oÕ¸şWä?ğøg–æCÇÿ·gôÿF³^-ôÿÇŒÿ-D\§”¦€*ë»½a{xöãÑŞLúšØapSy2•yV;Cåpâ™(h§Év„Â|—§«	uÏ/Gİ¹h©Ÿà»ŞD¤9G6?¢¾Æ=¡´2âfªa@”¹ŠU¸“¹÷[øt„õ×Vˆº‚Ü7ı³sßÕ?"âÒ;…AÆ×¶œ?4>ÂkÇ$[+À]—jWeõ6b~ÉöÄ<Ó5HÉ§rœd˜+ù¢ù›ÇæÌ~¬ªı[K!ıÏŒŒ#µx8%ùàW¤•#´"¤RäT‘ÕÇy=2[R"±ìºåTÄ°Mû%ÖYŒçæ‹(©|PDˆp-~%öl&QÂòeoçQp(r Tó d|k‹Û×òÛ'¾±ÅÍ·r›§\“‹›×óšÏyÅÃhäÁÈq¬–ùp£^Vó»Ù†tìïÎB ƒ Q—w0ŒB† /X¢¡ôZæŞ–n?•«Ê‹åƒÏ¸´[ã\å:zğT.Ÿ("½0¯Ãa±ÙÉ¦8sçe:Æ/†j.Ê/‡(o„.MY¤ğqHá‹&)7àRyÚ}\2OÒ8g"ö(|E#4É\$gdáÖT[Úf:óı”)§cgšr*Æé&ˆŞå;‰T-=‹³{ÊŒSázà˜o`ÜŒŠHpÄ«h5œ1î9Ã•…›BÈ8Í—Í£Ô4Zä9¿Ã¶ËµË7jœ	$.×VD oÖ6½»YÃ\z ÙMàF-³»×ÍšºKÎœM'^–Y¥³†”V†÷(_ø*ón>³è`›ÔXhEE^ÔYVæ';­'ªËîéÍQ8Lá"„	©¡ß™ ™1d4÷Hˆ#µŸBÏÂxšçš|†’›RËã„$j¸/ÙEn9ÇàZ³Ì½‹zé"S=%¸Cš^	¤O›w1ÂDp³4òcü‰tİçŒùgÎŒ¹ƒä±Œr3›>¶`ß\"ìòUrÓÓìŠ{Éİ™x‰àYÏ¥óŒ#Íã^'Á¯É$HŒ	Øì´Ğ É·ifö¿…ªyòkN
Í "™qôÇa@0=Ğäë×`„Wí¸#_Hµ0pm”\:š³SÉV©j¦óMH·+Õg9•GdÇféJ*iòû=ÿóê±ı¿ô¾ZßnTÿï£Œÿ=¤»\qÿKµŞ¨Íÿl÷<’ÿ×ßUeÔ§Ôa`U9ßU¥†•}/èkš60¤ğ¡H#™q£e¿ƒWôœÄæ¤•€•çQ%ß»ø“¨à¨QÎ¨O®ô:È}jXhiQ8Ñ‰÷7wÂœ¸º|âäGs\¾Åñd—ÂÉ5GbDòÀH½AÄqºƒÃ#8¦còÛ0„Šx{ìmÈßÉ½'Ğˆ¦è|KäL'`2‚¯æ!«¾òà×4"Í7‡öæ,;¢¦ˆ¿
-"½?F¤"ÖI¾/§¹—›¨•ËÊ"Bü¯ı¹öJdc¥¼ş{š
¥hìÄÓÜdSörŒñÕrsVUèæ+ßëùßy¦$ÿñïŒüonU‹ü¿'"ÿÉXSñŸì[\¾'ZÊj6¬(cpËlüôìXóKÑqµR€ ö[rªPI/ae—FÿŠìfŞ’<9%”Z>5Rcá#,M)ÖbÙ£ÆÂÚ9¤qgFR5äIq¤«œ„íËhYKçTC²ƒ#‰JMã=Ş§ı‘±X„Z	â)>2Û—iGıØx¸ô%\ãŒàÒQ¨â
„º,:'ñ@úÿfcîş—fu«VÈÿ§¤ÿGÂ‘|I"Uâ¥û¬'N9"a˜väˆ|æ¥36õe7*Mş©á#"A…½’­p½¬…/Õr¹ÚøªnŞ® “¼åÂÚ·(Š]Å¦ä|H›Ç7»şçµä{×ÿªµ™õ_ÛlT‹ü¯§¸ş“ü&aEÎ&µ/ã8$Îg¼Z†G®Çõ­¨ÇLWŸÙtß%ÿ†§ E_]7ûèŠä£ïa½ëz6÷‚×íçĞú!Q.?`¡ÑÕœ°ö…ŞåGÌ.Éâ!³+3—nŞ½ Èù,ï…‡ü‡Óÿf’>Âş¯Õ³ú_s»ÿODş§¯[PSv‰(+ôéiˆÏÉ0ÎõB^¯¦Eå¼ª'ªª"4ÂzCáW•Ëü+®¥Ìú
%qöæ—j¡M'PÂ³ÏL§ëPJ|ù
üK¡|˜]um~Â/êOFé'»ôÓ{7VOsŒ]Uü—õÈÿÅ7õØg†éåvNñëÚjóUÑé.úòZ_çíkOhÇ‰weî5á'Jùwêèj}ò?›¶÷ öÿvmÎşß®òÿIéÿÑ™‹Hô}Ó¢}6Ì˜rßòÜsvò;ô}WÆõRa?º:ô}Øö~y%"lûé˜˜dÈË…é+ó{Èã¯ÿt@ìaâ?[s¿ÿ£IWÂëÿ)­ˆ¾Eğ?^:Ã£^ØêWVV2GÌÃèˆY|²lö´:„i™3‘rvôn?>r.ïR8ß¡ãi¡#l”+1PqY ¿X :äÊFëÈóâ]‚Fş™ğuÎ{ñ<»¸¦İ‰ “ô^€”3vrä.
Å“pauJ×gœRÎ¥–"#N]×(Ã~ÿŒşq7çàİÜ¡ïÅ	uQBAÉ‚ßxvÁ'ºW@Ü&
İğ?t[±õçŸ¡<k2ªğ[º©Pô€ÿóØ‰‹B9Ó<Oä0²é1´(Î¡šT¢ª<‹rf^–Õ"Üu•üŸÏ¸wùß˜ÍÿªmÖëBşşßìµ"?¤û7swq©D¿jIsH¼—J»Ûå¿LJÇ'Í0JÔpW:h+>¹=Ğ¸ˆÇ(·îaÑ×¦Ããcx{~äÁY’%ß£g|ñÿßš»ÿ¡Y¯ñÿ'©ÿ÷iÚ,§ÿ_¢zÊÃAjeÍ¯jZ±¼‰şÇñR}ïÊõŸ:™uW}\™ÿ¹5ÿ©6Šßÿô´ô¿äò”oÜù—="'Î çœ|KÙ¼ÿÈYÈïpÁv3ˆ<„iÒsO¹
lR;4TNèœ¼¿ŒÇxĞ&½8ø–Ê•¿_•wn„¸ <!›”¯ö)ŞMÜª?nüÿw€+ã?ÛÍyÿïf!ÿ‹øÎ>‘†|.ÀşxÑõë„Öÿ·ŒªßßúŸ½Øãş×­^«Îúÿj›…ÿï)úÿ’;ğBxŞµ8=~TLGÆ¯(jG£¼êšôKZÚ”yºyßl}„}‘ˆ)?ãÎÉô‡wâÌ× ã…ô	M “Û^£ŒPÜP¢ß9šg/Íy}H”äNMœÄ–L jL÷´;×q"^‰òhtSœ3ÃtS¤G£K±®å¹>ÅpŠY®ÂäR’Ô„$gËÚÄQ¯GÎ-¢
dçÖbÂ¸w¾‘zõí„·"Mø\o@÷¬FôÍ,ŠÅJŸl^Ã"¹(E)JQŠR”¢¥(E)JQŠR”¢¥(E)JQŠR”¢üå;kb    