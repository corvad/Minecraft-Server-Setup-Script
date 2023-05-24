#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1669346837"
MD5="5b894ac7f335005d9413c4abc260a755"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="Next Generation Minecraft Installer (Ubuntu Server)"
script="./install_server"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="."
filesizes="5320"
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
	echo Date of packaging: Wed May 24 01:50:17 UTC 2023
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
‹     í=ûWÛÆÒùYÅDĞ6¹Å66ßríç€“ø^°9¶inNš“#¤5VÑÃÕBóå¿3ûĞÃÌ«¤Úæ$íÎÎÌîÎÎk—jíÙ½—u,­V‹~Ö[ÍõìOUÕ7776[[›æ³õz}kkë4Ÿ=@‰ÃÈ ™¾ÅÂ©a²Kê]õı‰–jm¿»Ûé;U×ºÏñ§½düë[Éø7››ü­õÖËñ¿÷rĞÁ¾m2/dš¶ëO/ûdÁó%4Ö°gœÙìúÁ™qâØ†¦²ÀµÃĞö=°C˜°€_ÀI`x³Ö`0şÌ‰œ°5ˆ|0¼˜² ÄşqdØí€&ö¥aÍh‚`BÃÊaè›¶ğÀòÍØe^dDÔßØvX/¢	}([è/y'3Íö€¾©OpnG? `aØ&ÁXÛ3Ø"ÔgÇvmÙ5ç5‡Há¹®oÙcúÉ8YÓøØ±ÃÉX6>#|ÒKÎÉ5¢£æ2ÇÑ‚xsZSìxB}J$‹Bzs>ñİ<%v¨ãÀÃ.ocùÈ2ŞãïÌŒèUûãŸi¦ïY6QnkÚ?Çşã´ˆñõüQ(Ğ LÓQ•ŸÂ‰á8pÌ$Ã°_d¯‘!' îqñx‘m80õŞß,™Uìÿm†ı×£wíAºC8ôíîuö@oñY_ƒwİÑÛşÑ°Æ İ½‡şkh÷ŞÃº½½5èü÷pĞ¡?Ğº‡ûİ¾ëöv÷öº½7ğ
Ûõú8‰»8•è¨Ô¡Õí	ØAg°ûÛ¯ºûİÑû5íuwÔ#˜¯ûhÃa{0êîí·px48ì;Øı‚íu{¯ØKç ÓU±W|_ñ†oÛûûÔ•Ö>Bì„ìößºoŞàm¯ƒ/_u³ö«ıè
‰ÚİowÖ`¯}Ğ~Óá­úe Q5¼{Û¡WÔ_ÿíºı‘±Ûïø¸†TFIÓwİagÚƒîòzĞ?XÓˆØ¢Ï`»^G@!VCnD°
=;	@Øë´÷Ö‰ªrU{V–olÿYpÆ‚OÇ†yOk÷µÿ·šÍëèrÿßlÖ7Kıï1Æ½^Á’Ú#³¹Q/Çÿ‘Çê µß±Xp¯úÿz}½53ş­Öæz©ÿ?D‘ö‡ÿÈ7×´Q3"T’…h1‡‘FNJ³P6í Œ@ÌšR-xÂëßöp8Î'!ÁÿÓj´æöü¥\ÿQV×m¯vl„Ít˜hÌœø ¿cé»L™–=ö9‚7Ìc0”l™1 +¦ëš=†çğ»qf@¥‚s‰›“ÿ'›B½•?4åi ¢‹Î`Ğ<Çª°kxhu¢HAsôÌplK ‘3“÷X…ƒ˜ä¸ŞªÂ!b2pS4Xc2”#f²!³ª:ö¸ æ6T‚qöYîyéëÙÅ@¨~¶#mlÒ#.™Ì•3ˆÜø3|ÿ3Ô,vVób´‹¯Moš§íñè0ãÀY’Şô±è˜øOq¢ò]Ê.üû”OZÏ ÉË}K¢/É3Ù6èøŠ»:ˆ ò'è«òı·Ãr†y=ÂÆÄ)ÌÜitÁy¡È‘ıï¬¾àM>¸z¢ Æÿ*úKUëÇ|Ê<¬Ú½½ş>ÃµPRæ`×Aì‘¸ ¿g¸ ßÜ~•-bDBÂ[ÿÜØœ€Ë\?¸(b$…Ë&‰ i&¿À‹7¯^qØŠ†”y°úkµë•Ÿ>Ö¾ÂÇû!ï@ j¸~ìE"ÉCè¤Ì‹İcä¨^É“M.SË¸ˆ>e(L‰jË°©…¿ÉÔB[ÉM/rT¯p²Wfé^¹„ğ•bÊWæIß#d¯OøŠ¤|I×p[p‘óù«Ä kYô¨øJÓdÃµp§fşîü ÿ–iô›®ƒ2ej¡ØÓ(¬	@
íÀ8“ ä”¿ ÂØö¸È#PÙG”Ş\âJ
‰ä°è§rq·áËpæ>xs'Ü¹LßCí&º{f ,…Dà{‘qü)`!‹–Â!à6(`ûxz€ePàVæ§ÈvÙ2ıgZ/Ó¹¨¢ĞÆ'Ñ±}²P–A&>Fáß™(Ë gìË#Û|©îÑd»Íò,n:A şvöËàOo…¿«à|bGÌ±ÃÛğp†æ)¥B©¯é+¥VÌmóZ‘†aZ)ü]v©U3ºôÜÜ•ÿgĞiïÜgúÇUşßæzc6ÿKÿÏƒø2®œ!mÓ<'àÀğŒJ$ò¥Ã»¦µÕRDã_1û!úhú_‰rÂ"02`¥P@Ğd¢Ù¸¶G,¬B»r©«4Wc‚†aNX˜ÍÔVNUÓ†ñ”ö.Wıá¶V#¾Ÿ!æ\nT Ï7[ØÇ>kÚî„™§ÜZ0î™Õûéˆ¥‡¯Ï«8÷M±pÊL{l›ÊÿÕr+Œr1¤]Õ&Q4·kµD=>®š¾‹z_pfXµ„öŠ@¬Â9[Ì¬ÉşÂš¦$‚>Ám1õ•À¿ÉVo­qG‹LqãÏU!{˜À…ıÛ£™pM&Ï <´šé+™aş”toÃ©Bwh{K†Åc²®‘xÃ	}‘å¡\4š6)"çÒ"æ€ï¡½
ş‡9Fc{ÃŒCø3ÁV8„n„…*XÀÎ<bAqçY8ø>¢ypÈ<Ë„L „QìmkÉ6Q'”ÕbD?Ğ¼ãüPø‹xÅIl[‚¥<¡‡Y¦¥œUÃQsO9Ä£Ü„D±A0~ó6?¥-$ËŒÈèqN™PwDõw”*vøRî¡Oèçà‹Á™3†]áÛÖr³y[¬,ªP©àP2w
UHY ú5œ²ğ"ó¥>¿ÙfGòúÌ‚,êRáœ‹mÇJ–¢eÇÈ@/ñZ‰y#*)w¥91¼œQÇ±œ·TE}Äñ9öel*?ô5UæJ¯D<µx®™aâê%qCn3œ#óê2‡6¯ÒÓÄæËwøg6eKqdbTn™CSÄ¯JŠ(‚WB9°9@\%Ê¶Ö±p%%Dåì~ÆŒ­orJdœ"4¥Ç‚‡$S…	íiTîÎŒÀ6&–’ÅÆFìpÇm}“×AêhUãˆD•ò+òõ$Ãƒ;³C‘›vî§i˜0?R”ˆ´³tÑŠ×Èm¯;äùQÁ6rÔò…;÷(İŒáˆLbïÈµC:(…X†]!«93¢À°˜k§!QçKÁIÒ/$l´V)Ql€şï†'[’‚Üè
r	%ÛCE3ö©‡>½şû¸AşÇÖFsƒë­õ2ÿãAÇ?·P2ş[_ßl¶fÆ¿ÙÚ,ó¿5ş+ôapıRšºüŞë:Û0Êè‡j?%mJl9¸‘™Ê<«;¡ê6l”¾éş„ÛÂ|W¤I	e,¬ªîı0´qÇ‚şT¤9«Ö?¢>Å½¯´G2’fêaHÎ›¹úàOçŞoà{Ú×_¼vbÔä¾œ«·ù—Ü=,2¸†”âü¡ù^KE˜l­·aúº"?o!æ—è‡,°}+…”V•ã$CkiÖGl˜3{‰zõo#ƒô?02vÕæ!œ´ÂOH=cVì(¤2äÔ‘ÕG^xùwd¶¤DbÙóÏ«™(e‡6Qüæ0›/"³òAaÉÕäTØ°F&«—9ÛelIÃ¡(€P/‚óç-nß(nŸúã7ß(lq‡.n¾YÔ|Î·F3…±R]ä¥ÎöQà7V½¬w³Ùxã…78T—w¤TaJ ŠÑ,HQ˜RzJ‹ƒ}K·Ÿ¼ÊU$ò!d\Ú­r®r=²j—Š‚/Ì¥ÀÁğØy¢õ'GvòiÔı1û%›W †j.³@QÑ]š&!IáãÁÍHnte² h÷ñÉXÉâœË@á+ùpâ#9c·¦ªØÊĞz3YŠZÜÄ4±³m•é¨R\½)Êw©F˜±Ïpv_p!$OÂ;	8À	ßÀ¸Q¥HpÈ?Ñj8eÜs†+7…˜qš/›G™i´È[‡m—k='–oÔ8¼\®­ˆ:Ş¬m&bx³†…òó& ò›ÀZæw¯›5õ—œ›N²,ó:	I	(åÒƒ÷(_ø*#nS3u°Mj,´¢”gu–çó‹…“Õõe÷ôV(epÂ„ÔĞoLÌ2û$Ä‘ÚOqà`%æ·*Ÿ¡âgÔò$	ŠîIv‘+Í³¸Ö,óıT/=äb¦§´wNÓ++…ÁsÒçÜ‚0\ã,U~[áLªHoÒ}Î˜Ì˜;HXË)7³)köÍ%2Ï.ßQ%7Ã­¹9¸×™ü×‰—E!øâQJ0ÏY0Ò¬±îuü”N‚Lš€Íî@’b›ffÿ[¡^$¿æ¤ĞŒ Z#!’ÇpG´ ³MşyÆ¸peĞ;ß…T‹#ßEÉe¢9{!ÙŠ ÃöşÒíÊAYAg×ÙÍ‰Yú<›¨ùÍÿLxõØşß¦8ÿÑ*ı¿2ş÷bsÅùŸúfscfü·Z[õÒÿû8şßpG—¹WŸ2GuílG—Vş½ ¯ùqÀXEÉŒ»-ûmÜ¸Ôs°“V~<SùŞÅ÷˜TGrF}ò¥×Aîkô…Å¡‚‹^²¿ùSæ%Ÿ«Ñç(	í{†çó-§
øf¨9ê RFê¸iMYÑ]Á±=›ß†¡ÒÄ±EW{LşNî=Q@M*AB9Ó	˜0)«z2‰ê+ôàš†Ò|Ó1ñho^Ë³C5Eü­XhÙıQa y2—¹Aj_Î8r/7P1ªVµE&„8.ö_÷sãTÈÆÊxı=ÿ$¶5>JjìÄÓÜdÓWªEÖxµÈ‡9«ª	t/Q¾Ñü¿¹­$ÿñßìùïÆF)ÿŸ†ü'cMÇÿåßâò%8j)ëù°¢ŒÁ-³EğÓ“#¬¨#r•Aãçô£0’~ç;0ú—²›yKòäTPj…ÔHO„°4¥ZMd«gÅYé§·HTÄ‘®r¶O"£åÇD:g’¬$*5Mö8zŸm@öGÎbIj;$ˆ/ğ‘¹¡ğÃÃ 1.	WÄ8\:~U¦@ÿÍó¿/?›ñ@úÿzsîü«¾±UÊÿ§¤ÿ+áH¾$‘*ñÀÒ}Ö“¤DJæ9¼£yVå”]„²&…Ôğ1‘ ÃnÅÕ¸^OÖÂ—zµZo~Õ,¿hW0ÎHŞra:Å®cEiióøË®ÿy-ùŞõ¿zcfı7Ö›õòş§¸şÓü&aEÎ¦Ÿ/ã8 Îç¼Ú–‡tX •Õc.ÇkÀ\ºï’×á)hªÖu³®H>J€ğ^ôüÀå^ğF³¹ÕäáZ?$
bËç‡-ºšV¿Ğû¯‰üHØÅá Y<dveæÒÍ»×7]Á;ÇÍ=ä¥FõÄõ¿™¤‡ĞÿZÍùûßZ¥ş÷DäöŠ=ó0S‹5©oÎì*?t]±š?FÍ•®Í¦Æo(ªVkøOÜ6!ñù
— úQ&Û¡Òw1e€’”}f&]uR	àËWøí_åìè«/è'ü¨gU¾s+ß½×qÏÚÑÅOqü-¹…Ç=µì zDˆô“}ÕLºhşq½ÊEŒÛõİ)Iöd÷ãŞ	~r“×\ZàÑ»âêŠ±ÿ¶sößV£Ôÿ”ş§rî••ó—6şfÃL÷Ï=fÇ1¿C=ôe\'ö‘ÏáĞI´0„İÑ`ÿÇW"Â²—‰H†ü²0}SlD‘aN±Ú£ïÿ¹€ÈÃøÿ7æşşCks«¼ÿõi­ˆ¼Eğ7Y:İƒÃş`Ôî?;btp4©#FÉÉ¢Ù³ØUèFG¶cÿ)OŸ¾ÛK	‹Î¥ãìãØÊ•¨8ÊÍ}«$÷L6RWæ¿‹w)ù#Î
ãõ’óçâÖ\®†¨Ã¯2Ië%H9ã¦G®T(–„C¨t}Â	åLQj!2âÄ÷­*ìõù_@õ
^Í^œP¥Ê~æÑåOt\Ü:
İğÿè†bë÷ßCuÖdĞáçlSS ş/`Ç>
å\ó¢È#‡‘O‡K ©8¯B5ıˆ*Ü,Ê¹yYÕËpÇUò>t~ïò¿ÙlÌúÿ6›eşÏ7áÿË_ñ·tÿ©ÜŠéb«
ı©Ã#ñ^©üé{l‡ÿ1!ŸËªPÃé «Eæôö@bë2 £Üª‡uF^›€áíùQgI–|‹ÑÅ×F>Lüw£¹5§ÿo–ş¿'©ÿhÚ,§ÿ_¢zÊÃ!zm5¬YzV±¼‰şÇñÒK}ïÊõŸñ©ŞUWæÿm4çò?¶åúRú_zyÆ_Üù—?"%Î œ|Jù¼oå,äçÊ}p}Ï”‡P‘&=÷D«À%µÃ@å„òÌå¥V<ö€6¸0éÅÁ§L¶ üûš¼s+Ä]ä	‰Ø´zµOq6³åZÖ?ğ|–yŸã\ŠŠ¤£—ãøïî WÆëú_yÿSÿ½2ş[töløï¾ƒõ?{±Ãı¯ÿÆf£>ëÿkÔKÿßSôÿ¥w =…ğ¼kqüş „œ_Q|‹>7¤_Ò1.èŸ_Tgã#ì‰D<Y;'³ïÄ=Y¬&éš @.·¹A<¹99 Bs5Ï~–!òú•äLM¼Ô–N jL÷t{×q"^‰òx|SœsÃtS¤ÇãK±n¹>ÅpŠY®ÃôR’ô”$ºÿzuêé×#çQ…òsk1aÜ‰;ßH¿úvº[‘&|®7 {V}3‹b1…Ò'[Ô°L`-KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)Ëß®üN Æ”    