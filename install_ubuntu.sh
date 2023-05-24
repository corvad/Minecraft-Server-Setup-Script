#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4220618439"
MD5="cc04174284b523ea7cfa079c77e8accd"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="Next Generation Minecraft Installer (Ubuntu Server)"
script="./install_server"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="."
filesizes="16468"
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
	echo Uncompressed size: 116 KB
	echo Compression: gzip
	echo Date of packaging: Wed May 24 12:41:50 UTC 2023
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
	echo OLDUSIZE=116
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
	MS_Printf "About to extract 116 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 116; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (116 KB)" >&2
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
‹     ì;l$ÕyN€ÀN…’ÔÁ»¹ñÙËİşô¯;ûæŸíÜ]Î>¯}pÁWïx÷ízâİ™efÖöâs@­’è¨¥—hÂ¯…†VQZU J“ˆ¤jHøƒ$(ME*RQtJJÛï{o~¼™Ûw%‰T©{ºõÌ{ßûŞ{ßû~¿oÓ™ßú'Ÿü›èËŠ½OG®··§§7›èÍuds¹ş¾Ò×ñ;ø4mG³é(™ej7´İ n«şÿ£ŸtF7€µÚ|s¡i8Í´½ø;>ÿ^xì‹œ_O6×A²ÿş¿õÏöm™İÈØ‹Òv2³¨ÛÄ.YzÃ!+šMªÔ –æĞ2iÚºQ%Úµi­BòéŞt– ¤¦—¨aSR2—©…PbÑ¬Ò¢¾L‰f”‰îØĞk8Ôpì]D¯@cşÚdeÑ¬ÕZD7Ê´AáËpˆYñ4˜ÉÃŞ}pj<)I“Ó‡ÎÏN¨Åf]³—Šàs¨íÙ‰JŒ!oH>€ çI]’F¦Gìf]•{ò½}ùş|o^–&Fû !Ûß_îÉÒİ%èèë¯ô/”4:P)—wçËZ9Ÿ•¥Â¡aUÎ¾Ë,ÍLLMONÎ¨Ê<T3N½±.ÍÆ¦ç§nUe¾å!BW¦å¯]’jÚ­©òQºêƒüPtÓ ºAK–VqÈa.ÃÔ"İ³LŒIZpIYâç©Ê Û¬ËëÑ¬ª­Ê²äRÚYuğm‘Ö‹T+SKíê’ˆ:eİ42P³FmıV
Ãúzs}²´DiC•[²d˜È+–îPÎCº¥©S‡=i¥mğGÃ,ëö%öÎw;RaïRØŞëåy˜ƒGÜjPÂ:*dÉ”érÆhÖjÂiû£T™ÃæšÇ©U’iÚV¦YZÈĞÒ¢?.‚Ãmá=ÈO>ê2G½Ú¨ö¢(	¨§†g©¡ÎAÛX§{Èì=Ÿ]Y‰CÇŠ±Øšx”dd”5H…ù)F“î¤´ÆàOÂ#Ò›ÈJN–Öƒ1ãœ/Ü‘Ş*We%`™lSÉª°R¤	Cœ$uÓâäpp¶àã[º¸Œ8V“ºeÓ} Äß‘§jTõÀØ£E“pŒ»ˆALÀf­è6$²?Ô&-ÃÖÒb
dÕ-?Œ½Åº¬ÕˆRÑİ^DiÕ’º`’¥!¿!àÂ`’VÛ$‘Ap†Ş¶NÖ_üh|bç’è–å
I-M±ãb;š^#©<i+K¤k7Ú­ô’OLg&IÖØ™¥g —ûï½ëd½KJ$½YÊ>Ã,ÔÌÒ’­Ñ,G2$—Í÷y_¶tu
]ePÿ Ö¸(}ÁV•<±—ô†š#&¼!Z†eÕn%’>Ç¬qÒ)|~’ª:$Kvì`ˆ=.Ğ}ª;ä¢ 
\&iGÑ>‘õĞ’|š ó™U‹Ú¶Oá€³áöÆ4C@”ë†tš–A”ı’pì¨aÑØ›Y©€íØ[UgQUz¸j2m5ËU²Ú›ÛÓÛ“í•â{Ç^¶u…#Šuƒfˆw‚†9€c0Ã.Dg¢ÛŸÓ¥¾Âwç±E~_@o÷èâ„G2·3„1¢Ø{¶³rûväÛ=ÄHmR&Î–‚·8’	ÛÀ]p¢qş‰ß…¿Ğ‰NsÙlqsP\P›µµƒúÛcı°jQÆì/†dsâ¿İ¶œd“9b†m?ñãÛİ­ñ:_•nÚ´5“…„!‚%à.¦:6b.YĞfÌ" >ßƒ	G4‰’${Á4 ^ñŒû!ğğ|VÒ²w/›<Dp„²øë¾/®n'÷şI.	¾¨ã ËĞÄ´À“¯€^0›@‰,Ôğ'•bİà¿0ÃÂƒ:èG­J= 6Î õZ.CĞÁZ‰£;5º‹”iEkÇq_”€3JKiA$ápC—t:í!®ÙuÒ[m¬é†E&/L$ı!:œc°Xpl—0·ÅİøÆTZ¤¥%BFğÂ8´
NpËg<h‰ä“dºiH´€B7›ôçíäæT
¾´rYÇğ2`³Í:NèÛD6zF¯è >*F™+ˆÓEDºÙ2áPM÷k[·ê!®† iVÀ3#–»¬È$l(óã‰Qˆåpwƒ88J°Š¡–ÄtÖfÃ¸/–³aŞæ‘#5LºJKaPw:XXì¢Ğ-‹J±;$t
#œB R‚Éİ¨”H$pq¨#Ş†Ú^4WØê}ˆrÓ{)ğhÉ¬7°NÁÅ´šËÅ/Ü·ÈHVaUughŒ®b4ÍÖ»êXZ	ƒrÎÀØ\jZ*å&Dw..ßGŒââÜ
§N´eğµ°qL4Ğ.XÉŸÙ%h»ÛíTîÖl³Öt(j‹Ö V]¦É:K:£ëZ‹4`Úª	ƒaW6nœ“¥Û¦4 R2í­¥$bcUó(ü'“ÁÉ0º¸‰‡ˆ(Â³e6«‹¬QÀÁÕ5£ÌPÆ-ó#¾Œ"¹¢ƒ£º ¬ Ù6œ‡{Q†¥êª\¦|;9>:ÏB:™Åt²ã­œ+æ'FûÄ`JV<èAF²ø=Øş+ø5Z-cÛµL¤‰½‚f€ÿ o¼_^—ˆ~xú FØÌ€¸³¡QÜ»#¦iGj]¢Ò"©—ûìfœ<é‘Š¤–…FñWn2½¸[V<Ä2Âm=Kû"şwƒ¼¬Wq\ĞÈ¦à¯Åà0ÒËk-Şl{Qk§SĞÈ&á¯Ñ­xˆÙV¶%ß×;QĞîÍÅ[ŠR4Vaj=ô&‚qŒZz¥ÅYoØ@Êd1`qC”"º$e¾İ»½Ht¥DR%ŒH-LmÈDæÛgbÁit•‡Ï¨‘˜…Uü“‚ÀÂJV	h‰…§ò g©‰ùÀIRE/”ğêï.ì¾¸ 6ÂĞêàŞ{pEF~8Áv39IiH)c#ì¾Ô[ Å.H˜Qp6Ã»M%
kóP#9yÀ‰‘-Ï¿%¤Át>èAMgöÆWP°fØ7°å´Ìœ?ÀÊ<ğß &M‹á¸—­¹)6lœ¥DŠsšÑd(©şŞâC¦àçùNao	¾1æXÀÒ#Ëµ‰;0R©Pf+–Y'œÖîv æhø³¿·h'úÑÑA(™<ÊåÆœB†Xòy„}…¸Ò×X[p¥Ç¹’ë%:¾ö®½(p%¼y\	@[r%>®üMq®i–ã6äüYÎ#'X˜åzòí,Çñ{,‡›ß„åÄµ"¿¹ö.†ßß-¿…¦;fãÊÔˆç9˜DN8Øò…%õÛ~€Ş6¡-w‡721:?vô˜Š‰qÂ0ù©J7™[ïjÓŸ€›­‘oiK†I+.º´ş!EÎ?¤k`ö¸“gÔõˆ|Tü½Ì‚Nv’îÊ³—¼Ù%ÌN˜#’sÛÂX»Ç4nhÕ4ËMsÖ˜ËPÆ!BXÉ-Wø¾àfäĞ{Xó¸ Œ½çûcø_–‘v<7ê8­!²„®p*×Geˆ¬K~ÇC‡¹çV(ùÎxâ]ew,vš¯™fC•‚¨d^ğ·d6Zªô„Zö¢ŞP[ò‰iSè— ™{¦\pïàfûJKò6Ïæ¤WyV#)%ÜTŠÄ>+%†x?uƒbÔ0~Ö’Â*áÖSqØ˜„/°{[êg8Y¦ ıã©^ÑKì6p/\ğPv»g"øyĞ¬áE¬°€Ç5Höô“#Üî‘ œ$Õ[õ†Û>ªaxWÈ§´¤UÁE$7¢j‡à-ßKrùÁŞÜ`¶ÌÎŒ|6ßã:ĞÔkOYÄ'•<°eß³]Ñ@e/êÉÔ½Ñs<Ã?'cTèĞzcNÚÒâK[•ƒØù¿¸XM¹Zƒˆ*¤·X º%Kø×d´Â,ÏOP_,0–=%êæ¸”àòVbJ&˜‰6²}DM»N<‹Z±/æ‘ˆ<Œâ™–88»E¾ºòĞN›˜)Ô›Øµ¯[˜Ÿ0ÅÍ´¡k…Ñ;’¿¢âÅI4x™—)á®1€ô¢r‹ÖÍeXF”ªîB¢âš*7ëÌ‘yâ5>|`l\s¥jÎ“˜ÂÈôá©lçGé ¤tâùø EÁÑ»SwºíGÆÆ¦PÖÙËÑÉÉccÓ7NC‹Î¥prbjz¬PP	.áçä \òqºÕĞÇŸüp1Üxò[!Ä-şØ˜º§?h)9<¥öíŞC«š]OJ~Òx¼0!eYÔ´ÄßbFè¶“ÜP3Ç'%âcÉì±d".hL`Ä\·±Ñ1¾#’–53—ÄáÃ61Ï	f›Åı%X*yÁÇ¤¼ìèm„i{p˜H×²x7ÌChş~SÛE«,+¸
3}¾s~²ÌGâ†%¸øü­8HXÏşF- O€Wµ"·›@Ìû»•±œ“ ¡xEYË¦ÒëFqs`¹“›q¼…^H, Ïa×øn‰æ'q¶ r&çêŠã¢Ğen+a!SÌ/Ÿæ—Ï` J53æ˜‹,esœ¾!^-ññ¦±äêLÁÛÊµÏß€`œæaÌçâoíPI¿‰•<¯ãº¤ï’€Z0«°6ØšV%ƒÜıb>vØİÊùˆqx!µµ’ÄXVŠu~[g7d€½‡×¡š˜†U³1DãW6Fê^§i¾:wQb=o7q¾¢š¡Yí@ıBÏ<—ëx@ÅòåxÉ²AØ †ªëº›°(»‰‰v»Y6“²¸ŠDd
x-è…ğÃn(#Õ>l¨ëøòa:w¥yß©7¸<¹%m²ï‘¥•éá££“éb]Ärg«³ŞYî<Ô9ÑY‹iEaêKh©Áj3D,á¹æbÄl‚çÇBN8O‡
®‰è¸#E²#f(p[<?29u\õfñ×(5J#°'v{ïa“xw¨¥Wm²" çÈJ‹u³Lv®Æö¡FöåkÑRÒ¼~P¼˜„A?{’Åc .Ænı)­“”U!E×· J¶({#™H¡úĞHm…Nà ‡Ú®"Œ~¶ãÕÑ
%‹ÖtTº¡ÕöK‰A©íÊ^˜môpaj|ø8w}]”[†7ãvrÔÜEšàSİ´_Š ¬¢AºE¬da¥‹e;¿‚e’6¤Í]¼Y:^tµİCñ«–›fÆ¦'
ªÌGª†Y§)o—ÄZ]†U9¬‹²ï1ö½Z)ÑŞ ¬¶ê?.Á€%p†Mˆ%5Ë»ÌšYmÉíõxÇŒº¸šØzÀ˜ÚW4²/Şµ1¼ª¢mÀ4èùVQ„Š!¼—DAÉ¢XskÃ«ô4pN÷›,È²ôê"ŞËÁ®³Ö³]÷>ëgõJ¹"°œ‘ı#/ğ‹TŸ+·ÅW• Ğ)Œ$Åj
ü€™¤(Ÿ‚ÛPxö°ı¨6,NÙ
:s3D(-¼úÕaQÍ„õ(Qi<MÊY…è#…-_HUøÕ¼ANÍ«Q'á:~lQG_è´z-tµl¬×L‹I…–›úpü—È;ÚÔìq“»fñù¦LL”5{±¡Ê©†,d²¢F/ƒ¶¤z«¢¸&/ºã¦Na]ñ¯Ëu4<s!Z—gì\[Ç†7›XŠ€–ëXxİGèŞ¾ËjU#†™È3tª\l¬”‹²ÈU…±™Ù©ù£“#‡ÆFp»¿È.,şgŠõÁ„ìí0+)Â
·å¨˜ÂtIƒ9Ê)Ë,Qp“ö“›gŒÄ+÷Ml\ç›HÄ–ó&Ú¥,†ß„5™4VÜã¥â$×|Ò’Õj0†dù/÷*'+ğg
h°`Å´Ê»ÜAn™I½á6Æj=ğ×**Mƒ®šÙ†O¼ÍÀâÔ)NüE_ (Ü ]<¥¡WÑš•´&¨ê]$PÕ5È\CèÚxÒ0DXfÎõE|>Š-–îë"9’'=ğ%²ã´­¬F+~Šb	t0[1¤ßR¨gı1Q-å‡I+iÜÓ¿>‹QpG±ØÈ`…$|)ˆùR¼1¾¶¢Lºƒ™€{“xšAÁšËnÆÖÉÈ&›µi¤®Ç{d‹%ˆíYlÀ‹{0Ri¸ò ­­Õu+Fh_Á¸4z™B´áşñ²pï9P´ŒÃ±ÜŸT,J9eÒ²´‰‘Û´¢>löâ ®Ÿj»xÚ:ÒÍ=tŸaùÏ†”à§FàbóìĞjƒ$In_ô×'¡;*?œ$KİáYxESjÚ	ÁjCcÕjøUhLò;$á>…„{çÆÙÂ`\Qnò/æ6"m¤t#&ãÃ¼Í “,
»cŠ&+mp ğ+ ~Å×’ÛKçÌS™Ášy¦Ö¿şzÜd­¿€ö>–¯Óµ!˜áé‘CÀàG‡'pV!‚b	\YÁ?¡v1—++Â[ÊÏîÊŠ÷ô»¿ëñ÷îo7ØAx/1#…Mx«¬N\†ÇÑmtp8¡‚¡É#ÜF£‡Oãî*ˆrhûc IÊ1~=—h!špNS®Ÿ“eLfÙª²¨] .h¼(:	>9œÔIÄú6ÁİúŒWBªÕI—;a—ûk¦³İ‚ZüÙ)X˜@°\n¥¿Û±&QÅ(	œRºöËØ¯Dß{ÑÏÔ·o|éĞß>~ÛØÁìéò¥Ï^ÚÿŠvíéçŞÓõVúG{_ïÏœş\×#ı/>ôí/}ûŸOgşûcç~ö[·'åÍ×.¿ûÌ‰³/Ÿ8qãÀÇÎıàşÏıág—Ÿºë›ÿñ³c©_ß|ÏÁs{í©ãKÿğÄ×¾ğæ¹ûïÿñöŞêü~§tàå®ŸÜıÚ}½÷}ß×yeöÕkğØ§¿şkã¶3/\ıóôwn«Vßøû·Ì3Ëñ–ùø›Ùÿzé®cï\ñ•¿ü·ÛŞø÷¿Øñé{†_¾ıºï}càæ_¾ø¯½Êä]ÕGnXª¾hİ¸¯üêÏßøÕ}õ³Ÿ±Æ×¿#½÷YûÔ•<wöìŸ|áíü£iûñ“=5°í_f~ñÜO?œP¿øÔïå¿ô‰Ëÿéù©'æU·æÊ\òñO:>¸zú?ü"9Óêš‹ĞÎvüÙ½\±çÌåçŞÿÎçoê¿ü™ç=5øÔ™êß~ğô›/<yñ7¿;ù“oIşñ‡>ğàû6ÿà²Ò7}U;¸ãu²ÿ¥{J§®ùÚÒõu|¿»Czÿs©×W¿Ü÷ô«Ÿ½»ï£õ÷W<àûŞpYæ¢“ßİıä'õÁ‹Ï<~åíÅ÷¼rç‹»ô†·Œ<ıÅWçÆÕ®#§®ì>ıÌÊÃG¾÷ã{¯ùÚç~ÙÕwàäŸ¾Ğõ@}íªCõÚ“_şä‡.yê3ùOMşê+Şùá}ßøêUï}ìêK®¾ıxş±×ÙêŸÿÂôÓÙŸ^õ£¿yô™·şní¦½ÆâÙşûZÿÓŞ‘ÀÅ´½…‘¬QB·iÍ´N)*-SÕdšRÓÌT£fi–V	Ù·,Ïúìg‰g/ñìBÙyö-KÖ
E5ÿ{î2KeËã=ï?W?u—óóå;ßùV2[ú:İÚÂóÎİyX{Õ¢ ƒkOı±/{HÛMıËèĞ}Ô[•Ç¶¶´bkS&/««"å›/«Q¾b”<j†TŞÿÙl?3Íÿø”r~Ù›wíèúiµCèüQÖ.ªã»¨ŞÍK^‹š¢ÍÜÚÏ;Êÿæİºø”gù{¼=&Ü=aA¢	ë@w=Ú”îÉ“ïßª;ÉŠ˜MŸ|<kp×}ZÛjGÉ¶O{ÒSöİ6mRòšıúÏ9Wvö®iÒZi°ÖÓ{şo[N)ºõøƒ7w^­lc)m¶ãìŒÃä—„©y>«œ½ë„×£‹†·Õ:rht÷~å¥²®‘¬ÌU×LŞéf˜³3KLÚİMl³¡ûìûë„i«_ty¢—nÆ9Qt÷NÜ ¯$ïÍšk?¡¯ä`¦öªšsqV³yY‚Gí£fm³Ÿ×«Oü©ÕÛÇÄ~ÈPëúÆséÓc©N›n]ª»-Ø¹e­üumáµ”Aµ/ãgfn5~…®íMŸÙ™›.mXx_{<3¦ùÎĞbçß2×¿‡_Ç?:VxóÖ–Ü÷òŒùö£3_­Î¹(r2¾Ø×½…Åâøñ–;­G?Øà$á^(Ïšó*<t£N»”Úäßµ®×|x°öCæÓ¨Ve™ëÏ¬Í\n{†2ëø¥Ğ¢ÍËŸbÚ'lü@ ¬ë9øvÈõWİ{yÔÎzq­‡Ëül›…İx´¦eÓMz1ˆ÷î™ãùfopoƒEƒN/­É—^0úm7í¡­Î€½Óü/D}=&oäD&zÚb®véã‘»I9Í;8æ¼Ù0wu«‡m-:Š
6Ïeì»òÈ¹âCQ³JBô/š6ùâEæã3É­V\_s~¾8ºxĞ¨G]›¯z;í(­ùì¾qCKÍ¥«²<ºpiMÅFãñcø»`ÃÌÖ7+NyThà¶êäÑ_8QE[©Gı–ë]{¢ÃÜl8{ñÚØ¬$ö˜î0@ø—ßò]³M½ŞkÀgÎîf•ÕÌ–Ûc àEä»Ô]´.£|Ê–Në2Ô¿Ãáşãò=u‹(ÉƒïHî†šåNÛg}kÃƒ‚î·®Ïò“qäØg-¼|–…ï‰b“¦ª,Ü]=Ÿ’[5nf›Œ†u›6s6G¾½cıf›ë³Êvºş£g[3–Zœ¿¥öÕÅZì5†è•¿·¹†Ü~øÑ©‹&^¹¥“Hdìş4¥nUÔÔñweµj18sLğòi¯õ¦e™i·ò´Å’wò†gİTóşÀûÅù…Æå³û®ÚwŸ*XDìX»çEøö3{æJÖê]2ß~.ÿtÆÊq%„=ü§
Ú¿êN;Ö%áæ U¯©“Ÿ¦¬½fTà9€³•’fÚgeÍD»)ÓªkÂ£´vÖ9àßÛã¾´¥nøåê¦n™-Òé=³êBÂˆmÏªºl£·±ûß~ºvşZ’f«›˜IZxÒ½EîØ^Ÿ‘Ash|€n›Ì6ĞŒ²q{ÚFĞŠ}1Á%rb¿İw³ïî]™5yw]ÿÏáUËŸ®7Ó­DDêî %ÈÒş#;f·×øæÃZê”¶©j?\?b½œY&s{7¦‡ŞÂv†ãŞk™¹å½ìµJë”Û	ßõĞÈÕ×‰¡ZÜíŒ`a^ÿóg®<í©Wvİ¦øŞÛ•fP‹š£¬ƒ…[Îu×Î¿¶ùÕ;ÁÎf#7ÏùkˆÈ¸'ùPÈÒ½ÌŞkŞÿ’?oôÑóÎ[;ó'/7.sÙ€T°rPËë./åÆIıZú'/®“äÊ3÷Ü<ıH~qÉõµò—£j2­‡Şje µ “xÍş÷F–óf^]e¹ºÕ‘©«¤ˆVÍÜé ]iÑâ±ÿÊ´mî?š9Ù—>Şàî€Õ¯c÷É»ÑkÍx?·’Ü¬‹½n¡vyRöÀ,éºÙÛV8Q¨7¼Úëûí8ié¶eíb;şæ­›`l5¥ä°?õÚ
Æı¥×X>§º›4kFØEÁ²ƒÚ²ö„N|xiä]-ıFÙ­LÉÓ{"ï>sQÆ”½}ÿt¾2ŸgxvÂÍÑoôB²ƒ)‡%VW>Ú>‹·Ut¤÷ÌgOo|l»¡÷)İmIG£Z†^•têU»ìó*{N*ïdä\9ØŒ}§ıÃÇ%…Ä¢õ‹,¦ÕXkié:–j\¼ä×è­×»=	jeøvBìãwâ’ÒÏŞŸæq¾õš^>s-¤¦ùcº¥w43™ Ûj<ø ¸p]	a]ó¡#ÇmplÆ¢PÂ¶ƒ!9EŒÃ†™íJú¿1ºàÊYwD÷øÂ[ífå6Ü»¿ªßµi{V­Ñ	ô8JÂÕÅ.ÏééqèÉÉKŞÖæ'\¯‡ßêzVgnôW[§}–te¦9T­¾ª“ºAÏN×ÎcÌ½ıúUA7[+{U©İ©”Q×ş9½½ÇW3Óõµ…]wë–Í÷W§íÅ=&Íl½xqaÑPÓË¿1£NÿæhÖ-¼t^Z[OÔ_šÕ’^‘8º™²—¯£Fîxçô`ÕÙ\ûÓ—Ol?“ÒcÉev‚ŒÛmEbş<é–n¡7İ³ö¦t›f”öÀßpg(½…óÃ3";eX.Èœ-Zàë˜cÑû©®MÆü°ÇÏ½«3iñß:Æ-Ğ%·Şõ*ö€Ën»K³M;u2ëÔi­Ş’fc?±™kP4?Hà·zPêÈíu`Ÿíz­èĞ³Ò9ËoÔœJÎÊƒí¨y3òïîÎ™|pTw‡JÓç½#´ˆlî—E9•>KN×eçœ(™?2°Ë±'Úµ˜şÂeD‹ô•%ge·ÏÓù^[hViÇlYÁÉ§Ze!ÃWµ·ØP¹v»…öe#šYÕüYQœ£•”´T§,Å›C´ªŠ¿3E\bœwºà…¨ëä¢Ê=q¢Áå%®zïNû[æÍîŞg@øÔqó¬õßŒc•Ì4cû=.³”Iåı<íoZœ7¸\Gçü\.n1'Ê7_ûš\Øq–KÚÒ‘¾'Å^‚{â=£B<v¾9¾‡VW¼ãdeá²çòG™Û÷Ÿ­=&_²9IP3âyÌê‹òÂ˜šÂºí£N­µÓa¾.ğ4LN>Ùwm÷S¤—ÌÉWY¶K«ˆ¹î[;v® ÍIœÁéªÅÒ·»İù·€‘E§kµy][tyÖ†cwŸ÷¢üğş¿ÒCrEvµ°·2¼İR·|f	éÊ_Ç›ä_;ÿŸ’=¢âÂÂ¤½õÆõß6¡"vĞ›_^6K¼ßÌˆ¿êõÁùK[<JŞüîÁÚ’	ç.X;o5¾W¡5öä–ôÀŒ"ÇN´0û`bÜÂ‹q…SJó\%íãä—Cäºf«¢{té>°wábVp”ß.ßŞÔàÃ2îé.ÌlÓf`‹/½õÜ¿'ìË’í;Œú—öéÙ¹ç«3#çjg\œ·h}ÒbãHßÍ§k·zCleD¿ûôí¬{o§­Ê*ÿYjí_ö´ôÌªÒA.Ùo=³-?WŞï¦ÿxÿáo·¾qFŸæïP8ìÎü9¹¿†zsFk¬›¯œU¹~@ÖG0IH4L|şviDŞÆša-æÓö[×Õêîˆ‡å¯ç¾~“ŞÍÎ\0UVVubˆ3+k„Qñ£6c6,w9ÒŞ`VÉÚÖ†:;ë[9Ô‘“Ú»P+Ù¤]Ğ§³‹kš·?ßa˜wÏ9y¬øóUCt-çzeA\/£’ğV¿ì=-Í5rwKïA¿éL÷€p/»ı]Ûµ+i«ıêì]Ñ)g»˜}-;ºÆ¬Q–†–ºfåê,ñö5:³ğÌê‹NÃZVMà_‰/0_ ¼Ø·S—ˆ­¤ìØ[¿ó{KwLT^a©µ}ÉÁYÃc’·.¡¼¹¼ÔXgIp¾Í·Ö®<:v9¿ÂÿÖ„1¬M6­?øğß¯yw¦Ï;kPŞÓÖ¶‹_Òp:óÊÍ×uV‰–ş9©M'¦O¡£×<û('W£«Ú·íé{ mî°_­K±4°]»àø“°«¯lkSÀÚrò˜¹ÖÖéOšwu·h»(¶[äâÖzI–¬“;üc–ÆÏ\{Ş´("=Ñàî½EFÅŒ*twNy	Øë|ıa¿wÖmífÕü[|Ÿãë‡vôŞÙ }©Q¿E”ÒeÁ"shs™fÛjôÿ8Yïâ‰?ÜO‹êæ“ÄÚqm&ÄtÏâu¾§ØÎißU™ÃøI}&$Î<»vxç4ı róÓ×&Eõw±XZTk¹æznV·’	5%Ë‹r6°wT&ºéTîw—W<ÿyıYÍËàMƒßgª²êöÊ½:óõïàu™ü×æ˜'òZ·ºÛQtƒğ†¿w÷ÀzBÛ>–·)Yø¬ïcCöšş³Ì‘u‹Ævu&W/xtb®–É£r³ëû¯öÌÙpgåàÒ‹Vô”GLŒã”9L|tìÃ—Õ‚šğ6“Oßº‘ÍO´iyğp/²Î™ÁöDjÔÄ[¯7½5éÏ;¦İ‹v^å÷rx7~Å¾¹R™åã—œ[Z3Ï›ï0[ãØcü´ƒ{‡Oüı½Ø}¼]Ïè'íÙã"ä^3]¢]sdçÔÊº^ö:ÓsZô´×KˆvÛº˜°?ïÄÍm}(»Mİ•ê«)ÔŞqìµùu[’»„Œ-\“jx¼Vç[O5>—²Å Ú®bc7ÿwŞíwF>b.%^n2¶ü‘|w·îvó¹ò¸ß{UølÄ°­üÉ\ŠñÎö{d»Z%¥%mliZµ¥£·Ùù*’kï“³Ö<zğº§îÌ:‹ç1—;º»ÌŞÌ™Á¾{˜d:Ş™}mõ1İ?K—®I\SÎ;mÓÑ(ñÈ¦ü=Ï;Å½¶_pö·Éq-M›tß]ÿözã•µsó†uœèæL¸§ÓŸaÕşšÇá«)÷öèéŒìy¾èuÔĞÅÚµY2#Ç>½¿¼R>|Ó²Bùúá³ùårÓ'rFßU¶ÓÖ¼±CZü!ñŞü¬Âá™fSdC®ü¾ôÚ78±|hHÛPëŞ×¶ö%\(;7¼Šyå´²ÑiÔı<üS‹&Ê¢Ø÷ëDlìÌ<ræş’yÑğòee™oüµ.£7ß4RŞNTkUtcúéGó¶Ş×ïë}6¶c¾Û:Úì×k´zõÛ~<pö•9n)·­7f”p6—Å˜DÌÓ¹9Ë½ÿóô‡óïÌ¿şèŸ®{Æ†tö]w<xøãJŸk5_z/7‹éšÕœ“7çZîâA./—GŞ–‘lú¾ìÛÓåİœ…İ.5¿"ÓLŞı*g%@™òÛÁOäP¹gFêÄ_ÒN\ŠnéöôÌ±¦>WÎì|ÖŒ¿NJAØßŠvaã«Ã/óÚW±4˜²ìn5Õüúøó»Ö7ìİQ«¯O®/~i½(yûzÇÑÛº¾±ÚQZıd3ÁxÑÖı¥ËOeVô{¤ğŞ‡Œ¥’åmìú«J­è´«úwÃ”¬6ÕÇw>í’Ç¿-‰éuå~AvµåÕ½AC²+âÖz¾œ>ÈşÅÑºë<›k™ıŞ0äé!ïWœŞ»pÈY~ÍÃÃÖïz¹¯[ßa¿ç+ß‘VoMÙÙ‡UŒòğöøáÃ‘£^µ*òr³$–á¾×^=¬ÏÍEâèÜ­ä±ÚÄw÷å·G½ÿ`ò<fS¾üksf‡©ùÔW.£Ü
Vß?$ºñ$ÛÄsìR×h©Ô¡[‘™ßë“«jLãgUzwœ´€_Kš½Ü¤Ğu*ı}¹$ÇğìÑÏrN<Ôír"×°—çê3g%Eæï˜ÎúƒÂŠäÖİú'®xš2òJv»#rw#f/šn¾9Ö÷„‘•«ØÂ'¯×È^"î¼i»ÈqÒo“Nu,v¤ˆí¢2›±SÎÛöMÙ)½œ$óÎÕë54¡Üx9óàıÑwFCRù¡ºÃû#çlö”ş‘rå¼ÛçƒRs›Wy®XÍw<3ƒ˜­ççÜƒ<Ùò~~ÇKÌ6ˆRç;V0B‹DÇÃÊ3]¥c•^ı 6óLyİ£—‡åÎÜ"•s·ÜßÌ|E'=!O7ğ¡°xmú³lšÑ«5KbtŒ_´nAqŠÙİ²ãâ…Í^[—¹¹Õ±ü/iU‚°8›Ø7~ûƒôÊ™[Ì){¯ğúæeµ™ûgÊ=j3§^ˆq¯•w¼Ú]ğ¦%^—˜¦?ªôœ¼pøÓô¡[äóéo½I„‰ÅÛyòÂ[½_ÊS†½§syQSÔsî½Ø6Á³'$ÜÚ-í²]ò°gbÿ+„µSB&t°t¯ğ]¹é ×NŸ–[Tœ>zi°Í[-ç¾.Oª­gîZYõaãïÇòê‚a[·~¸ÿ¯õ‹ŠR'½o]şÖ•¼vC+·‰ÕÍgŞÑqkvßyY~ªŠn$/p¨!œì¡_s¿ÅøÂï‹#Ÿ‰Ş•K¸XQWè·¹Rîî+·üËgª–íş.Çç¿h7ıÉ‰*ƒê+'×<–øTYğ3ÆO©É_åvıåÉfô#.-’8D¼±Çjå`
«yÆÈNææ9×oœ9`Áî&!‡
]Ûıò:Ó>1cb ø˜¥àŞ K-çcéûn–õí°Õ7Õa¯õÙÅ¬}ÖçsN®æ2}äŠ1}«m†|Æ˜wq¢y~Mš¤tã³6¥]:m·Kâ)¬ÓÓöß(xŸ´oÄÜc[\VÎNb‘±—š÷‹÷İÒèa–Û¬µáZ
?ÅX°}~cšl¯i÷ÖªY°ÖÊŸ<şc Í‡J%ó9ß3ş§³³óÇâ:Ø9+ã:Q@üGGÿSÿñû_A4&„}€5$b–õb[#;/+‰Ç|„â$VlE „(\=€OFWÌN…bÅ,”Ë±A¾ÂˆQlÍ° ¸nHàÂhàBˆx”#($(:)Œ‘&§< ·fI$B6‰;É²‘X¨[ğ¢0‹ †b%ˆÖ6¨ê“•@Àb³à¯=40s%R1qş°xv‚Œƒb€×	<>«GíÒ0P™Æ ´Óâ9¼ğ›‹ %’E'ğ$q6 l:Z&…JÀC¤'m ¶@QÍMH v³<®" Ş:äĞtÄwFŠubã‘'ä«cÂ“bdb AãLp„p—!5æ²¥xä	e¶P€†‘¸@ÕÄŠ‚0Šñ¥pSÑ&Äa¾5Ø¨b¯$q,Ôí0$ÄRAØGÃ‹G åÁ¬P6"î?õĞ$ÃõP¡Pºs¨ƒ
ÑB¡}Í—ê½Bá{¢4”Æ ‡1!ø†W03¢ûA^ÁáĞ Z°¯D†(&!:ƒ@
	¤Qág´`ŸÀ0_Z°?ä—¦Ã“˜Oe(“
1P4j( DeøÀ·^Ş´@3Ü†àGc˜~tä…x1˜4Ÿ°@/Æ¡‡Ráê}a°Á´`?\5ˆÌ$ÃµÂÏ êøø†‚ª^apë }°åeĞü˜P =Ğ—
?ô¦Â-óò¤¢UÁHùzÑ‚l _¯ /*RŠCaÀghë ¡TğÔçÿø0iô`€†=˜É€om`,LEÑ¡´PªäÅ …‚ñcĞƒl ;át\.˜ŠB]©ü	¸¥* B¾T¯@V((PÄ?&´4×,ş3ê³ÍbÇËD¶ßkÿw¡P¾(ş7ºÿ;Qìœ4ñ¿ÿ‰ñ·³'Á?ğØşƒãO¡8ØkÆÿQŒmœ0ÃWşßÎŞÎ¥Şø»¸8Úiøÿq!á×€K¤2Ü§Ä½©9Ü.àÈÛN„Ùä‰%R5¶à?ÿ¥?>ÿ‡=|ÜW®g°ÿ;;iò?üÈüÑ,IØ÷‹	¨}âPn[ÈçâGË/ˆaŠ8˜B£YI,ˆDÂ{ŒbÅ\dï‘	˜m"e‡Á 3LÃ#æ Ãƒ£¨Û›™¨'&$“àÎ¸`{2îX<;áÓ(8(K1Ã
rÑˆ8b>„Îm`÷¨zíyÊÇõõ=ÂŒ-MUíIù²ÈR5<øã†UÇíŸÃƒ-'4¤è¿YLrÑ %ÿ),Ìê£ïªÜdøSÈÌ †‚Ù—`¤ä«Q3«›ÙG3k;3=3Äã¸‚‰`r‚ğˆ¿ZªP%ğâÒ‚xÈ @´>–€r6ÀĞ8ºp€HiÑ{B„"ğáı¶Q¨×“Á 5l…×?—/’¦"cV¿»y/4¼v:¶øzDÑÿª;|§r£pTïœœ);'ZŒôö^¥°'ß«†`úTG(P&C|ÜÊå#®?†6BB% ü£'ÔËßÛ —BœµÌÓá[[Ûv$×Û(âû „6”Åá×Ur\A¬r›ÈøÑ\±ÖfêhÁ6‡•*ii$65šÅKHÅ¸d‰'@”@Ö=4x †µb¥ó2¬‡º/hì—#®º	0ó#T°ùœµ şŠ“
,2Àt‡;ˆYÙJÜmÙ#%îVÀ±BQh$‘áN[ÔçAb‹Â›­  $a °)ÿU @‹yÔ»¥z‹O¾¢™$Œ$üÆ€¤~	ˆoé—¿¡g¾Gßü-½ó-ıÃ
`TúİSB“!a1£#Å\	WÚ¤6¨ø–&Àåe¢oi
 )M@d‘ NSêW)İ”Ê…b|p‰T¸òb›ÒˆF 4¥1hxÁomL#PšÒ	+‰ûËCµx“ª®êßR£åa@ ¿Pğ__P¾iEßÔ~á7m Éq<)ÄÍû†64€Aà'áLÎ¾*álEƒmĞ‡¼ÿql<İ„@V]ĞÛ¿^şÇ zù}OóŸÏÉÿ]êÛÿØ;9jä?Dş§"Ê bÄ a}ñè´¡2˜Œ^ø"‡$àª!@Âª9—%ArÂ€ 4,°¹AƒÃO ñy™”+!C^pU|P•ÒVa±ã¸UKìüD&Be"°+Â„êF AjAyá{:²Cp)ŸœÃ\Dğ!`F‹£Ç…Xˆÿ´˜‹%‘v5É‚!|È“ˆ¸lZ—ÒC‘óK™(‰Lˆ“JE7[ÛX¸é²h2[È‡9Jq‹c«À„6Œ„ô,	íL[¬>‰-`f†DBFE1 $ê™BbP{DÖ†Yñe)dyÔÍA£òÑìº¨ı>’ƒ·àŒ‡F	a%!Zˆƒõ{ñÁ™• ¢†>¸ˆ@``VBÉ˜tB|˜• C Qëk¸<‹¢
c !‰‡Œ‡1	®/B„Rp+€ª	‰Z‚!qB¢ÅH§£C#dpÄ¸ôƒŒtC&p¿ÉYÌ‘”Qf~ŒŸXR+0=‘>ÃqDÕZ±2ívÄî‹+QäNf¥’Ã)¤™ØÅ%è-¶¢ª2¸Å01ü
Şê3_%7R20˜S‘‡G³@lckTr ºÁÛ§|qe°lTPˆt‚ÚÌwƒ!±ñHØjØKMJ!ÜˆlÁLmğ?]»b0¾°vUÈUN`Â³‰¯ceD~lº 3.Z-„8;% Ñ4A„AdÆ£Ù¡Ğ—ğ¨E1Å¦úğ‚·J~FAÿø˜°D&â †Š,6¼ô­Ò®4™Ïœ†\<­áI,	dá‹ÄÂ$0µC£@7LÄi˜nŸÚtÆ‹çîF‚JAØ(0ƒÃ“¢7€>c¡¥Dp!¡DY<! >HwAŞ(CÈà‚$Z`È€É@…){LMÖàXï|ÆÓDM‘¹õ¢raD§¢¤È¤d0C‹‡mDÑÅs ÂÉŞ	ùî:@,bdR@AqY*²„aÀ“xXv®d¡8^©ÀVg¬ëPƒH%@ÃıAğ¥…"–{T†<\4“ˆá¢œ'ÁÃ-ƒNB*âó$2	ºÌ•SşIIŒæD-³8\>K/Ø	1z$$S¼)ˆŸĞ…,º5G³èLÂP{ƒ†¢šr4‰Árø2¥¼âÄğyŒ¯±ÿqvrBø?gGıÏ´ÿQßu~¬şß‰âRoü).NşÿŸÔÿ£›?z@˜Kì(@ÄŞÓ™T74y#F:ñ-°IŠ‘HŠ„ÚÖcŠ`L$æñÕ¢:ÃÄ†9´1	å²$d¼ú¡DÂaÏèhÆS7üÅ»˜MBäº€£h(Š°€B‘Šõ_8€BQƒçğs°5÷òKÁ,Ò—'‰·nğSÜpLÖÓh"/‹²Í#(Æƒ³ˆ Şša¯á–d×áŠyH~ŸŸbã„)í”_¸DÀÅÇ_‡4¥Òè¾
0˜VÌQ)?p…±‡y,o”
:öpW‡	$w6†	ÖÊ`a2YEÿI[ü.ËÆ2Ø ‡	ô†€*<Í 7²Sê<ÉãcZ+<@°o‚š¤ğÓå/¯”ô}º¸c£ÅU­Ÿ.îÔXñ2¾OÃ (a˜‘?%ÿV­£‰4^‹YãÕ8CªšÌ¿MqŠD]û¸ê‚ğ*ÿõ'® E"®ÁÿRÕ ˜¶q5b“Ë7Péb«J¬  f#Ü{æH¯"|±R}KøøøàúõOZiÀƒbÍâ¼µÂeKİ`=exªZ, CÕÀfRF¨ûb,ò¢½ğI97©Ø€İGªmV³?€‰/Z>		AøKE—ŒneHÈT‰Då…efá–®¸’öWÊ$•%Q9!	Œ‰¢I¢Ñ´b¨±.@Â’p€ÕÏE$g Ç|ìEƒ¥~l©L£OéşÆ²M+İ€,Ua5µhÓÊ¢úÌ¯+«¢ºøº‚ÒÏ¯ ¾	|UIõİëëŠ
›87ÙtËR'Â0	 P¸<Ì‘U&‘"'W.îØˆq,`EáÂ˜g1m¸XĞHØ*|"±©{ºK#¤©Ò”˜ 6ô?FHêÜÑP#qÛH™8ş1ó4ÇîAV%[®0¯}±îB¢—r®³”Äk	†{Q¥&eD2q”0Ÿ„’=H„¥’ ]ŠdQÑâLfó=gLßFfÌß`
§ÆÜÔ7†ûÄ¾Ù›¶ï¨XoŠY|[¾Ü/™ü_:?Bx>¥Üo|”-W;Á`ÇÎw®ÊI ¢şÀêï@Ÿ<4~¦©·ÿ}‚}cô«ªG€l QGIœL
 ê@£™ibà…‹)íù9JÕdR!¦\lø8›Šu+’Ëâ	şÔí³ƒŠäC©¿–hÔˆZq,5U5ıÏúÿ*úêŸ–ÿº ş¿Îü÷%üƒä¿ÀÛÛ±Şø;»Pœ4òßFş+q'bV]‘*.¡DB’;ã°ÔŸ£Ôqe)jFRO\ŸìAF ü^©ÃN	ğË$ü%MC	ï1Jæ(ë±OBLê€§M‚ßpe	,\…'Pìo ×â5Yš"Uèì,Ùâ !„æİ&!ECƒñ¨úT
b¡ ğb”ñ<$
nû€zİàxy!™ˆé	Ç	·À…é ¦8'6Öë‹ò	Âiàœ¯rL`o¶Qï¼(Ü~å"T÷G¼*Šb¥6È¾¬"ÈıøñfŒÈdÂ§¨»à0~Šƒ?Dg,©¿@+ãQÂÇ½k0ªˆfäÆNãäÆd˜õY5´¹aş£öŸ°šıAôş©ïÿïh¯±ÿûIè?8¬áÿÔŸÂËÀÁ—2Q]­ˆéàš²E Ş³q,		w¾#!™”i™0Í‘'È6®Q’@’C‚©–"*ˆzÒÄ(¹‚öó$Hµí\ò9‘àGÊ=û(h4öRAU
‚s0NQAQÅ« çµ‹²A^X&ÅP.—/Á¬}ŠÃÚÕqâpc—ÆúÿÜşûã^?ˆÿ·£¸Ôÿãbïà¬¡ÿ?ÿG KBM%~0u¯/ÇQ˜Hqb¨&ÈA*’pR<7U‚UC“ŸØğ€ò!ñ‘„ƒ<pZH·'“í)h¶Á»+	Ğ[„XK€ÛÍŸ×È‡`óø×®ÿ†\òwçÿìê­;ŠE³şÂõ¯´oBO‘õmÉ›"=¯fàåÅá@!ÀS fvğÕl¼\>ˆwŠ|ƒ˜ á_}©õÑgŒ@zÅ|D
î@¡8SuX?€È8BÄÓ‚B³Bæéày†‚~(º£…¨Ì>k¹ôõÕ£á»¾¨hßq”Ã¿JB®á¨~rş¯ÑÇàÿ€n ~ü?gü÷'¡ÿªÁ#ˆ*7õ¾B:ìêí¸}hSxE²ºƒ6Ât9„â Å³…Ğ8X{2 ñáéƒÛÁL_ªˆÁ”¤¬…¼¨Pz4²Ø¸Í{ßP¢‡dÁ'Y„áLÌpÜ‰èo4Äö—"¾?ÍHß°à†˜aÊdØ ‚Ôû‹¾m¬Û|„| ëŠ½‘M ~›Èwh}R÷™ ?äüçìĞàüçl¯áÿ~*ş·¹ÇO9ÿêÃ_}5“Šø±=æFËú!¦×QQû@L!š M´îÃdöñF5,¾ª:¬C<?i¾€`Ì’JYì8YÂ?¾ÿ«)D~Œüß±Aş'Š&şïÏµş1Eä7(K‡Bg0½‚™¦¦¦j.FAa¡LÜÅHáYTßÉšÑ¤LÊKà¥a®ç!C}¾¨ß$Pç_ö™ =`ÁtEõÑFü¹q#wk$fÿ>S6£qWÜ^,à®+V8–£Q“6w1ÅŒ´¬!ŒÎğ•.W¸*.5„Oˆ6SÀ´îˆX¡C†|éHFXp#W|m?mP…+”I	¢]îÜØÀÙÁD·7òÄ~İji	‘ëˆ‡jQT§Š æFa¢¬V¼1Í#CİN×óâMU¾„Y¸úMV›—d¢Fİñ9úßPuşİé?…âP_şç¤‰ÿüßÿ©Gsø¿ÿ©…ã%‘@ª%– w)M(àº#É¤Øğ‹Ã!‚î˜€ÎVÊ};çc@Ä\`[õc…‘_Œ‡ÃoïÆà4±Kş‹’ÑO¤ü1ú_GŠsşßQ£ÿı)ù˜6Mãÿ?ÂzbÎ!D[s‰-‡¨ÊX~ÿ‡´‹¨á÷>»şUdªWŸµÿsl ÿ·§hâü\üŸ2xÆ¿\ø§î"…ú 6âù¤¨Û}ãÂBÄ¯\ñ…—â`°#="‰ ¢>`;X0sìÌ±ĞQˆî>ƒ£GzÔñIÅZË¯ŠTÎ‘‰Ñ¸X@"åŠÈŸ—)Ö·l±ËÚ
±gi(sl`¢‚á¡!—ÿÇúß¿qø¬ş×Ş©!ÿ§Ñÿhô¿ŸÕÿ6¨»¾øÿG	ü·¬ÿú¾ÿúwpr°¯/ÿs°ÓÈÿ~FùŸ2ÚÏ n(ZdÊÄHü jrEômLLc¯0¹d+8ù	ûÆ1òEñ°Ïá¤ê‡‹x²qP±°aüPN‚Ôl›€E bÜ¬pP9çaÎ“®Ú!XøÜÈ(…aÊ	 
ƒ8İ‚/"~¶É11_ÛfµaúÚFÇÄ|´Õ‰>ÑáDg9}%¢%üÚ\$ ~ZğÜXÁÔçÖ§C„¸?î›PCe®_"YÅñ«·(>!&“m¬ Æ€Usi.Í¥¹4—æÒ\šKsi.Í¥¹4—æÒ\šKsi.Í¥¹4×ÿíõ?cx ğ  