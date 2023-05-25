#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="337677017"
MD5="84f3c920656c6bb00a852b48a529cc42"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="Next Generation Minecraft Installer (Ubuntu Server)"
script="./install_server"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="."
filesizes="5409"
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
	echo Date of packaging: Thu May 25 00:47:33 UTC 2023
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
‹     í=ûWÛÆÒùYÅDĞ6¹Å26Ø¾åÚÏÁNâ{ÁæØ¦¹9mNÖXEWˆ›/ÿûÙ]½laÀR©œiwggfwgçµ‹V}rïÏ6>­V‹~×ZíìïøyRÛİİÙiÔ[­ZóÉv­ÖlÕ@ãÉ<Qê>ÀÃ3Y0ÓvE½ëÊé£U{İş¨«9æ}³Ù¼jüëÛÍtüwëuÿz³ñ¶Ëñ¿÷ç¨7†CË`nÀåÀ›Í}ëlÂ3ã9Ô·ë;ĞÑ/,<ÿB?³-]Q™ïXA`y.XL™ÏNçpæënÈÌ-˜øŒ7cªûglBtw3æØÀ;uËµÜ3ĞÁÀ¾¬NLàMÂKİgXÙ=<ÃÒ˜9Ìõú›X6àY8e dõ9ïÄdº­X.PY\—V8õ¢|„¾eŒ-°\ÃLÂ!.¶-Ç’=PsÎ€@A Q€[àx¦5¡ßŒ“5‹Nm+˜nièÓ(Ä}äœÜ":ª³m!Xˆ7§5Å×!ÔgÄĞP²( /—SÏÉSbÊ$ò]ì’ñ6¦‡,ã=şÁŒ¾Põ‰gÛŞ%‘fx®iEÁ¢Œ±H?õ.§EŒ¯ë…ˆª@`–ª,
¦ºmÃ)“Ã~‘½z†ŸºÇÅã†–nÃÌóy‹djØÿë.Œ/ÇoÚÃ.ôFp<üÚët; ¶Gø®nÁ›ŞøõàdXcØîßÂà%´ûoá?½~gºÿ=vG#•ŞÑña¯‹ßzıƒÃ“N¯ÿ
^`»ş 'q§2€:” zİ;ê^ãkûEï°7~»¥¼ìûóå`m8nÇ½ƒ“ÃöO†ÇƒQ»ï Ø~¯ÿrˆ½tºı±†½â7èşŠ/0zİ><¤®”ö	b?$üà`püvØ{õz¯‡.~|ÑEÌÚ/»¢+$êà°İ;Ú‚Nû¨ıªË[ÊP¡j;xóºKŸ¨¿6şŒ{ƒ>‘q0è‡øº…TÇIÓ7½QwÚÃŞˆòr88ÚRˆØbÀ`»~W@!VCnD°
½ŸŒº	@ètÛ‡kD‰Ä¸²¦<)Ÿolÿ˜Áü÷§ºqÍª÷µÿ·ébÿßmÔê¥ş÷%Æf#‰SÏ6™ÿPúNÅño¶êÛ¥ş÷Ï˜vü¡=[L •µ
ÏŸ£Fáó’#Ëe†¯OB³¥Ü¾õo¹¸lû½Ù‡·ÿkÛúÎ‚ı¿Ûlì–ëÿ!§ÕSË­êÁT1l¦û
3¦¨o˜mx‹M‹>ûÂ+æ2_J©@è‰éÃü§ªbMà)ü¡_èP©à\âæÄÿ£qÈfPkAåOA¹
€è¢;†O±*è.Zhß¡9r¡Ûhpr rfò58Â‘"{$\kipŒı–ˆ¥„™lÈLMÅŞ|GJ-¨ø“ì»ÜóÒÏ‹‹Pı`…ÊÄ¤!G2™*:Ñøşg¨šì¢êFhİ˜6Ş4OÛ—£Ãˆ|{M:xÓ¯†ßsCıt]Rdë¯…šhr¹&%ÔòKQ±±HÆ‰K¬Z13OÏ'hã&å€Üš´EÚ6® n£˜ºIŞÒç3Éš¡pœê!\z‘mÂÜ‹À¶Î¹ tu˜ÜŸ%úã°\ƒíŠŸ¸{…†ú7¨üê¦ü¢Â»xxï6
œì6†`'ŠMæÌÂ9ëx¸dÿû›ÏxÓ”Ø¡ª¦‚ZQŸ_Sòµ~ÜÇ·ÌËæ°İïÔÖÅ"<e!"èG.¹‰W²<Ã+ùå¾xõ«Dh»^{—àDÆæ’¼<¾kJÉÑø<{õâ9‡­8aH™›ñµZım»òÓ»ê'xw?ä	DuÇ‹Ü0C$ù.İ³tku#ç•û,Õy²É™kêó €ès†Û<Qmê–=‰_ˆdjÁ¥CL4}ÈQÈƒ;/ÖÒ;„ìÍ	Ï.w¾çğG9Ÿ?I°–9§ïDÅ'šîÈ ~¨ûUã÷`ÿõ÷L£ßUb#»¾5ƒª £ ¸  €œò·@[.—*û*€Ò—›@ÜHA"‘ı–@æ7q¾|ÎÜo>wîÂÃsQïïÀk!!”¥÷>X¸9 wAÛG³»   ¬ƒª%Aø>´¶Nÿ™Öëtîù:kï)èòGtb­ƒD”u‰NQ¸FwE¦ Ê:Èú»ÃòÈ6_«ûP÷ï²<‹Û£@è—€ÿºAûõğfwÂß»Óp9µBf[Á]x¸Cq.b¥"V_ÓO±Z±´Í+E†a¦ ğß²KEË.èGæÿvÛ£ûLÿ¸Îÿ¿»½ÓXÌÿÀ×Òÿ÷ ş¿Œ+oD›!Ï	8Ò]ıŒ	F|‚Ã(Â%¥(íxÂ£µPÛGc¬ï€,o´Åçdœ±ô¥ h2„,ËBhĞÆ®ê*ÍÕ˜¢¹¡Sd35¤-¡)Ê(šÑBa0ÚS*pÂwÄœ¯Î
ø–‡ØÃE9˜2ãœÛ$CÆ]—'jØ:bAé!ÂÀó*.]ÛCƒ'˜1ÃšXFìÿŒ¸­C¹ÒNÕ”iÎ‚½jõQN5ÃsP»ò/t³šĞ^ˆU8g+‚™UÙ_PU”dâ¼ ¦¸ÿ¤şø7¹Ak­-îkÛâC‘7"õÆÈ*&ğbF–Ï(]&Ø’‰4íT*%ÃÇ›‘¶«Ûô&€Ö®d¹Œ2„t;ğDÆGì?á#w~§ÂPìÕZ0¥,ô³Ğ'ğ3åœèá4+8†1DeüßYd™‚ZnCC “F.õ9vùF÷…# ñAIósÈµ#Ü§¦Ç“>f8cL)Q™şã,L<Dƒ3Ht(ú'V\zş9àhQ Ës†BÖ:s=_ºq.&Ö¥Î›ëQè9ˆÍ}1¥!òİ`ªñ¬—°—ó;v	ˆW¹ğŒ&Âûö±H¬ü²IƒqÏ.)Û*ãXĞş@ÉeÏ…	x{¸åàãğñù0{Â/Ç‡2·löÄ¦:•
2‡93Ğ`y¬ÕàYôsµÀHßÈ­ÒÕ½'Sê†½g!u®Œq†G–m&BÀ´&d«›x¥d,”WŠ}™ÆTwÏPzœFr•P•¸GíÔÃ¡_^*MƒDx:ÒëÍLå¦8IĞ‘Û„…—gÎ²:Ì¡-«ì8w…Ô˜ùŞ…EyZ™„˜8«-€3Ä/·(cdvr.Éfä3­P¼p'xØÛyAÚ“AÒ–Î.x!4«!‘½4däŒÙSº,åXÎiÀi\0”ÁöÎ&¹¾c.¦ãt.H.Up8·uÿŒçjD«É&zdsïpm—û£o.®ÖI’ì=’\
Y"ñÍgV ¨æâ‚¯ïåA–|©tWpy¢tz#úÕîá¡¤á"ùÒ%Ê.pÈg>1Š÷çXA°…Ğ;ÖC¦!LKÎĞ×Mæèşy@êÉ}€¥%$Z,Ü.(ÅRìíŞº+f“¤™ÒKE£å†Ì§%QùÿFù_÷yà6ù_­&×ÿ[2ÿëAÇ?'Ô6ÿc·ÑZÿF«Ìÿø²ùB† ·)¤)¨ÊrÔ¾»{À³Çäk5¤éŠ½Õ™‰/SÙ´ò™z;nßÉF[2Â|S¤å
E9Ğâî½ °NñÛ`&ÒÜã‚ß¶ß¡¦Ë}Ü´‘
2’f¿ÕŞÁˆ\dKu*ğfKßwğ;iWÏ^Új¡²cçÏ—êí¾CÄ¥ß	·X“ŒGa³¤uïà¥f“­¢¾B¥²¸‰˜_¡83ßòÌRZU“`¦5Zï°ybÎv%÷ßzé&`d„°Íei…ŸzTëÌÈ‘ÊSCVŸ¸ÁÕåÈlI‰Ä²ï]j™Xp—4,³?›!¢äòEÁßÍäTØŸ°Æµ«B2‚§àP@¨AÈyMW·¯·O½«›ï6Ï8W7ß-j¾äï\£‘ÂØĞVÅ²}xçã^6Š»iB6ªûÙ‚È +ÃÈ q—Ÿ#ƒ(°2ìGÁ`é.©®İ~)¼-W•ŸÈ‡€qi·É¹Ê­›4”­\=>q®ÁÊ¼—]&Rrd+Ÿâ"Å_²Ùb¨–ò7äĞ•)+’>|Ñ˜ç¦o&×‚v»,Î¹\¾¢³’3±qkÒÄV†V­Á‚ cØYˆ†•œŠIÎ¢7CùN"UÏfOãìs3*˜âTGxg>8å7@c"ó"ZçŒ{Nqeá¦1NóUó(3VÅD>cÛõZ/‰å[5Î…ˆ×k+b»·k›	ãÜ®a¡ü¼€ü&p«–ùİëvM½5çFÁ¦“,Ë¼N'ÒÍEJÓà-Ê¾Ê‚;X|°Qj,´¢bÿê,O—';«'ªëîé­Q8Îà"„	©¡ß˜ Y1d4œIˆ#µï#ßÆJ<ÍwS¾CÅË¨åIª5ìHv‘CÓ5¹Ö,sKã^úÈÅLOiî§Of
éÓ—³0\ã,}êÂ;›T‘.·ûœ1ÿ,˜1Ÿ!-0§Ü,&®Ø7×Èï»zG•Üôu§êäàŞdòßt&^!xV%:R‚yÎ‚‘fy¯“à§tdRØâ´Ò )¶iö¿•jEòkI
- ­$ c0BZ€Ù¦(‰\¸2hËC q0ÁV©Ÿé–ûUH·k5`¹²=W¤'féÓl:ì·ëÿyõ¥ı¿~ş·Ù,Ïÿ~™ñO5àòÿÒiï…ño¶š¥ÿ÷ùƒ}Uf¸½ÏW•‹}UjXùïB€¾¤ic
¼Š4¢w1Zö{¸qÅïiTSZ	Xxò½‹ï1©
å‚úäI¯ƒÜ×¨„E¶bÓ„oÆÜ¤X?„IÚ…«»ßâx2ŠGx†š£
	"E`¤Ş "à!İ…ÂáËµøm(ÂŒD¦BâmOÈßÉ½'1Ğ˜¦øSìL'`2÷A-B&Q}åÁ5®iÄšo:&.íÍ[yvÄM3ZDvŒ1ÈÄúÓ.9|_Î8r¯6P1Ò4e•	!‹ş×ùP²±2^×;‹,…R<vâmi²É˜Z‘5®ù0U5îŠÃ·ÿ-"ùä?ş,ä¶vêµRş?ùOÆšŠÿËÅåKpâ¥¬æÃŠ2·ÎÁÓÿ¦zP‰"VBlõŸÓÃ¥ÂHúîSÀè_±İÌ[’'§‚R+ Fj"|„¥)%Ğf"{ÔÄ@Ø¼€,îÌL‹ÆÜ"‰#t•—°}-éœiHvp,Q©i²ÇÑ÷l²?rKŠPÛ&A<ÇWæ2ak˜O—¡„+bœ1\:äV¦À”ù?Wœ€y ı»±tÿO«¶SêÿJÿ…#ù’DªÄK÷E?N’rÆÂ0çÈáÌ5+çlÈnTšüRÃ'D‚
