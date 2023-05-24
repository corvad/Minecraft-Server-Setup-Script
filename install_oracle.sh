#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1650475119"
MD5="1836b7200f233b54b4401f5fb78fe1c4"
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
	echo Date of packaging: Wed May 24 01:45:05 UTC 2023
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
‹     í=ûWÛÆÒùYÅDĞ6¹Å66ßË=´ŸNâûÍ±MssÚœYZc=\= ´_ş÷ofzØÂ€y¤$ÚrJ$íÎÎÌîÎÎk—jíÙƒ—M,­V‹~×[ÍÍìoUÕ···¶;ÍÖöö³Íz}§UÍgPâ02€g¦o±pf˜ìŠz×}¢¥Z;ìîwzÃNÕµrüwvv®ÿÆæN:şÍ-ÿ­Fkól–ãÿàå¨;‚CÛd^È4mßŸ]öé4‚æKhl6¶àÀ8·-Ø÷ƒsãÔ±M;fk‡¡í{`‡0e_Âi`x³6`0şÌ©œ²ˆ|0¼K˜± Äş82lÏöNÁ ûÒ°f4E0¡?‰.Œ€aeŒ0ôMÛ@x`ùfì2/2"êob;,„Ñ”>”-ô—¼‹f{@ßÔ'¸°£©G°0
l“`l€í™Nlê³c»¶ìšs„C¤€ğÜ ×·ì	ıfœ¬Y<vìpº–M Çq„/CzÉ9¹AtÔü Bæ8B°oNkŠ¯C¨Ïˆ¡‘dQHo.¦¾›§ÄµIxØ%ãm,YÆ{ü™½¡êßqü"Íô=Ë&ŠÂ]Má'cìŸ3N‹_ÏUÀ,Uù)œc&†ı"{9u‹Ç‹lÃ™ğşæÉ¬bÿo;0ì¿½k:ĞÂñ ÿK÷ s z{ˆÏú¼ëŞöOF€5íŞè=ô_C»÷ş·Û;Ø€Îáú­{t|Øíà»noÿğä Û{¯°]¯“¸‹Sú@JPİÎ€uûoñ±ıª{Ø½ßĞ^wG=‚ùº?€6·£îşÉa{ Ç'ƒãş°ƒİ Ø^·÷z€½t:½Q{ÅwĞù`ø¶}xH]iíÄ~@øÁ~ÿøı ûæíŞö:øòU1k¿:ìˆ®¨ıÃv÷hÚGí7ŞªPUØÁ»·zEıµñgÔí÷ˆŒı~o4ÀÇ¤r0Jš¾ë;Ğt‡Ä×ƒşÑ†FìÄ}Ûõ:
±r#‚UèùdØI ÂA§}ˆ°†Ô˜HT•«Ú³²|eûÈ‚s|æY<«=Ôşßj6o¤ÿ‰ı»Yo–úß—ÿÍz8$µ/8şø«Qÿÿ™ƒÔN}ÇbÁƒêÿ›õÍÖÜø·ZÛõRÿŒ2"íÈ7×´Q3"T’…h1‡‘FNJ³P6í Œ@ÌšR-xÂëßöp8ÎG!¾€ÿ§EÆşÜş¿ÓÜ)×ÿc”µçµ±íÕÆF8ÕL‡ÆÌ©ú;æ˜¾Ë”iÙcŸ"xÃ<CùÈö˜“ºbú°à¹®Ùx¿çT*8—¸9ùp°Ô[PùCCP ºèıÁs¬
û†‡V'Š4GÏÇ¶93yU8ŠIŞ0P€ë­*#Æ!×8Cƒ5&C9"a&2«ªcobnC%˜dŸå—¾_„ê';Ò&¶ 9â’É\9‡È?Á÷?AÍbç5/F»øÆ´ñ¦yÚ¾f8+ÒÁ›~):f ş3œ¨|—òcÇ‚K?Ç>ã“Ö3hòrß’è‹CòL¶:¾â®bÆ¯PùôuùF‡Šş»a9Ç¼ac
âfî,ºä¼PäÈş÷Ö_ğ¦
\=Q€ãı¥ªõã>eÖíŞAÿHŸcŠZ()s°ë öÈG\ß3\oŠ¿H„–1"!á­nlNÁe®\1’Âe“D4“ŸáÅ›W/‰8lÅ	CÊ<Xÿkµ_7+ÿúPû†¼#¨áú±eˆ$¡wš
0/vÇ,ÈQ½–'›\¦–q}ÆP˜Õ–a;—Rÿ
&’©…¶–!š^ä¨^ãd¯ÍÓ½vákÅ”¯-’~@ÈŞœğ5Iù’®á¶áşKÎçÏ¬e]Ò{¢â3Mwd?ÔÂ½šù[¸÷ƒş[¦ÑoºÊ”©…f`Ï¢°& )´ çà\SşV cÛã"@ePzsˆk)H$’Ã¢ßÈåM@Ü…/÷À™‡àÍ½pç.ü1}µ›èì™ƒ°ïEÆøcÀB­„CÀ]PÀöñì.( « À­Ì‘í²UúÏ´^¥s?0P%şH¡8¢ût$
 ¬‚L<Fáß™(« çìË#Û|¥îÑd»Ëò,n:A _şëíW#ÀŸİ	ÿNÀÅÔ˜c‡wááÍ=WJ…R_ÓWJ­XØæµ"Ã´RøoÙ¥VÍ,èÒss_şŸA§}pôé×ù·š›ùüúv³ôÿ<Šÿ'ãÊÒ6ÍsÏ8¥D‚!_z0Œq±kZ[-E4îñ…ğ“±’¡¦ÿ%™(§,#V
M&šík{qÄÂ*´±+—ºJs5¦hæ”…ÙLiåT5mÏhïBqÕîj8áûbÎåFú|³…Cìá“¦íO™yÆ­¥ã‰P‰ğ—XPzˆğZğ¼ŠÏñÑgÌ´'¶©ü_ı!·Â(CZĞUmE³p·V;EÔãqÕô]Ôû‚sÃª%´WbÎÙŠ`fMöÖ4í(q”ô)n‹©¯şC>°zkƒ;ZdºˆªÂÙÃ.ìØ¥È„2yá¡ÕL_Éóg¤{Nº@Û[2,uÄNè‹,å¢Ñ´L¹1|íÍPğ?Ì1ÛfòÄŸ)¶Â¹ t$,TÁvàŠ3x</ÈÂÁ÷ÍqÀ9. ó,>2rPF±·«%ÛD5œRV‹ı@óóCá/â§±m	–ò„d™–ra\VyFGAÎ=åHr1ÄÁøIÌÛü”¶,3"£ÿÅeBeÜÕßQªØáKa¸‡>¡Ÿƒ/?dÎö…;nWËÍæ]±²¨B¥‚CÉÜT!eè7pÊÂ‹Ì—úâf›É{ê3²¨Km„s.¶+YŠ–=™ ½Äk%æ¨¤Ü•æÔğNqFc9o©Šúˆã3öel*?ô5UæJ¯D<³x®™aâê%qCn]0œ#‹ê2‡¶¨ÒÓÄæËwøç6eKqdbTn™C3Ä¯JŠ(‚WB9°9@\%Ê®Ö±p%%Dåì~Æœ­orJdœ"4¥ãKÁC’©Â‡„ö4*wçF`c‡‰¥d±‰;Üq[ßæu:Z•“8"Q¥üŠ|=Éğ`ÀÎíPä¦]øÁY&Ì…%"í,]´â5òC;èy~Tg°‹µ|!Ã.<J7cç8"³€˜Ä;rí„Jg!ÖC†aWÈjÎŒ(0,æÁYHÔùRpR£ôI‡#­UÊC ÿ»á‰Á–¤ 7º‚\BÉöP@ÑŒ}ê¡ÏD¯À>nŸÿ±U§üß2ÿãÇ?·P3ş[ßÜnîÌçÿ´¶Ëøïÿ
}A\¿”¦€.¿÷ú£Î.Œ2ú¡ÚOI›[n¤“@¦2ÏëN¨ºÍ¥ïeº?á6ƒ0ßiRB«ªûc?mÜ± ?iÎêÃ¯›PŸâŞWÚ#I³_ë`HÎ›…úàÏŞoá{Ú×_¼vbÔä½\¨·ı—Ü=,2¸†”âükó¼–Š0ÙZnÃôuM~ŞAÌ¯ĞY`ûV
)­*ÇI†ÖÒ­Ø<1gõê?Fé&`dìªÍC8i…!õhŒY±£ÊSGVŸxáÕß‘Ù’‰eÏ¿¨f¢”ÚDñ›Ãxn¾ˆÌÊM„%×“PaÀf™¬^ål—±%‡¢ B½BÎŸ·¼}£¸}ê[Ş|«°yÆº¼ùvQóOÜrÍ"Nj€µê2¿±êe­¸›ÈÆï-¼	°4À	 º¼ ¥
SPŒ`i@ŠÂ”ÒSZì[¹ıBàU®ª ‘!ãÒns•kìiU»z|T|i.†Ç.­?9²“O« îÇìçl^ª…Ì9DE#teš„$…C_4#¹Ñ•É İÇ'c%‹s.K …¯häÃ©äLÜšªb+CëÍda(jqÓÄÎ"´T¦£JqAôf(ßI¤aÆ>ÃÙ}É-„<!ï4à §|ãF•r Á1ÿD«áŒqÏ®,ÜbÆi¾je¦Ñ2oı=¶]­õ‚X¾Uã\ğrµ¶"êx»¶™ˆáí
ĞÛ Èo·j™ß½n×Ô_qnl:É²Ìë$p",$ ”KŞ£|á«,Œ¸MÍÔÁ6©±ĞŠRÔY/.NvVOÔWİÓ[¢p”ÁERC¿2A2?bÈh8’Gj?Æƒ•xšßº|†ŠŸQË“$(jx ÙE®4ÏâZ³Ì÷S½ô‹™ÒÜ9M¯¬ÏI_pÂLp³Tùm…_0©"½I9cşY0cî!a-§ÜÌ§¬-Ù7WÈ<»zG•Ü·ææàŞdòßt&^!x–…à‹G)Á<gÁH³ÆzĞIğ¯td‚Ôl~ZjÛ4sûßRõ"ùµ …æĞ	‘Ü8†Ó8¢˜hòÏ0Á…+ƒvÜù.¤Zù.J.ÍÙKÉViœ¶÷·n×jÈ
²8»ÈnNÌÒç™DÍ¯÷ügÂ«¿ÇùÏf«ôÿ~‘ñ€›kÎÿÔ·›óù;­òş/äÿ÷t™{õ1s$P×Î÷t©aåßúšQ€U¤‘Ì¹‹Ñ²ßÅK=§;i%àÇsõ‘ï]|IUpÔ(çÔ'_zä¾F_Xì*¸è%û›?c^ò¹}Š’Ğ¾gx>ßâxª€O!`†š£	"E`¤Ş€›ÖŒİ…ÁáÛ³ùm*ıA‹Qtµ'äïäŞTÑ¤$”3€	“²ª!“¨¾BO ®i(Í7öæ<;TSÄßŠ…‘İ2‘'Ãp™¤öåŒ#÷jó£jU[fBˆãbÿu?5Ş@…l¬Œ×ßóOc[ã£¤ÆN<-A>M°À_«ù0çU5n±âğµæÿ-Ém}$ù?óç¿·Û¥üòŸŒ5ÿ—‹Ë—à¨¥¬çÃŠ2·ÊÁOON°¢ÈU"lŸÒŒÂHúïQÀèßÊnæ-É“SA©R#=>ÂÒ”h=‘=zb ¬ŸCwf¥ŸFÜ"QGºÊIØ>‰Œ–éœiHv°’¨Ô4Ùãè}¶Ù9‹%E¨í ¾ÄGæ†ÂƒÄx¸$\ãTpéøU™ıç_}6ã‘ôÿÍæÂùÿV}«UÊÿ§¤ÿ+áH¾$‘*ñÈÒ}Ş“¤DJf9¢£yVåŒ]†²&…Ôğ	‘ Ã~ÅÕ¸^OÖÂ_õjµŞü¬Y~Ñ®`œ“¼åÂ:t(Š]ÇŠÓ
*Òæñ·]ÿ‹ZòCŸÿ¨×së¿±Ù¬o•ëÿ	®ÿ4¿IX‘óéç«¸ˆó¹¯¶eÁ1@eGõ˜Ëñ0—î»äux
šªuÓì£k’ ¼‡=?p¹¼Ñlî4y8‡Ö‰‚Øòùaƒ®æ„õ¿èıçD~$ìâp,2»6séöİ‹ë›n„…àÀ£ôsúß\ÒÇcè­æâıo­Rÿ{"ò?{Åƒy˜«ÅšÔ·çö•ºŠ®XÍ£æJ×vSã7U«5ü·MH|>CÅå€~”Év¨ô]Î $eŸ˜IWTøë3üöoòNöôõô~Ô¿³*ß¹•ïŞë¸†gíéâ·¸ˆGş+¹…Ç=³ì zDˆô›}ÖLºhşq³ÊEŒÛ÷İIöd÷ãŞ	~r“×\ZâÑ»æêŠG±ÿvößN£ÌÿRúŸÊ¹WVÎßÚø›3eÜw<÷˜c~‡zèË¸N&ì#ŸÃ¡“haû£Áá¯D„å ‘ùyiú§Øˆ"Ãœ
bµ/¾ÿç"ãÿßZøû­íòş×§µşe òÁßdétûƒQ»7zşüyîˆÑÑÉp¤%'‹æÏbW¡AÙı§<}~üî 9&,NtR8—³ObOX(W â(7?ö­’Ü3ÙH]™ÿ.Ş¥hä8+Œ_tÖ7HÎŸ‹[s¹¢¿Ê$­— åŒ›¹R¡X.¡^Òõ	§”3E©…ÈˆSß·ªpĞçapÒ+8xµp
xyB•
(Wø‰G—?Ò!p9p›(tÿÁÿ£Zˆ­ßÕy“A‡Ÿ²MELU øŸ€}Ê¹æE‘G#Ÿ—@Sq^…júU¸y”só²ª—áëäÿbìüÁås>ÿ§±I)A¥üÿ
üù« ¾I÷ŸÊí©˜.¶ªĞŸÚ1<ï•ÊŸ¾Çöø2ñÉ°¬
5Ü“ºZdÎî$¶®0Ê­z\gäéøŞEpVdÉ×è]~mäãÄ·Îÿ·¶·Kÿß“Ôÿ4mVÓÿ¯P=åá½¶Ö,=«XŞFÿãxé¥¾wíúÏøTï«kóÿ¶šù;eü÷iééåsç_şˆ”8ƒZpò)uäó¾•³Ÿ+÷Áõ=;RBFšôÜA®—Ô•Ê3——ZñØÚàÂ¤Ÿ2Ù‚òïkòÎ­87v‘'$b³êõ>ÅùÌ–hYÿÀóY})*’R\~Ãñß{Ü®ÿÖõ¿fyş§Œÿ^ÿ-ºN{>ü-ïaıÏ_ìğğë¿±İ¨ÏûÿõÒÿ÷ıéhO!¼èZÅ¿?(¡#çW_'“¢Ïé—tŒK:äçÕÙú "OVãÎÉlÅ{qOk€ÉÂFú„&ËmnPF OnN¨ĞßGÍ³Ÿeˆ¼>B%9S/u†¥€Ó=İŞMœˆ×¢<™ÜçÜ0İéÉäJ¬E®O1œb–ë0»’$=%‰î¿^ŸyúÍÈÂ¹ETaƒüÜZNwâ.6Ò¯¿îN¤	Ÿë-¨ãUEßÜ¢XN¡ôÉ5,XËR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊòÍ•ÿ¢†r|    