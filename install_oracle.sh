#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="392012115"
MD5="d1910354e7a359f3957bb6009e289de7"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="Next Generation Minecraft Installer (Oracle Linux)"
script="./install_server"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="."
filesizes="5305"
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
	echo Date of packaging: Wed May 24 13:48:56 UTC 2023
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
‹     í=ûWÛ¸ÒıÙÅ`Ø-½Kr—{Ø~)IÛÜ	'	ÛÛÓíé1¶B¼ø‘õší×ÿıÎHò+1B¡¥µÚSjËÍŒ¤Ñ¼$Ê•'÷^¶±4›MúYm6¶Ó?£ò¤Z¯ïìÔ«µzµşd»Zİm4@ãÉ”Ğ4à‰îÌŸj:»â»ëêi)W»Ş°S¶ûÿİİİ«Æ¿¶½›ÿíÿÿv1ş÷^º#84uæøLQÜéÌ3Ï&lêÏ ¶]Û¶vapàzÚ™ejŠrÌ<Ûô}ÓuÀôaÂ<v:ƒ3OsflÁØcÜ1èÍ;c[¸ 93˜2ÏÇîi ™éœ:ö¥à—ÁÁøî8¸Ô<† ù¾«›ÂÃÕC›9PcÓb>lêP¶PŸñN¦YŠé ÕEUpi7Àc~à™:ÁØÓÑ­Ğ ¢jË´MÙ5çğúHá¹¶k˜cúÉ8YÓğÔ2ıÉ&>|éÓKÎÉ-¢£âzà3ËR‚‰xsZìø7„ú”HùôærâÚYJL_‡ƒ]2ŞÆp‘e¼Ç?™Ğú|ìZ–{I¤é®c˜D‘¿§(#¬ÒNİÆiãë¸¢*P ˜&£*«ü‰fYpÊ$Ã°_d¯–"Ç£îqñ8©Y0u=Şß<™eìÿu†ı—£7­AºC8ôï¶;mP[C|V·àMwôº2übĞêŞBÿ%´zoá?İ^{:ÿ=t†Cè”îÑña·ƒïº½ƒÃ“v·÷
^`»^'q§2õ:” º!;ê^ãcëE÷°;z»¥¼ìzóe -8nFİƒ“ÃÖ OÇıa»o#Ø^·÷r€½t:½Q{ÅwĞù`øºuxH])­Ä~@øÁAÿøí ûêõ^÷Û|ù¢ƒ˜µ^vDWHÔÁa«{´íÖQëU‡·ê#”BŸ	ìàÍë½¢şZø÷`Ôí÷ˆŒƒ~o4ÀÇ-¤r0Š›¾é;[Ğt‡Ä—ƒşÑ–BìÄ}Ûõ:
±2#‚ŸĞóÉ°„v§uˆ°†Ô˜HŒ>.+OŠòíÿ>ó.˜÷áTÓÏÃiå¾öÿ&nè7Òÿøş_ol×
ıïkŒÿÔB'®e0ï¡ô?œóã¿Û¬núßC”íşø—öl1|Tj<Ô*\o†…ÇkL‡é6@Ì–bø~Ö¿éà
°¬bdŞş¯n×õyù¿[¯ëÿ!ÊúZåÔt*§š?Qt‹iÂô‰êfé®Í"Ó¢Ç>ğŠ9Ì†R"ºbú0oMUÌ1¬ÁŸÚ…¥Î%nNü?‡l
Õ&”şR”£ ˆ.:ƒA°†ŸÂæ Õöš#š…'"g&ï±G8RdD€«Í2#Æ>[;Gƒ%$C) a&2£¬bo-¥”¼qúYîyÉëùÅ@¨~4el
Ò#6™L¥ìğ#üüTvQqB´‹nLoš¥íëÑ¡‡µ"¼é7C‡ç:vº*)²õ×¢f}œp|™%eÓ²~b¨í­	YŸ§dı
RÖóiY—Ä¬çŒÍõ‰Kü¶¤ÛÆŠ”ñµFÉcÒ3Eá8Ñ¸tCË€™‚esAéh$0¹?KôÅ!9:Û_q÷
1ç”şuC¾Qá}Ä‡»a9ÇÄa£N¢Ødö4˜q^DäÈş÷76yÓ”Ø‡ãŸ’ú,úê—}|J=lZ½vÿHcJ$œæ`×^èÓ¸ ëS\oî‹¿K„–1"&áµ{	v¨OÀf6©¿‹CŒ¤ğıP"H.Äç°ùêÅ3"[qÂ26>ác¥òn»ôëûÊgx?ä	D5Û E$y%³dÓtBûÕö4ÕëY²ÉMkh3?‡ès†8Qmh¦5‹Ì„çD2µàÒ+"š^d¨×ÅËémBöæ„§”‚ª\€sø“œÏŸ%ø•1£÷DÅgšîÈ VüıŠş‡¿ÿTı#ÕèU…È|®øºgN¿" EhÇ .À… §ü­ Æ¦ÃEJ?
 ôæ&×H$‡E?%ÙM@Ü…/_€3÷Á›/Â»ğGwÔ¨ƒ;°gÂJH5èƒÇ|¬„CÀ]PÀöáô.( « €º†|L›­Òªõ*»†fØ
§|À›g« ‘edÂS®á]‘É²
2¾vÁî°<ÒÍWê>Ğ¼»,Ïüö¨#ú!`àÿnĞ~5Üéğwï´\NÌ€Y¦.ÀPì‹H©ˆÔ×äU¤V,lóJ†¡	ü¿ìR)§ô÷éÿtZí£ûLÿ¸Îÿ¿Ó¨5çó?ª…ÿïü)WŞ¶Lp¤9Ú%ù2€aˆOQZÑ²@C_ M€&Ş>İh†ÏÈ\8ch!@Ğd.™Ø¦Ì/C»²©«$Wc‚F‰¦O˜ŸÎÔGYQ†á”öıáR‚¾· æ|— Ï7>8Ä>*ÊÁ„éçÜr0î%ğ¼<QTÃÒJWqéX.šEş”éæØÔ#ÿgÈ-"ÊÅÖlY™ÁÔß«TÎõğ´¬»6ê`Ş…fTbÚK±çlI0³"ûó+Š²ìıÔÁw©Äuÿ&7hµ¹Å}m[Üs(òF¤–S†²Š	¼Ø_¡é1J—ñ·d"Fk–jÉ<r§¤kVºc@›X2üE6™Kšå»"ã#rp¡³G?‘)vô²?¡,äµĞ:ğ5åœhÁSšÃ"2şsš† –§ÛĞÈ¤‘KmVæù*ñ]ÎŒÈäR\ó\ ÊHA0V‰Y•pIkó’ò”R†{ùO\ó¦ÿL˜¸¾»‡r>	ç#ã3kÂ•Å™™p{bòÓ7¥r˜ÙS(Ã"—Ô¸Ïa3ú™šc¯gæ÷òŞãÁ¸aïiÈy+#œ¡iñò1ÌñÙêÄ^EäEî?}¢9g¸îNC9¿è“¨GíÔ&9ÃKµÉÆ‹[ZõáÔàùaš+D¹%XpÉpæ,ª›Ú¢JŒË@¬·©ç^˜”áÄ‘‰‰‰òÁ"Ñ1Eü2Ó9BV`'&7§Ña"M‹¼M†ˆ‹{›b#×OzÒINñåvÀÙ/„æ2`²—†Œœ{J%ËåœÆ9C,Wçl’‰q“…q:DB–ç¶æñ¬»2Ñj°±ZÜ¥Z­sòÍA?’Z‘Ç¯_S¤ŒyìÂôÕ—®wÎ…{Î K¾‰$´+¸Š<QÚİ!OšêöpÈW³K‡¤»À!ŸzÄ(ŞŸmú¡Ïæ‚Öø2aâXr†f0[óÎ}PWJPj”ÔP:2QĞRr¢Øİ?5GÌ&I2¥+¨&”L'`-‰GuìûÎÿ¾UşÏNµÈÿ~àñÏ,Í‡ÿïÎ£¹³Sèÿ_3ş/´apRšª¬ïõG=àÙCRŒG{3ékb‡ÁMyìÉTæyí•Ã©g¢ %Ûn,óM®&Ô=¿uì¢¥~ŠïúS‘æU¼Û~ú÷„Òv Èˆ›½«¾‡!9R*jTáNŞïà{Ò6_Z!êR²múçÏ¾«¿GÄ¥w7
ƒŒ®m%8¿k¼‡—2I¶V€».Õ®Ëê]ÄüŠíÿ˜y¦k$’Oå8É0WòEó=6Í™v¬ªı[K!ıÏŒŒ#µx8%ùàW¤•#´"¤RäT‘Õ'u=2[R"±ì¹—åTÄ°Cû%ÖYŒçæ‹(©|PDˆp#~%öl'QÂòUoçQp(r Tó d|kËÛ×òÛ'¾±åÍwr›§\“Ë›×óš/xÅ–ÃhäÁÈq¬——ùp£^Öó»Ù…tìï‹…–¢.¿DÀ0
P¼`ipˆB†Òk™x[¹ıBT®*/–>ãÒnƒs•ëèIÀS¹z|¢ˆôÒ¼‡]Æz~|d'›â Ìçé¿ª…(¿¢¼º2eA’ÂÇ!…/š¤Ü€KEäi÷qÉ<Iãœ‰Ø£ğĞ$s‘œ±…[SYleh›éÌ÷S¦œhÈ©§› zS”ï$Rµtö,Îî7ü	Nu„wæq€¾q3*r Á1¯¢ÕpÎ¸çWn
!ã4_5RÓh™çü¶]­õ‚X¾UãL qµ¶"x»¶©èİíæ
ĞÛ Èn·j™İ½n×Ô]qnäl:ñ²Ìê$p"5$ $°2¼EùÂW™pó™EÛ¤ÆB+*òò Î²¶¸X8Ùi=Q]uOoæˆÂQ
!LHıÎÉüˆ!£ádpHB©ız~ÄÓ<7ä3”Ü”Z'$QÃ¶d¹åƒkÍ2÷.ê¥‡\Lõ”4àize$0>mÑÅSÁ5ÎÒÈ3,|Œñ'ÒqtŸ3æŸ93æ$e”›ùô±%ûæ
Y`Wï¨’›fWìÜ›Lş›ÎÄ+Ï²pxş(Å˜g,iÖ÷:	~M&A*`LÀæw ¥I¾M3·ÿ-…PÍ“_RhN m‘ÉŒ£?	Z€é&_¿c\¸2hÇùBª…k£äÒÑœI¶"HíL3oBº];¨>ËÉ¨ì:"ã86K×RI“ßïùÏ˜WßÆùÏİz½ğÿ~•ñ¿‡t—kî©Öµ…óŸõâş¯äÿõ÷U™õ!uXU.öU©aeßú’¦Œ(|(ÒHæÜÅhÙïáÆ='±9i%`åETÉ÷.¾Ç$*8j”sê“+½r_£ZZNtâıÍ2'®.ƒ8yÀÑ—oq<Á¥p2CÍQ…‘<0RoqÜ€îÂàğé˜ü6a†"Ş{D[còwrïI4¢):ß9Ó	˜Œà«yÈÄª¯<¸Ä5HóMÆÄ¡½y+Ë¨)âo„B‹Hï©ˆu’À#‡ïË)GîÕæ*Få²²Ì„Çÿk¬½‚ÙX)¯¿ã…¦ÂG);ñ´0Ù”½c|½œçÃœWÕºùŠÃ÷zşwIéÉü;'ÿ›;Õ"ÿï‘È2ÖTü'û—/Á‰–²š+ÊÜ*[?=;ÑüRt\­`#¨ı–œ*FÒsXÛ§€Ñ¿"»™·$ON	¥–OÔXøKSJ Xö¨±°qiÜ™‘T¸EEé*'aûÄ2ZVÆÒ9ÕìàH¢RÓx£÷édd,–¡–E‚x†ÌöeÚÑ 6.	WÄ8#¸tª¸á‡.ËÎI<ş¿İX¸ÿ¥‰ÿ)äÿcÒÿ#áH¾$‘*ñÀÒ}Ş§‘0L;rDG>sŒÒ9›ù²•&‰Ôğ1‘ ÂAÉV¸^OÖÂ§j¹\m|V7oWĞ.HŞraí[Å®â‡Sr>¤Íã›]ÿ‹Zò½ëÕÚÜú¯m7¶‹ü¯Ç¸ş“ü&aEÎ'µ¯â8"Îg¼Z†Ç®Çõ­¨ÇL×€Ùtß%ÿ†§ E_İ4ûèšä£ïa³çz6÷‚×İçĞú!Q.?`¡ÑÕœ°ñ‰ŞåGÌ.Éâ!³k3—nß½ Èù,ï…‡ü‡Óÿæ’>ÂşGq?¯ÿ5…ıÿHäúº5õ°d—ˆ²BŸ†ø”ó§\/äõZhúDT.ªz2 ª*B#¬7~¥Q¹\Á¿âZ
É¬ÏPgo~©ÖÚlÊ %<ûÈtº¥äÁ§ÏğÇ¿Ê‡ÙW76é'ü¢şd”~²K?½Uqcõ4ÇØWÅOqYü_|S}n˜^nçôˆ?o|¢6ŸîbÜèÛ¼=pí)í7ñÌ}&ü<)ÿN%ëwïZ}œò?›¶÷ öÿnmÁşß­úÿ£Òÿ£3‘èû¦Eû|˜1å¾å¹çì4äwèû®Œë¥Â~0r9:tèûp0şòBDØÚé˜˜dÈó¥é+‹{È×_ÿé€ØÃÄv~ÿG³^ß-Öÿ£Zÿ2}‡à¼tºGÇıÁ¨Õ­­­e˜GÑ³ødÙüiÿ2tÓ2ÿf"åìøM;>r.ïR8ß¡ãi¡#l”+1PqY ¿X :äÊFëÊóâ]‚Fş™ğMÎ{ñ<»¸¦İ‰ “ô”3vrä.
Å“pauF×gœQÎ¥–"#Î\×(C»ÏÆà¤—sğnáĞ÷ò„º(¡ dÁo<»àİ+ n…î?øº-‡ØúóÏP7Uø-İTÄÔ€ÿóØ©‹B9Ó</òÌadÓ!chQœ?B5©DUyåÌ¼,«E¸ë:ù¿˜;qïò¿1ŸÿUÛ®ï4ùÿ=ø³×ŠüîßÌİÅ¥ıª%Í!ñ^*ıí:lŸÿ2)Ÿ4Ã(QÃ}é ­úôî@Bã* £Üº‡uFß˜áİù‘gE–|ñåWx>Lügáş‡f}§ˆÿ?Jı@Óf5ıÿ
ÕSR+~ÅPÓŠåmô?—Zè{×®ÿÔÉ¬/ÕÇµùŸ;ñŸj£øıOKÿK.OùÆÙ#rârÎÉ·ÄQÍûœ…ü^l×1ƒÈC‘&=÷D«À&µCCå„ÎÈûËxŒmpaÒ‹ƒo©lQùûUyçFè‰ÚÈ°iùzŸâ—‰[âñÇÿÁàÚøÏnsÑÿ[+äÿÏÙ'òÏ/Ø¿^tıÆ¡õ»ÄÕïoıÏ_ìqÿë¿V¯UçıÕfáÿ{Œş¿ä¼Ç^t-BßÓ‘ñ+ŠÚñ8¯º&ı’–6£CnŞ7;ï¡-1ågÜ9™şğ‹¸'ó5Àxa#}BÈä¶×(#”'·Ç”èwÎ£æÙO3D^%¹S'q†%€Ó=íÎMœˆ×¢<ßçÌ0İéñøJ¬ky®O1œb–«0½’$5!IÃÙ²1uÔ›‘…s‹¨ÂÙ¹µœ0îÄ]l¤^;áH>×[PÇ=«}s‹b9…Ò'›×°H`.JQŠR”¢¥(E)JQŠR”¢¥(E)JQŠR”¢¥(?dùXıÃé    