Gáz=YkšVk|RL¯hWĞ/HŞraØÅ®aE—)ióøj×ÿ²–|ïú_­¾°şëÛÚN¹şáúOó›„¹x`wÀq>—àÕ6M8ö|®oÅ=ær¼†Ì¡ûNy‚×ºiöÑ5ÉG	ŞÃ³¾ç;Ü^o4šÎ¡õC¢ 2=~ÀF§«Yaó#}ÿ”È„]’ÅCf×f.İ¾{A‘óÿXŞ	<nï!/5ªG®ÿ-$}<„ı_¯/ÿlµš¥ü$ò?{‘†šyY±KÄY¡OCüó¸^ÈËõ0Ô©(\Võd@UU„F¸ÛPø½VšVÅqáˆdÖ'¨ˆSK?ÖvÚ|Æ %<ûÀºè¦âÃÇOğû¿Ê‡ÙW7ŸÑoøQıÎ¬|çT¾{«âÆêë®¹¯Šßâ&ù¯ä&çÜ´üÂÎé!~ÚüHm>)İ²C5oT»hh<gF;N²+s¯	?QÌë©+]­¥Xşrò?Ÿ¶÷ ö³¾dÿ7ë¥üTú|æ"}_µh_3fÜ·<÷œFüo(ŒëeÂ~0ö8:®p0şøBDØ:Ù˜˜dÈ/+ÓW–÷/¿ş³±‡‰ÿì,ıı—Ön£Y®ÿGµşe úÁÿdéôÃq»?~úôiîˆÙÑÉh1KN–-Ş“À/zˆBË¶şb"åìøM'9¬/=S8ß¥ãi‘+l”+	PqÍ¿’!>äÉFëÉóâ[ŠFñiúg:¸÷“.xvpM/¾C&é=)gœôÈ]Š'áÂêœ®O9£œ9J-EFœy©AgÀ/ÃôŞ-—_P'Tlø™g¼§äÀm£ĞıÿîA"¶~ÿ=h‹&£
?g›
EO ø?Ÿz(”sÍ‹4@#Ÿ™@‹ãü1ªi!ªÊ‹(çæ¥¦–á®ëäÿrêÄ½ËÿF£¾èÿİİm•òÿ[ğÿæ/dù[ºsXW*ô§¶t—Ä{¥ò—ç²}şÇÄ|ÓM³B÷¥ƒ¶³»‰Ì«€øŒrëÖ}c:|>†wçGœ5Yò-zÆW_Îú0ñÿTöõÿòş¿Ç©ÿiÚ¬§ÿ_¡zÊÃAju3¨šjV±¼şÇñRK}ïÚõŸ9™õ¹ú¸6ÿséşÏV­Yşı¯Ç¥ÿ¥—§|åÎ¿ü9q¹àä[ê(ÈçıÇÎB~¯€çZaì!ŒÁH“{"ÈUàÚ¡£r"ï˜¤ƒo<Æƒ6¸0éÅÁ·L¶¨üûº¼s3òÅÕvä		ÙL»Ş§øyâV¥xüûÆÿ?ãpmü§ÙZöÿÖKù_Æÿö‰â3äKö/]¿IhıpÇ¨úı­ÿÅ‹=îı×wëµEÿ_}»ôÿ=Fÿ_zŞcˆ /»Ç‘ÏïJèÈùEédRT\—~I[ŸÓ!O¯¨ÎÎ;èˆDLY;'³?‹{²XL6Ò'4A€\n{2Byr{r@)÷Ÿ²‘×‡ÄIîÔÄMaé ÆtO¿{'âµ(O&·Å97L·Ez2¹ëz‘ëS§˜å*Ì®$IMIÒq¶lÎ\õfdáÜ"ª°A~n­&Œ;q—©×ßNx'Ò„ÏõÔqÏjLßÂ¢XM¡ôÉ5,˜Ë§|Ê§|Ê§|Ê§|Ê§|Ê§|Ê§|Ê§|Ê§|Ê§|Êçoûü¯u    