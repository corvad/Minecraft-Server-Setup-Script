#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1415509085"
MD5="a5fb95613f26b31dbe5ed560a1702305"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="Next Generation Minecraft Installer"
script="./install_server"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="."
filesizes="4179"
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
	echo Date of packaging: Tue May 23 13:02:42 UTC 2023
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--notemp\" \\
    \".\" \\
    \"install.sh\" \\
    \"Next Generation Minecraft Installer\" \\
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
‹     í]{WÛH²Ïßú…`6ÉÎZFÆìar3!37{È!äÎİ“áp„ÕÆZôğêñäòİoU?ô²lÀÆ$LºÃ‰‘Ô]ªêG=~Õm¬ö“µ—m,ƒÁ€>íAo»ü©Ê»ÛİÙ±wºİA÷É¶m÷ûİ'Ğ{ò %KR'x2Œ\–Lœ!›Sï¦ç´Xí„Å—,>=s†Ù¤½¶ñïõî0şİ½£ÇÿKŒÿ¶İÂŸIû¯·³­ÇÿÿÄGiÇ‘ï²xõñï÷ûsÇßŞÔÆ0Ø<m=şk/Çc/üq 4Ü0ò|éØIáÊó}8cà2Ÿ¥ÌÅëtŒOV‰“Ä¬±Œ'º<Öõx!ÆÎ(]›'xwı¿Ó×úÿáÇß±/|ÿTX„óÿûN]ÿ÷ûÖÿQ67Úg^Ø>s’±1ô™l8ÀüùÃ(@#qmÀ>¥ğYì¤^Â¾š4ğVLo˜†7‚ø·sé@«…3(¡šÿç1›€=€Ö$ âo6°*¼vÂ0JÑ¤„.\:¾ç
"|>†CfÁ~F¶†"j,x‡Ü&ç‚A’Å¼”™œÄÌµL|S€˜ÍĞŠGåkéï·­Úô'6?y©1òŒ˜9.´&Ø)Ü"F™ïÂ4ÊÀ÷.x…uRù.Åø0ñVB,Sß|„Ö`nÉ;&œ¨şXËZg7CÑ£Øe,˜¤SŞJùşİ­g¼©âG*‘aü×2Ÿ«ZßïâUébëèÕÁŞá¾Yë50Eçà«ã,½ğœzA>/õ‚¼³®^øÉĞ¢ÈEøïè
‚l8†€Q<mb…¯É yA/áÙ/?='á°%aë3^¶Û·[?œ´¯ád=âíF ÊÂ´$d’ÆØãÅ‚	³àŒÅ©7«b;á\gš4}Ápá’Ô®ãùSéë%/Idjal–„¦©7¹Ø›u¹7ç¾Ù,ùæ¬è{Äìíß”’o¢èªğçğg9Ÿ¯%XËÒ}’âš¦;vOÛÉn{ø{²ûÔü½ÔèwÓ6µ“aìMÒ¤-)¶s—DàRSşNˆc/äJ—H•/QºsŠ›I’Ó¢OIdz«ôË=ôÌ:úæ^zg•şF!ZÒt…î©QXŠ‰8
Sçì4f	K—â¡B`°}6Y…A`xD{šz[æı¥ÖË¼<Št¿N'Qœâˆ¼óe˜h ²3‰sÉV˜‘åæK½=òUVDs{4ËD>üíí— š¬Ä´’Î½{)ó½d•>œ¡a—Ê+±¸¥,ùŒe5šŒúĞ-Hàïò•†UZC˜ùñÿÑ›W{ûo¬À]ş³ ÿµ»»ÿÛv_ÇÿQŠ@ş=Np0ßwBç½ixÏW&¼ÏPÆ~iS0F%_ÛğO
Ø1È§öÃ,ö-Ã8òÎÇ)„dˆØX‹B%’lB6*Cn°àW/Ì>¡Ûî3é£Œ±ÆóÂ†á+…9³+|Ÿo	®)Hq\0bpG×HÊÈ8à;)ª+©çˆ£,|aäêÈJÆ†qŒÑëÓßeÁñ8HÀŞç™ç
aéåÈDJ¬ÑïWÎÔ¢¶Œ³P±<F—RÙ	(¹A21>Âßò§ô©‹bSŠç]YÌJ‘¦õoœœ^ò\ÄdIDìWè‹aI˜?‚×Q€ÜF î´ZaÜ2ƒy0ÇœÕÚÆë±¢˜?	UÄRòæ½0Ş¸8^g‘ÌT>)jÎ2øÑĞ¡„‚'kaJ}q6…!½‘&¢BÑ!GSuéÄsæ31`.9™Ï‘»Ëëàä ±e)MULğQ“¹Œ˜]zdqè®¢ø¢ÈiTGNNXb>-MqÛúÓèÿu¡¾«à¿İ~Oã¿ÿÕø¯Æ5ş«ñ_ÿjüWã¿ÿÕø¯Æ5ş«ñ_]î1ş_ê»
ş»cw5ş«ñ_ÿjüWã¿rşcÇ —Øÿm£¹Ğû¿rü+sÿ!ñ{»k÷ëùßAw[Ûÿ/‰ÿ¿:»,@M/S>?8<~óK†=È™A¡ÅÑĞâ(ªµfôĞæNb/pPÑç*57Òü­É
+šXêõï"ĞÀá„lPòB=ø¸}‚†#"¤ß…y³ö	¼§ènæA‡D“™û;xŸ<g?ûÚN$¹ç%ÏgêuOq2Á~äz#oÈ­kÁóÇŞ	ü,=ò¶R´lôtS>î#çsLì;{‘[P*ªÊq’pwQcp‚Íİè*ôÉ+ÚóF#ìUÅ:%¦ÿ“‘xò+«~@é‡cæf¾bª$]ı!Læ?ÇÎ–’H.¢+«”9x’{öù8XÈ¼È–ÈC¤
¶òĞbÿí"[`ÍÀ$ŞkàP4P°›(TşÅí;Íí‹€}qóÆæ%¼dqónSó™P}1^àHQÙl&Ó‡2Æo)€…I õÊûH¨Ô  åE ‚À”PI3À¾tû™d‡\5q¾şÆµÙïUîä‰cşø¨ÌÓÂü%FÈ®rG™G8³©Lzı{YÎå‰¡šÉæÉ!j¡¹©I)
‡¿Ç‘3K™7².ù÷e+™9T®¢QçŠ3òÑôXÂTMâhÈ’DÔrü$‚!¾,eHOdUiedo‚ú›T¦“”BœİS ş
Q‘ŞyÌ	¹âqˆL{")şˆVÃ›?¸²PégŒË<o•¦Ñ"¸îÛ.×zFíŞ©q%a°\[ôß­m	¥¿[ÃFyU%§–Uët·¦Ñ’s£Á¨äË²êsÀ‡‰Ë#yRP
k¡~á«,Iéÿ‰
¹GB+*“Ñ'Ù˜],\ì²h.k³ªğ¸Ä‹P&äfşÉI}Ä°£áÃÑ¯¤ÄQÚÓ,ö±¡u°%¯¡•Üî|ã5Ü“İ…FyÅrzËöbéMEtìGü–[Ğàß9àæ~©RåÑk¼K 6>ªª"˜uÎ˜¿7Ì˜{Ø$RqnêÛDØÍ%v{Ì·¨²7c'hº·™ü·‰sÏ¢\ó(åœW"¶¸k?“ ”¥"bu´0àhYjöo!»IÍh¡šú)‘Ê8&ã,¥XèQVŠô,e	œe²™“¥Q€škˆáêTv+’tÎ/ü*´Ûƒš°†SoC±Ã0;7J›£¾Åü_-ñûUà¿bÿ¯Æ¿Àø¯!Ãşo»ÛéÖ¿ÿc ÷)ü7Ù5åæŒÓÒWB™Æå®)=°ê}¡`æ_uŒÓF&’kp1Fş/Ğ°©ë"å(£|x©rÛÆmPá¢£ÇYs¯"‰JH»GOXæ;*_æö/š°0l¥ŸÒ<':aÄM ÏñFà‡=KrFšÈH¿Ú„ÅhûAèx¡—zŸç­9œ#¢¯F„wrtEU2©Ì¶Ó‰˜9-³‰™Ü5~pODyÆÅ˜„d»ÿVíÕùw3áe”í§â€?Vq
åî e·K@îüğ'Ë2…â¸ÀÿŸ:¿@‹b°êFç™gğQRc'®f† º¨!X¯;m‚±fâ›¶ÿkèˆ›ô?şÔ¿ÿo§ÓÑúÿqè
æLü¯z—/ÑQKÙ¬¦en‘Ù'i’–:¶ÒJ±t~l»ì²f¾/3G/ac—FÿPq5oIHOµVBÌ\ùˆHTj ­\÷˜y ±u	eŞ™[<:æ‹Ê8¢š•F®£åÃ\;—Rœ¬4*5Ímİ/7 ø¤Ñ½òIOñ’‰Àéá(®/G’®Èq*ºt$BoüÆ÷Îß¼ı@şÿvoPÿööÿ•ÿ¯”#aMb«Äk÷:Î“o9H•2,=âE	İÖ›&ò5&Mş¹á#Á„×­Àà~=EŸmË²{×†5Yç’ô-WÖ‰OYn+†Ìh¨HÆã«]ÿµ¤àC¬ÿAoöûŸzı?’õ_>vg–.jµøî]»[ÓjĞ2ºÂª³á‹®Û3ø)rËjã8(ù¹†V@°|/7cà¢ŸN 3È>±!?mÅğù~ÿ‡AyÉ]së}Â÷æwnë» õİ¿Ìçôb¼kŠOq8Zş–ŸŒ.\/nä€.‘"}R£kcH‡_á¯·«ÜÔq¯£`B_ÌÇüÜ;å{÷y=ÑK"º>ˆıïwfì¿ÓÕëÿ1ÙµçRY¹¯Úø×aÆRøÆ÷¦±³ìœn&‘ÄõJ°`ÔFt`ÂÓV¯~ış'°í•11Ù!/¦·¸ÄNš:Ã±Öøâö¿“=ş³ÓŸYÿİşûkıK zğ?_:o÷ß¿:8ŞØØ¨l1ßÿğşXm1Ïw–×QYğ6…,õ|ïylìİo{¸èøá(`8ŸÎ¡²P à¨Wr¢â?¯¥6A–²ÕoåşHq¯`£zZJqüÌI`BX—<8&şjwCÔy"™ÄRÏÅ–{Å“raHuŠoFÓŒùÖìˆó(r-Ø;„ƒÃc8úpĞ°ñ~æ`Õâ„»J(´|ø‘gNé ™¸mTºåÿè/uë_şV=d0áÇrS´ÿ³³•r¥yòÌiT·KäÔÎ¯X-¢Wg¹2/-SÃ]7éÿÙÜÉÚõ¯×©êÿÎv·§Ïÿ<Fü§8ß"õ_ù€ïó¥²ÁûÔñ•ó=¯\ŞÑ!_T]ê…•#>G,ˆ.™¨Ã¡ªuÛÃ'7œ=É‰ğ7<;ˆâ€o’êôzıßíGË‡ ÌòÜnk`«Ö„aíÔ{«õG²İIvæ{C¼r\·Ew·>ÓÇu;NV'’¹óˆÄŒrë¹ûœ—
;™ïï¼ñÍš:#æc¸z4ÑY²KÄ´ògÙ[¶ø«|ÿßéõgüÿ®Æÿ¥ÿDÓf9ÿë)7›í­¤íšeÇò.şçËÔşŞÍù¿S} üŸ
`&ÿ×·õúTş_qxú+ÿª[èÅ¥†ñPPİ÷§ÀB~î0‚ 
½T!„ŠŒé9APA@n‡ƒÎ	í3D§ƒ6ÆóÜÆà"¤ãK»E8(‘ˆ—»Y,¾…”M¬›1Åzfó)-ë§<Ÿ9‹9Î¤(¥Z]~ƒú¿rÊâaü¿İàÿéïÿÒùßó¿Mß·XÏKIà{Xÿõƒ¿ë_ÿnÇ®ã[ãÿ+¾ç1d€g¡Åã,æß/‘ËQÁÅÓÑ¨éqGâ’¾3¥CQSØãG]Uãàd¹â½À“Í`¾°Q>á	Tö¶u®ñßÜ–oPFyÉó<,wˆ<^¬6¹Q“° ÃŠ	@1t?o"ŞÈòhtW+ÃtW¦G£¹\wš O1œb–›0™+’YˆD_\¹5	ÍÛ‰…s‹¤ÂÕ¹µX0âÎ62oşv¢•D˜ë¤ãÈª’¯¶(K(1Ù¦†¦>¬‹.ºè¢‹.ºè¢‹.ºè¢‹.ºè¢‹.ºè¢Ë·Zş­^rB    