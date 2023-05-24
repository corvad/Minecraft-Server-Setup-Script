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
�     �=�s�H��Y�X�n�[#6p�+o>bH.��K�RB��z�z���_�<� �m;qV�Ti4=�=3=���V~r�eJ�����Fm/�S�'������
�ԟ�U*�Z�	�=y������LLu�����GZ��I���5Ǽ����ƿ�W�����^e�Z���+����igHN,��U�co:���IH��Iu��OZ��2ɱ����������+ ��ќ\��Rs��}J�7&�D�/�.	=��s2�~ �Q�[��^�З_� x��J�)|l=<��1=#r��!�7�l�g�u Z��Y'&�m�r	��*re�/
�O�з��K,װ#q�ն�X�l�( 4
��s�8�i��'edM��m�]bZz��2�����HG��I@m[��hM�c� �Sdh(X�����d)�e�.tIY�����F�o��g���fx�i!E����Jy3�h���z!��Q��&�*���n�dDà_`��"���a񸡥�d����E25��M�z��o��6��Y��k��n�9�gu�����·��7��w���4���:��.i����H��tN�N:mx�����:���%���`w`*�a�`�T�=@`����xl��t��v�W�aa���I��5�����I�O���g�A�o�n�����O�ݡ��;����M���R��}�#ǽ�w���7C�w�j�˗m����ͻ��O���]�j�6_�Y�@�+�ǎ�}��W�_�;�.�q����T��qӷ�A{�4��2�U�w�� ;�E��v�6���&��O��|Ў�V�y��I�kʓ�|g�@��?�t�2���k�o�j7����P۫�����$N<ۤ�C�09ǿި��C�!����l>Pj|�*<��jN-��>	�-�>���˅`���>��_�;��!k������e{�<���H&�aS�W�1���چ�PiZt�ǐ��.������>��RkL���L'��%fN�?�tJ*R�SP�B�����[�)9�]�:��sd��`p2 bf�5r
#���\ih�0(q�K0X"4�Bf�!55z�!�H���Ş��^\��G+T�'8��T��Љ>�!e���nvэicM��}=:�ȷ7��5�f��=7�G��"Z+�D�)��_���E2ƠH\��%�1��l3��oBQȭI�^�m{q���m�>��@���Dɕ�&�{��K&(]&�g��,נ�D�W̽�C�)�E��F%����m8�El�N�ԙ�s6�r�D�G;�XS�H����OI}.����R;�f��;U�"�s��ڏ\t�!D}���}q�W��:F�$���P���!R�~(D������H�b�e.�����o{��ߗ?���C�)GTw��SD�WҽH6M7rF�����Β�nZS�9D_R���jS��4^ �؂�{I4��P��;/��[���	O/dT���'1�?�+s��8݁AyZ������S��T��U�H��5�2$ю��L S�V c�erA�9P|s��	H ����& �/�������]�cx.h��س a#$����7�!�.(@�hz8�MP �#?��C7�?�z��=_3��S>�����M�ȁ�	2��ktWdr�l�L����G��F݇����t��?8���oF�7��ޝ6���R�
���%�3�J�T_�WR�X��<�0�ѥ���w��뷛���L�����ߨU�?���=��/�����rNuW��D�[d��S��\`m��	��C�;@�l�9�4$�RȀ h4�,�8��4�H�r��$WcF�nLh�����(�h������P)�s�� �l�H�m|�z��(�j\2˥O��  ��Q[,0=��X^ŕk{`SjXcː��ހYD��!�YM���48,�/ �h��:�?��rL{�#Vb�-qf�EAYQ�����;��.��/ȿ�Zi�2_�.����hd��/�gd��e�]�H����Z4��)�ĺ��Θ�M,��.#�%�<��!�'���"W±����2L���,	h�`^�=(�Q&��,���]�#d�D� ͑ϸ�!��6J�th�g��=ğ��:�L0/%y�� x�Y0z��)㙤��sY&�?K �I!�X����2h�b�J' �NB��U|�g�@X{v��S)W��H!+x΍��;��'gs%���scBf	��ߔJ0�ԙ�,sI��C�<ˀ~���ۙ�_�{<7�=9�se�5�l3^Ц5[��%��#�4&�{sq����J��Nr�kU ���3DS�e��� Z�(������ 3h�J:.	&��7�0�!#3Ԥ0�~��,�˔MnF�Ky���L+�(��6�F^��d��d������T���^2t�*m �p,�&`4.�����&��'��,�ќ�}6�ۺ�� 5�դc=����r�<P�7��(D9*}�l�Z<�ͧ3+�T_y�%�nrY���ŭ�*�Diu,���?�!3=.^�\�>tC>��Q�?�
Pf���0`�X2���nRG�/PO�tl�ԠP:�@�c�$ߧ�?t��&A0�éF�,d'.���XǾ�����T@Q�2��vP��<d�Ov�y��#��*��~���U��|�� �)�)���no�>$ÔN(wBԎ�<�-p�T�E]T��o�X�'��8�|��q�*�d�gX�#xכ�4gY���{Ў�'�/'#n�[�=�#e����t��>����+;�@������w�q� �l���t���j��+�������ۢ����lϨoyf)�T��s%_4�C�؜iŊѿ������8R��S�~�A0#["�"��>w����lA����]i��aw'��)���QR���N����d/�j��"Σ�P�@��A���ַ��O|c���6O�&�7?�k��[������y��}��pe/����I:���B���6"��C2$㥄�a�Px-�o�_
��U���!�L��0�2�8	x*��GF���5�`��*֪�#;�n\�H���P-E����ʔA
��` 2s)����Cc �s&b7�r�6lM���2h�':AS1�9�� �Q����Y��s�z�� x>8a3Z����*\��y�`e��QF�y��F�<�_��f����g�����۵M9�o�0W~�@v�U���u��ކs#gӉ�eV'!��5�J���;�/l�!3V�<�&4\Qҧ:���bad��Du�=��#
�)\�0A5�;$�#�&���@�ȷ�#��#�I�K��qB6l	v��5��,re/]�b���sH�+3����=2�\c,�~X�ы?n���1�̙1_ y,��,����77�[��
n��Sv2po2�o:W�u���Q�1�X0¬1�u��L�T��-�@k�|�fa�[��'���Ђ �E!��`�� ���u��aአs�s����� sv.�
 ��r�	�v�4'������,�J'M~��?c^}e�oe�����7
��W�D~ �/���_�z���~%�op��<�����2;R���}��+�6d��:�F��.��6.��D� �3Y��.��$*8h��'�b_�ٺ޹���M�Wk��0ջ��-���=�R�U#�F�<j�]±\�݆!S�9IWs��N�=�@%M2)B:�����y�Ī�8��4��&c��޼�e�l
���"���� Nx�0�}9��]m>�b�i�:���������Jy�]�"�6Jr�����S���<k\��a.�j���wz�wM��������د�
��8�?k*��}��ȥ�fÊ"���N�N��$���BhD��$����la��_�nf-ѓS�`#5>��h'�=jl ��Hwj&UCf�Ȉ#^��m�XF��X:��,%*6��8|�n��G�bIj�(���H�@$��c���py�S�ţP���V��x ���t�K̀B�?"�_
G�%�T���~�8� ��0��a�5K�t�nT��%T��H�J�K���z�>U4�R���^ޮ��P�2a�Ů��.Ur>���]��Z��������������?�o�V�b
�&�S�|&��i����#{��x����]�oX
����G�$�@XϺ��0/x�V��X8��������$;����X~��bp�,2�6s��ݛ 
��7����q{y�Q=r�o!��!���~}Q�k�������uj�a�.!�B7���Af�j�va����/��A`����*��ͧ��������|��3��_
&��;��'�I��,���~x���y�����
�Ҵ���� ~���m>+^rB�q�o�8v�9S��fǜ�&����6�k��x��^]���B�{T��̹�V�7m�-��R�;�{LG�C=�D\'�!C���#^A@�����^�K+y�6}�Q���nL8��W��3�����/����A�Z��G��E ���x�tN�z�a�;����1:=���d���j�tB��m�%N���m�|�QI���q�r�J��fǸe�{*�#��������t<�����Yva
�<�.���!g��ȕŢp� u��'\`��#.<��H��~B���s�j����*P.��]������������� [��h�&�J~I7�1U��|:�@(g��E�l:\M�y%�I%ht�(g楦����r���������
��=����8�-��lK%�U;���T��s��eB<�YG�AW��݁D�* >�ܪ�uFޘ������gC�|����W8>L�w����;(������f��
�SQ�;A�Tӊ�m�?��Z�{׮��w�K�qm��~m)��V��������o���="�Ϡ�|Jټo�,d��=�x�J�#Lz�@W��j��	晋ۢX(lpn��O�lA��5Y�f����ҩv�Oq1��).�,�e�縔�"�(���8��w�k�?�Ʋ�W/��͏��]h��zA�G�������x������A�����������K�@{�e��0���A1�"����/i�s<���}����x"���9'�~�d�/l��k��dr���Ȓ��*�;�A��"���I���M�a���xO�{'�(�Ƿ�93L�Ez<^�u5��ɇ��r�LW��&$��;SW�Y0��*h��[�	cN��F����݉4�s�u̳*�[X�)>ټ�EkQ�R���(E)JQ�R���(E)JQ�R���(E)JQ�v�c��e �  